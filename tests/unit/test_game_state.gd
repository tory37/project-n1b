extends GutTest

func before_each() -> void:
	GameState.reset()

# --- reset() ---

func test_reset_restores_active_player() -> void:
	GameState.active_player = GameState.PLAYER_TWO
	GameState.reset()
	assert_eq(GameState.active_player, GameState.PLAYER_ONE)

func test_reset_clears_ap_tracker() -> void:
	GameState.ap_tracker = 5.0
	GameState.reset()
	assert_eq(GameState.ap_tracker, 0.0)

func test_reset_clears_currency_for_player_one() -> void:
	GameState.player_resources[GameState.PLAYER_ONE]["currency"] = 99
	GameState.reset()
	assert_eq(GameState.player_resources[GameState.PLAYER_ONE]["currency"], 0)

func test_reset_clears_currency_for_player_two() -> void:
	GameState.player_resources[GameState.PLAYER_TWO]["currency"] = 99
	GameState.reset()
	assert_eq(GameState.player_resources[GameState.PLAYER_TWO]["currency"], 0)

func test_reset_player_resources_has_no_ap_key() -> void:
	assert_false("ap" in GameState.player_resources[GameState.PLAYER_ONE])
	assert_false("ap" in GameState.player_resources[GameState.PLAYER_TWO])

# --- request_add_ap() ---

func test_request_add_ap_increases_tracker_for_player_one() -> void:
	GameState.request_add_ap(3)
	assert_eq(GameState.ap_tracker, 3.0)

func test_request_add_ap_decreases_tracker_for_player_two() -> void:
	GameState.active_player = GameState.PLAYER_TWO
	GameState.ap_tracker = -2.0
	GameState.request_add_ap(3)
	assert_eq(GameState.ap_tracker, -5.0)

func test_request_add_ap_clamps_at_max_for_player_one() -> void:
	GameState.ap_tracker = 8.0
	GameState.request_add_ap(5)
	assert_eq(GameState.ap_tracker, GameState.max_ap_tracker_value)

func test_request_add_ap_clamps_at_max_for_player_two() -> void:
	GameState.active_player = GameState.PLAYER_TWO
	GameState.ap_tracker = -8.0
	GameState.request_add_ap(5)
	assert_eq(GameState.ap_tracker, -GameState.max_ap_tracker_value)

func test_request_add_ap_emits_ap_tracker_moved() -> void:
	watch_signals(SignalBus)
	GameState.request_add_ap(3)
	assert_signal_emitted(SignalBus, "ap_tracker_moved")

# --- can_spend_ap() ---

func test_can_spend_ap_returns_true_within_bounds_for_player_one() -> void:
	GameState.ap_tracker = 5.0
	assert_true(GameState.can_spend_ap(14))  # 14 <= 5 + 10

func test_can_spend_ap_returns_false_over_bounds_for_player_one() -> void:
	GameState.ap_tracker = 5.0
	assert_false(GameState.can_spend_ap(16))  # 16 > 5 + 10

func test_can_spend_ap_returns_true_at_exact_boundary_for_player_one() -> void:
	GameState.ap_tracker = 0.0
	assert_true(GameState.can_spend_ap(10))  # 10 <= 0 + 10

func test_can_spend_ap_returns_true_within_bounds_for_player_two() -> void:
	GameState.active_player = GameState.PLAYER_TWO
	GameState.ap_tracker = -5.0
	assert_true(GameState.can_spend_ap(14))  # 14 <= abs(-5) + 10

func test_can_spend_ap_returns_false_over_bounds_for_player_two() -> void:
	GameState.active_player = GameState.PLAYER_TWO
	GameState.ap_tracker = -5.0
	assert_false(GameState.can_spend_ap(16))  # 16 > abs(-5) + 10

func test_can_spend_ap_returns_true_at_exact_boundary_for_player_two() -> void:
	GameState.active_player = GameState.PLAYER_TWO
	GameState.ap_tracker = 0.0
	assert_true(GameState.can_spend_ap(10))  # 10 <= abs(0) + 10

# --- request_spend_ap() ---

func test_request_spend_ap_decreases_tracker_for_player_one() -> void:
	GameState.ap_tracker = 5.0
	GameState.request_spend_ap(2)
	assert_eq(GameState.ap_tracker, 3.0)

func test_request_spend_ap_increases_tracker_for_player_two() -> void:
	GameState.active_player = GameState.PLAYER_TWO
	GameState.ap_tracker = -5.0
	GameState.request_spend_ap(2)
	assert_eq(GameState.ap_tracker, -3.0)

func test_request_spend_ap_does_not_switch_turn_while_tracker_non_negative() -> void:
	GameState.ap_tracker = 5.0
	GameState.request_spend_ap(3)
	assert_eq(GameState.active_player, GameState.PLAYER_ONE)

func test_request_spend_ap_switches_turn_when_tracker_crosses_zero_for_player_one() -> void:
	GameState.ap_tracker = 2.0
	GameState.request_spend_ap(3)
	assert_eq(GameState.active_player, GameState.PLAYER_TWO)

