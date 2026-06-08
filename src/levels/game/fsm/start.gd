class_name GamePhaseStart
extends GamePhaseState


func enter() -> void:
	Loggit.p("Entering GamePhaseStart", "DrawDebug")
	_on_server_enter()
	_on_client_enter()

func _on_server_enter() -> void:
	Loggit.p("In GamePhaseStart._on_server_enter", "DrawDebug")
	if not _game_manager.multiplayer.is_server():
		return

	Loggit.p("Setting up new round. Incrementing round number and shuffling decks.", "DrawDebug")

	_game_manager.round_number.increment()
	_game_manager.action_points.set_value(0)

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

	_game_manager.transition_to_phase(GameManager.GamePhase.DRAW_CARD)


func _on_client_enter() -> void:
	if _game_manager.multiplayer.is_server():
		return
