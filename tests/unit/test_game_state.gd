extends GutTest

func before_each() -> void:
	GameManager.reset()

# --- reset() ---

func test_reset_restores_active_player() -> void:
	GameManager.local_player_id = GameManager.PLAYER_TWO
	GameManager.reset()
	assert_eq(GameManager.local_player_id, GameManager.PLAYER_ONE)

func test_reset_clears_ap_tracker() -> void:
	GameManager.ap_tracker = 5.0
	GameManager.reset()
	assert_eq(GameManager.ap_tracker, 0.0)

func test_reset_clears_currency_for_player_one() -> void:
	GameManager.player_game_state[GameManager.PLAYER_ONE]["currency"] = 99
	GameManager.reset()
	assert_eq(GameManager.player_game_state[GameManager.PLAYER_ONE]["currency"], 0)

func test_reset_clears_currency_for_player_two() -> void:
	GameManager.player_game_state[GameManager.PLAYER_TWO]["currency"] = 99
	GameManager.reset()
	assert_eq(GameManager.player_game_state[GameManager.PLAYER_TWO]["currency"], 0)

func test_reset_player_resources_has_no_ap_key() -> void:
	assert_false("ap" in GameManager.player_game_state[GameManager.PLAYER_ONE])
	assert_false("ap" in GameManager.player_game_state[GameManager.PLAYER_TWO])

# --- request_add_ap() ---

func test_request_add_ap_increases_tracker_for_player_one() -> void:
	GameManager._request_add_ap(3)
	assert_eq(GameManager.ap_tracker, 3.0)

func test_request_add_ap_decreases_tracker_for_player_two() -> void:
	GameManager.local_player_id = GameManager.PLAYER_TWO
	GameManager.ap_tracker = -2.0
	GameManager._request_add_ap(3)
	assert_eq(GameManager.ap_tracker, -5.0)

func test_request_add_ap_clamps_at_max_for_player_one() -> void:
	GameManager.ap_tracker = 8.0
	GameManager._request_add_ap(5)
	assert_eq(GameManager.ap_tracker, GameManager.max_ap_tracker_value)

func test_request_add_ap_clamps_at_max_for_player_two() -> void:
	GameManager.local_player_id = GameManager.PLAYER_TWO
	GameManager.ap_tracker = -8.0
	GameManager._request_add_ap(5)
	assert_eq(GameManager.ap_tracker, -GameManager.max_ap_tracker_value)

func test_request_add_ap_emits_ap_tracker_moved() -> void:
	watch_signals(SignalBus)
	GameManager._request_add_ap(3)
	assert_signal_emitted(SignalBus, "ap_tracker_moved")

# --- can_spend_ap() ---

func test_can_spend_ap_returns_true_within_bounds_for_player_one() -> void:
	GameManager.ap_tracker = 5.0
	assert_true(GameManager.can_spend_ap(14))  # 14 <= 5 + 10

func test_can_spend_ap_returns_false_over_bounds_for_player_one() -> void:
	GameManager.ap_tracker = 5.0
	assert_false(GameManager.can_spend_ap(16))  # 16 > 5 + 10

func test_can_spend_ap_returns_true_at_exact_boundary_for_player_one() -> void:
	GameManager.ap_tracker = 0.0
	assert_true(GameManager.can_spend_ap(10))  # 10 <= 0 + 10

func test_can_spend_ap_returns_true_within_bounds_for_player_two() -> void:
	GameManager.local_player_id = GameManager.PLAYER_TWO
	GameManager.ap_tracker = -5.0
	assert_true(GameManager.can_spend_ap(14))  # 14 <= abs(-5) + 10

func test_can_spend_ap_returns_false_over_bounds_for_player_two() -> void:
	GameManager.local_player_id = GameManager.PLAYER_TWO
	GameManager.ap_tracker = -5.0
	assert_false(GameManager.can_spend_ap(16))  # 16 > abs(-5) + 10

func test_can_spend_ap_returns_true_at_exact_boundary_for_player_two() -> void:
	GameManager.local_player_id = GameManager.PLAYER_TWO
	GameManager.ap_tracker = 0.0
	assert_true(GameManager.can_spend_ap(10))  # 10 <= abs(0) + 10

# --- request_spend_ap() ---

func test_request_spend_ap_decreases_tracker_for_player_one() -> void:
	GameManager.ap_tracker = 5.0
	GameManager._on_spend_ap_requested(2)
	assert_eq(GameManager.ap_tracker, 3.0)

func test_request_spend_ap_increases_tracker_for_player_two() -> void:
	GameManager.local_player_id = GameManager.PLAYER_TWO
	GameManager.ap_tracker = -5.0
	GameManager._on_spend_ap_requested(2)
	assert_eq(GameManager.ap_tracker, -3.0)

func test_request_spend_ap_does_not_switch_turn_while_tracker_non_negative() -> void:
	GameManager.ap_tracker = 5.0
	GameManager._on_spend_ap_requested(3)
	assert_eq(GameManager.local_player_id, GameManager.PLAYER_ONE)

func test_request_spend_ap_switches_turn_when_tracker_crosses_zero_for_player_one() -> void:
	GameManager.ap_tracker = 2.0
	GameManager._on_spend_ap_requested(3)
	assert_eq(GameManager.local_player_id, GameManager.PLAYER_TWO)