func test_request_spend_ap_does_not_switch_turn_while_tracker_non_positive_for_player_two() -> void:
	GameState.active_player = GameState.PLAYER_TWO
	GameState.ap_tracker = -5.0
	GameState.request_spend_ap(3)
	assert_eq(GameState.active_player, GameState.PLAYER_TWO)

func test_request_spend_ap_switches_turn_when_tracker_crosses_zero_for_player_two() -> void:
	GameState.active_player = GameState.PLAYER_TWO
	GameState.ap_tracker = -2.0
	GameState.request_spend_ap(3)
	assert_eq(GameState.active_player, GameState.PLAYER_ONE)

func test_request_spend_ap_emits_ap_tracker_moved() -> void:
	watch_signals(SignalBus)
	GameState.ap_tracker = 5.0
	GameState.request_spend_ap(1)
	assert_signal_emitted(SignalBus, "ap_tracker_moved")

func test_request_spend_ap_emits_resources_updated() -> void:
	watch_signals(SignalBus)
	GameState.ap_tracker = 5.0
	GameState.request_spend_ap(1)
	assert_signal_emitted(SignalBus, "resources_updated")

func test_request_spend_ap_guard_emits_ap_spend_failed_when_over_bounds() -> void:
	watch_signals(SignalBus)
	GameState.ap_tracker = 0.0
	GameState.request_spend_ap(11)  # 11 > 0 + 10
	assert_signal_emitted(SignalBus, "ap_spend_failed")

func test_request_spend_ap_guard_does_not_modify_tracker_when_over_bounds() -> void:
	GameState.ap_tracker = 0.0
	GameState.request_spend_ap(11)
	assert_eq(GameState.ap_tracker, 0.0)

func test_request_spend_ap_guard_does_not_switch_turn_when_over_bounds() -> void:
	GameState.ap_tracker = 0.0
	GameState.request_spend_ap(11)
	assert_eq(GameState.active_player, GameState.PLAYER_ONE)

# --- request_add_currency() ---

func test_request_add_currency_increases_target_player_currency() -> void:
	GameState.request_add_currency(GameState.PLAYER_ONE, 5)
	assert_eq(GameState.player_resources[GameState.PLAYER_ONE]["currency"], 5)

func test_request_add_currency_does_not_affect_other_player() -> void:
	GameState.request_add_currency(GameState.PLAYER_ONE, 5)
	assert_eq(GameState.player_resources[GameState.PLAYER_TWO]["currency"], 0)

func test_request_add_currency_emits_resources_updated() -> void:
	watch_signals(SignalBus)
	GameState.request_add_currency(GameState.PLAYER_ONE, 3)
	assert_signal_emitted(SignalBus, "resources_updated")

# --- request_switch_turn() ---

func test_request_switch_turn_changes_active_player_to_player_two() -> void:
	GameState.request_switch_turn()
	assert_eq(GameState.active_player, GameState.PLAYER_TWO)

func test_request_switch_turn_wraps_back_to_player_one() -> void:
	GameState.active_player = GameState.PLAYER_TWO
	GameState.request_switch_turn()
	assert_eq(GameState.active_player, GameState.PLAYER_ONE)

func test_request_switch_turn_gives_income_to_new_player() -> void:
	GameState.request_switch_turn()
	assert_eq(
		GameState.player_resources[GameState.PLAYER_TWO]["currency"],
		GameState.base_income
	)

func test_request_switch_turn_emits_player_switched() -> void:
	watch_signals(SignalBus)
	GameState.request_switch_turn()
	assert_signal_emitted_with_parameters(SignalBus, "player_switched", [GameState.PLAYER_TWO])

func test_request_switch_turn_emits_resources_updated() -> void:
	watch_signals(SignalBus)
	GameState.request_switch_turn()
	assert_signal_emitted(SignalBus, "resources_updated")

# --- request_pass_turn() ---

func test_request_pass_turn_sets_tracker_negative_for_player_one() -> void:
	GameState.request_pass_turn()
	assert_eq(GameState.ap_tracker, float(-GameState.pass_turn_starting_ap))

func test_request_pass_turn_sets_tracker_positive_for_player_two() -> void:
	GameState.active_player = GameState.PLAYER_TWO
	GameState.request_pass_turn()
	assert_eq(GameState.ap_tracker, float(GameState.pass_turn_starting_ap))

func test_request_pass_turn_switches_active_player() -> void:
	GameState.request_pass_turn()
	assert_eq(GameState.active_player, GameState.PLAYER_TWO)

func test_request_pass_turn_emits_ap_tracker_moved() -> void:
	watch_signals(SignalBus)
	GameState.request_pass_turn()
	assert_signal_emitted(SignalBus, "ap_tracker_moved")

func test_request_pass_turn_gives_income_to_new_player() -> void:
	GameState.request_pass_turn()
	assert_eq(
		GameState.player_resources[GameState.PLAYER_TWO]["currency"],
		GameState.base_income
	)
