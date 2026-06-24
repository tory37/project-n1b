class_name GamePhase
extends FiniteStateNode

var _game_manager: GameManager = null

func _ready() -> void:
	_game_manager = get_parent().get_parent() as GameManager

	if not _game_manager:
		push_error("GamePhase must be a child of GameManager")
		return