func test_request_spend_ap_does_not_switch_turn_while_tracker_non_positive_for_player_two() -> void:
	GameManager.local_player_id = GameManager.PLAYER_TWO
	GameManager.ap_tracker = -5.0
	GameManager._on_spend_ap_requested(3)
	assert_eq(GameManager.local_player_id, GameManager.PLAYER_TWO)

func test_request_spend_ap_switches_turn_when_tracker_crosses_zero_for_player_two() -> void:
	GameManager.local_player_id = GameManager.PLAYER_TWO
	GameManager.ap_tracker = -2.0
	GameManager._on_spend_ap_requested(3)
	assert_eq(GameManager.local_player_id, GameManager.PLAYER_ONE)

func test_request_spend_ap_emits_ap_tracker_moved() -> void:
	watch_signals(SignalBus)
	GameManager.ap_tracker = 5.0
	GameManager._on_spend_ap_requested(1)
	assert_signal_emitted(SignalBus, "ap_tracker_moved")

func test_request_spend_ap_emits_resources_updated() -> void:
	watch_signals(SignalBus)
	GameManager.ap_tracker = 5.0
	GameManager._on_spend_ap_requested(1)
	assert_signal_emitted(SignalBus, "resources_updated")

func test_request_spend_ap_guard_emits_ap_spend_failed_when_over_bounds() -> void:
	watch_signals(SignalBus)
	GameManager.ap_tracker = 0.0
	GameManager._on_spend_ap_requested(11)  # 11 > 0 + 10
	assert_signal_emitted(SignalBus, "ap_spend_failed")

func test_request_spend_ap_guard_does_not_modify_tracker_when_over_bounds() -> void:
	GameManager.ap_tracker = 0.0
	GameManager._on_spend_ap_requested(11)
	assert_eq(GameManager.ap_tracker, 0.0)

func test_request_spend_ap_guard_does_not_switch_turn_when_over_bounds() -> void:
	GameManager.ap_tracker = 0.0
	GameManager._on_spend_ap_requested(11)
	assert_eq(GameManager.local_player_id, GameManager.PLAYER_ONE)

# --- request_add_currency() ---

func test_request_add_currency_increases_target_player_currency() -> void:
	GameManager._on_add_currency_requested(GameManager.PLAYER_ONE, 5)
	assert_eq(GameManager.player_game_state[GameManager.PLAYER_ONE]["currency"], 5)

func test_request_add_currency_does_not_affect_other_player() -> void:
	GameManager._on_add_currency_requested(GameManager.PLAYER_ONE, 5)
	assert_eq(GameManager.player_game_state[GameManager.PLAYER_TWO]["currency"], 0)

func test_request_add_currency_emits_resources_updated() -> void:
	watch_signals(SignalBus)
	GameManager._on_add_currency_requested(GameManager.PLAYER_ONE, 3)
	assert_signal_emitted(SignalBus, "resources_updated")

# --- request_switch_turn() ---

func test_request_switch_turn_changes_active_player_to_player_two() -> void:
	GameManager._on_switch_turn_requested()
	assert_eq(GameManager.local_player_id, GameManager.PLAYER_TWO)

func test_request_switch_turn_wraps_back_to_player_one() -> void:
	GameManager.local_player_id = GameManager.PLAYER_TWO
	GameManager._on_switch_turn_requested()
	assert_eq(GameManager.local_player_id, GameManager.PLAYER_ONE)

func test_request_switch_turn_gives_income_to_new_player() -> void:
	GameManager._on_switch_turn_requested()
	assert_eq(
		GameManager.player_game_state[GameManager.PLAYER_TWO]["currency"],
		GameManager.base_income
	)

func test_request_switch_turn_emits_player_switched() -> void:
	watch_signals(SignalBus)
	GameManager._on_switch_turn_requested()
	assert_signal_emitted_with_parameters(SignalBus, "player_switched", [GameManager.PLAYER_TWO])

func test_request_switch_turn_emits_resources_updated() -> void:
	watch_signals(SignalBus)
	GameManager._on_switch_turn_requested()
	assert_signal_emitted(SignalBus, "resources_updated")

# --- request_pass_turn() ---

func test_request_pass_turn_sets_tracker_negative_for_player_one() -> void:
	GameManager._on_pass_turn_requested()
	assert_eq(GameManager.ap_tracker, float(-GameManager.pass_turn_starting_ap))

func test_request_pass_turn_sets_tracker_positive_for_player_two() -> void:
	GameManager.local_player_id = GameManager.PLAYER_TWO
	GameManager._on_pass_turn_requested()
	assert_eq(GameManager.ap_tracker, float(GameManager.pass_turn_starting_ap))

func test_request_pass_turn_switches_active_player() -> void:
	GameManager._on_pass_turn_requested()
	assert_eq(GameManager.local_player_id, GameManager.PLAYER_TWO)

func test_request_pass_turn_emits_ap_tracker_moved() -> void:
	watch_signals(SignalBus)
	GameManager._on_pass_turn_requested()
	assert_signal_emitted(SignalBus, "ap_tracker_moved")

func test_request_pass_turn_gives_income_to_new_player() -> void:
	GameManager._on_pass_turn_requested()
	assert_eq(
		GameManager.player_game_state[GameManager.PLAYER_TWO]["currency"],
		GameManager.base_income
	)
