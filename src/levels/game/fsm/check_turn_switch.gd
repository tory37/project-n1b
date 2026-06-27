@tool
class_name CheckTurnSwitchPhase
extends GamePhase

@export var on_switch_true_phase: FiniteState
@export var on_switch_false_phase: FiniteState

func _on_enter() -> void:
    var action_points: int = _game_manager.action_points.value

    var should_switch: bool = action_points < 0

    if should_switch:
        _context.set_next_phase(on_switch_true_phase)
    else:
        _context.set_next_phase(on_switch_false_phase)