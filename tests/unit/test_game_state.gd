extends GutTest

func before_each() -> void:
	GameState.reset()

# --- reset() ---

func test_reset_restores_active_player() -> void:
	GameState.active_player = 1
	GameState.reset()
	assert_eq(GameState.active_player, GameState.PLAYER_ONE)

func test_reset_clears_marker_position() -> void:
	GameState.marker_position = 3.5
	GameState.reset()
	assert_eq(GameState.marker_position, 0.0)

func test_reset_restores_player_one_resources() -> void:
	GameState.player_resources[GameState.PLAYER_ONE]["ap"] = 99
	GameState.reset()
	assert_eq(GameState.player_resources[GameState.PLAYER_ONE]["ap"], 1)
	assert_eq(GameState.player_resources[GameState.PLAYER_ONE]["currency"], 0)

func test_reset_restores_player_two_resources() -> void:
	GameState.player_resources[GameState.PLAYER_TWO]["ap"] = 99
	GameState.reset()
	assert_eq(GameState.player_resources[GameState.PLAYER_TWO]["ap"], 0)
	assert_eq(GameState.player_resources[GameState.PLAYER_TWO]["currency"], 0)

# --- request_spend_ap ---

func test_request_spend_ap_reduces_active_player_ap() -> void:
	GameState.player_resources[GameState.PLAYER_ONE]["ap"] = 3
	GameState.request_spend_ap(1)
	assert_eq(GameState.player_resources[GameState.PLAYER_ONE]["ap"], 2)

func test_request_spend_ap_moves_marker_for_player_one() -> void:
	GameState.request_spend_ap(2)
	assert_eq(GameState.marker_position, 2.0)

func test_request_spend_ap_moves_marker_for_player_two() -> void:
	GameState.active_player = GameState.PLAYER_TWO
	GameState.player_resources[GameState.PLAYER_TWO]["ap"] = 3
	GameState.request_spend_ap(2)
	assert_eq(GameState.marker_position, -2.0)

func test_request_spend_ap_emits_marker_moved() -> void:
	watch_signals(SignalBus)
	GameState.player_resources[GameState.PLAYER_ONE]["ap"] = 3
	GameState.request_spend_ap(1)
	assert_signal_emitted(SignalBus, "marker_moved")

func test_request_spend_ap_triggers_turn_switch_at_max() -> void:
	GameState.player_resources[GameState.PLAYER_ONE]["ap"] = 10
	GameState.request_spend_ap(int(GameState.max_marker_value))
	assert_eq(GameState.active_player, GameState.PLAYER_TWO)

# --- request_add_currency ---

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

# --- request_switch_turn ---

func test_request_switch_turn_changes_active_player() -> void:
	GameState.request_switch_turn()
	assert_eq(GameState.active_player, GameState.PLAYER_TWO)

func test_request_switch_turn_gives_income_to_new_player() -> void:
	GameState.request_switch_turn()
	assert_eq(
		GameState.player_resources[GameState.PLAYER_TWO]["currency"],
		GameState.base_income
	)

func test_request_switch_turn_sets_ap_from_marker() -> void:
	GameState.marker_position = 3.0
	GameState.request_switch_turn()
	assert_eq(GameState.player_resources[GameState.PLAYER_TWO]["ap"], 3)

func test_request_switch_turn_emits_player_switched() -> void:
	watch_signals(SignalBus)
	GameState.request_switch_turn()
	assert_signal_emitted_with_parameters(SignalBus, "player_switched", [GameState.PLAYER_TWO])

# --- request_end_turn_manual ---

func test_request_end_turn_manual_does_nothing_when_marker_on_own_side() -> void:
	GameState.marker_position = -1.0  # negative = player one's side
	GameState.request_end_turn_manual()
	assert_eq(GameState.active_player, GameState.PLAYER_ONE)

func test_request_end_turn_manual_switches_when_marker_on_opponent_side() -> void:
	GameState.marker_position = 1.0  # positive = player two's side, valid for player one
	GameState.request_end_turn_manual()
	assert_eq(GameState.active_player, GameState.PLAYER_TWO)

func test_request_end_turn_manual_does_nothing_if_marker_at_zero() -> void:
	GameState.marker_position = 0.0
	GameState.request_end_turn_manual()
	assert_eq(GameState.active_player, GameState.PLAYER_ONE)
