class_name GamePhaseStart
extends GamePhaseState


func enter() -> void:
	Loggit.p("Entering GamePhaseStart", "Flow")

	_game_manager.initialize_all_players()
	
	var player_ids: Array[int] = _game_manager.get_player_id_turn_order()
	_game_manager.set_active_player(player_ids[0])

	_game_manager.sync_ap_to_all_peers()

	for player_id in player_ids:
		# TODO: Get from a config
		_game_manager.add_currency(player_id, 2)

		# TODO: Get from a config
		_game_manager.draw_cards(player_id, 5)

		_game_manager.sync_player_deck_to_all_peers(player_id)
		_game_manager.sync_player_discard_to_all_peers(player_id)

	# TODO: Remove or Gate Debug
	_game_manager.print_game_state()

	_game_manager.transition_to_phase(GameState.Phase.DRAW_CARD)
