class_name GamePhaseState
extends FiniteState


var _game_manager: GameManager = null

func _init(game_manager: GameManager) -> void:
	_game_manager = game_manager
