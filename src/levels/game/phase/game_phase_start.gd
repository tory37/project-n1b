class_name GamePhaseStart
extends GamePhaseState


func enter() -> void:
	Loggit.p("Entering GamePhaseStart", "Flow")

	var player_ids: Array[int] = _game_manager.turn_order.value.duplicate()


	for player_id in player_ids:
		_game_manager.decks.shuffle(player_id)

		# TODO: Get from a config
		var starting_hand_size: int = 5
		_game_manager.draw_cards(player_id, starting_hand_size)

	_game_manager.transition_to_phase(GameManager.GamePhase.DRAW_CARD)
