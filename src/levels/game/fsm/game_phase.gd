@tool
class_name GamePhase
extends FiniteState

var _game_manager: GameManager:
	get:
		return _context.agent as GameManager
