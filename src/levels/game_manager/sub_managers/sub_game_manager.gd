class_name SubGameManager
extends Node

var _game_manager: GameManager = null

func setup(game_manager: GameManager) -> void:
	if not game_manager:
		push_error("GameManager is null, cannot setup SubGameManager")
		return

	_game_manager = game_manager