@tool
class_name SwitchTurnPhase
extends GamePhase

@export var on_complete_phase: FiniteState


func _on_enter() -> void:
	Loggit.p("Switching turn.", "TurnDebug")
	var active_player: int = _game_manager.active_player.value
	var active_player_index: int = _game_manager.turn_order.value.find(active_player)
	var next_player_index: int = (active_player_index + 1) % _game_manager.turn_order.value.size()
	var next_player: int = _game_manager.turn_order.value[next_player_index]
	_game_manager.active_player.set_value(next_player)

	_context.set_next_phase(on_complete_phase)
