class_name GamePhaseDrawCard
extends GamePhaseState


func enter() -> void:
	Loggit.p("Entering GamePhaseDrawCard", "Flow")

	var active_player_id: int = _game_manager.get_active_player_id()

	Loggit.p("Active player is: %d" % active_player_id, "Flow")

	if (_game_manager.can_draw_card(active_player_id)):
		_game_manager.draw_cards(active_player_id, 1)
	else:
		# TODO: Send the game over signal / active player lost
		Loggit.p("Player %d cannot draw a card. Skipping draw phase." % active_player_id, "Flow")


	# TODO: Remove or Gate Debug
	_game_manager.print_game_state()

	_game_manager.transition_to_phase(GameState.Phase.MAIN)



func exit() -> void:
	Loggit.p("Exiting GamePhaseDrawCard", "Flow")