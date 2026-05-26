class_name GamePhaseMain
extends GamePhaseState


func enter() -> void:
	Loggit.p("Entering GamePhaseMain", "Flow")

	_game_manager.print_game_state()

