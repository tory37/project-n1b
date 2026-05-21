extends GutTest

var _gm: GameManager


func before_each() -> void:
	_gm = GameManager.new()
	_gm.turn_phase_fsm = FiniteStateMachine.new()
	_gm.turn_phase_fsm.change_state(TurnPhaseMain.new(_gm.turn_phase_fsm))


func after_each() -> void:
	# Transition so TurnPhaseDrawCard.exit() fires and disconnects its signal
	if _gm and _gm.turn_phase_fsm:
		_gm.turn_phase_fsm.change_state(TurnPhaseMain.new(_gm.turn_phase_fsm))
		# FiniteStateMachine._current_state → FiniteState._fsm is a circular ref.
		# Null _current_state to break it so both RefCounted objects can be freed.
		_gm.turn_phase_fsm._current_state = null
	if _gm:
		_gm.free()
		_gm = null


# --- can_spend_ap() ---

func test_can_spend_ap_true_within_bounds_player_one() -> void:
	_gm.ap_tracker = 5
	assert_true(_gm.can_spend_ap(15))  # 15 <= 5 + 10

func test_can_spend_ap_false_over_bounds_player_one() -> void:
	_gm.ap_tracker = 5
	assert_false(_gm.can_spend_ap(16))  # 16 > 5 + 10

func test_can_spend_ap_true_at_exact_boundary_player_one() -> void:
	assert_true(_gm.can_spend_ap(10))  # 10 <= 0 + 10

func test_can_spend_ap_true_within_bounds_player_two() -> void:
	_gm.active_player = PlayerSeat.PLAYER_TWO
	_gm.ap_tracker = -5
	assert_true(_gm.can_spend_ap(14))  # 14 <= abs(-5) + 10

func test_can_spend_ap_false_over_bounds_player_two() -> void:
	_gm.active_player = PlayerSeat.PLAYER_TWO
	_gm.ap_tracker = -5
	assert_false(_gm.can_spend_ap(16))  # 16 > abs(-5) + 10

func test_can_spend_ap_true_at_exact_boundary_player_two() -> void:
	_gm.active_player = PlayerSeat.PLAYER_TWO
	assert_true(_gm.can_spend_ap(10))  # 10 <= abs(0) + 10


# --- _on_add_ap_requested() ---

func test_add_ap_increases_tracker_for_player_one() -> void:
	_gm._on_add_ap_requested(3)
	assert_eq(_gm.ap_tracker, 3)

func test_add_ap_decreases_tracker_for_player_two() -> void:
	_gm.active_player = PlayerSeat.PLAYER_TWO
	_gm._on_add_ap_requested(3)
	assert_eq(_gm.ap_tracker, -3)

func test_add_ap_clamps_at_max_for_player_one() -> void:
	_gm.ap_tracker = 8
	_gm._on_add_ap_requested(5)
	assert_eq(_gm.ap_tracker, _gm.max_ap_tracker_value)

func test_add_ap_clamps_at_max_for_player_two() -> void:
	_gm.active_player = PlayerSeat.PLAYER_TWO
	_gm.ap_tracker = -8
	_gm._on_add_ap_requested(5)
	assert_eq(_gm.ap_tracker, -_gm.max_ap_tracker_value)

func test_add_ap_emits_ap_tracker_moved() -> void:
	watch_signals(SignalBus)
	_gm._on_add_ap_requested(3)
	assert_signal_emitted(SignalBus, "ap_tracker_moved")


# --- _on_spend_ap_requested() ---

func test_spend_ap_decreases_tracker_for_player_one() -> void:
	_gm.ap_tracker = 5
	_gm._on_spend_ap_requested(0, 3)
	assert_eq(_gm.ap_tracker, 2)

func test_spend_ap_increases_tracker_for_player_two() -> void:
	_gm.active_player = PlayerSeat.PLAYER_TWO
	_gm.ap_tracker = -5
	_gm._on_spend_ap_requested(0, 3)
	assert_eq(_gm.ap_tracker, -2)

func test_spend_ap_does_not_switch_turn_when_tracker_stays_non_negative() -> void:
	_gm.ap_tracker = 5
	_gm._on_spend_ap_requested(0, 3)
	assert_eq(_gm.active_player, PlayerSeat.PLAYER_ONE)

func test_spend_ap_switches_turn_when_tracker_crosses_zero_for_player_one() -> void:
	_gm.ap_tracker = 2
	_gm._on_spend_ap_requested(0, 3)
	assert_eq(_gm.active_player, PlayerSeat.PLAYER_TWO)

