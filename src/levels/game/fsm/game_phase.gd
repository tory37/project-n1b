class_name GamePhase
extends FiniteStateNode

var _game_manager: GameManager = null

func _ready() -> void:
	_game_manager = get_parent().get_parent() as GameManager
