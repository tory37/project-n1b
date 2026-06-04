class_name GamePhaseStart
extends GamePhaseState


func enter() -> void:
	var player_ids: Array[int] = _game_manager.turn_order.value.duplicate()


	for player_id in player_ids:
		var player: NetworkedPlayer = _game_manager.get_player(player_id)
		var new_deck: GameCardCollection = player.deck.value.copy()
		new_deck.shuffle()
		player.deck.set_value(new_deck)

		# TODO: Get from a config
		var starting_hand_size: int = 5
		_game_manager.draw_cards(player_id, starting_hand_size)

	_game_manager.transition_to_phase(GameManager.GamePhase.DRAW_CARD)