func test_spend_ap_does_not_switch_turn_when_tracker_stays_non_positive_for_player_two() -> void:
	_gm.active_player = PlayerSeat.PLAYER_TWO
	_gm.ap_tracker = -5
	_gm._on_spend_ap_requested(0, 3)
	assert_eq(_gm.active_player, PlayerSeat.PLAYER_TWO)

func test_spend_ap_switches_turn_when_tracker_crosses_zero_for_player_two() -> void:
	_gm.active_player = PlayerSeat.PLAYER_TWO
	_gm.ap_tracker = -2
	_gm._on_spend_ap_requested(0, 3)
	assert_eq(_gm.active_player, PlayerSeat.PLAYER_ONE)

func test_spend_ap_emits_ap_tracker_moved() -> void:
	watch_signals(SignalBus)
	_gm.ap_tracker = 5
	_gm._on_spend_ap_requested(0, 1)
	assert_signal_emitted(SignalBus, "ap_tracker_moved")

func test_spend_ap_guard_emits_ap_spend_failed_when_over_bounds() -> void:
	watch_signals(SignalBus)
	_gm._on_spend_ap_requested(0, 11)  # 11 > 0 + 10
	assert_signal_emitted(SignalBus, "ap_spend_failed")

func test_spend_ap_guard_does_not_modify_tracker_when_over_bounds() -> void:
	_gm._on_spend_ap_requested(0, 11)
	assert_eq(_gm.ap_tracker, 0)

func test_spend_ap_guard_does_not_switch_turn_when_over_bounds() -> void:
	_gm._on_spend_ap_requested(0, 11)
	assert_eq(_gm.active_player, PlayerSeat.PLAYER_ONE)


# --- _on_add_currency_requested() ---

func test_add_currency_increases_target_player_currency() -> void:
	_gm._on_add_currency_requested(PlayerSeat.PLAYER_ONE, 5)
	assert_eq(_gm.player_game_state[PlayerSeat.PLAYER_ONE].currency, 5)

func test_add_currency_does_not_affect_other_player() -> void:
	_gm._on_add_currency_requested(PlayerSeat.PLAYER_ONE, 5)
	assert_eq(_gm.player_game_state[PlayerSeat.PLAYER_TWO].currency, 0)

func test_add_currency_emits_player_currency_updated() -> void:
	watch_signals(SignalBus)
	_gm._on_add_currency_requested(PlayerSeat.PLAYER_ONE, 3)
	assert_signal_emitted(SignalBus, "player_currency_updated")


# --- _on_switch_turn_requested() ---

func test_switch_turn_changes_active_player_to_player_two() -> void:
	_gm._on_switch_turn_requested()
	assert_eq(_gm.active_player, PlayerSeat.PLAYER_TWO)

func test_switch_turn_wraps_back_to_player_one() -> void:
	_gm.active_player = PlayerSeat.PLAYER_TWO
	_gm._on_switch_turn_requested()
	assert_eq(_gm.active_player, PlayerSeat.PLAYER_ONE)

func test_switch_turn_gives_base_income_to_new_player() -> void:
	_gm._on_switch_turn_requested()
	assert_eq(_gm.player_game_state[PlayerSeat.PLAYER_TWO].currency, _gm.base_income)

func test_switch_turn_emits_player_switched_with_new_player() -> void:
	watch_signals(SignalBus)
	_gm._on_switch_turn_requested()
	assert_signal_emitted_with_parameters(SignalBus, "player_switched", [PlayerSeat.PLAYER_TWO])


# --- _on_pass_turn_requested() ---

func test_pass_turn_sets_tracker_negative_for_player_one() -> void:
	_gm._on_pass_turn_requested()
	assert_eq(_gm.ap_tracker, -_gm.pass_turn_starting_ap)

func test_pass_turn_sets_tracker_positive_for_player_two() -> void:
	_gm.active_player = PlayerSeat.PLAYER_TWO
	_gm._on_pass_turn_requested()
	assert_eq(_gm.ap_tracker, _gm.pass_turn_starting_ap)

func test_pass_turn_switches_active_player() -> void:
	_gm._on_pass_turn_requested()
	assert_eq(_gm.active_player, PlayerSeat.PLAYER_TWO)

func test_pass_turn_emits_ap_tracker_moved() -> void:
	watch_signals(SignalBus)
	_gm._on_pass_turn_requested()
	assert_signal_emitted(SignalBus, "ap_tracker_moved")

func test_pass_turn_gives_base_income_to_new_player() -> void:
	_gm._on_pass_turn_requested()
	assert_eq(_gm.player_game_state[PlayerSeat.PLAYER_TWO].currency, _gm.base_income)
