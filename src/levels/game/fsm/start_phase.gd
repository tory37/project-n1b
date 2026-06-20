class_name StartPhase
extends GamePhase

@export var on_completion_phase: GamePhase

func enter(_payload: Variant) -> void:
	Loggit.p("In StartPhase._on_server_enter", "DrawDebug")
	if not _game_manager.multiplayer.is_server():
		return

	_increment_round_number()
	_reset_action_points()
	_setup_players()
	_set_first_player_as_active()
	_transition_to_next_phase()


func _increment_round_number() -> void:
	_game_manager.round_number.increment()


func _reset_action_points() -> void:
	_game_manager.action_points.set_value(0)


func _setup_players() -> void:
	var player_ids: Array[int] = _game_manager.turn_order.value.duplicate()

	for player_id in player_ids:
		var player: NetworkedPlayer = _game_manager.get_player(player_id)
		var new_deck: GameCardCollection = player.deck.value.copy()
		new_deck.shuffle()
		player.deck.set_value(new_deck)

		# TODO: Get from a config
		var starting_hand_size: int = 5
		Loggit.p("Dealing starting hand of %d cards to player %d" % [starting_hand_size, player_id], "DrawDebug")
		_game_manager.draw_cards(player_id, starting_hand_size)


func _set_first_player_as_active() -> void:
	_game_manager.active_player.set_value(_game_manager.turn_order.get_player_at_number(1))


func _transition_to_next_phase() -> void:
	_game_manager.transition_to_phase(on_completion_phase)
