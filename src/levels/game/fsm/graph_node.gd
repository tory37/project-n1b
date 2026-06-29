@tool
class_name FSMGraphNode
extends FiniteState

@export var passthrough: FiniteState

func _on_enter() -> void:
	if passthrough != null:
		state_change_requested.emit(passthrough)
	else:
		push_warning("FSMGraphNode has no passthrough state defined.")