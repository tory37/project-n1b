class_name FiniteStateMachineNode
extends RefCounted

var _current_state: FiniteStateNode = null


func change_state(next: FiniteStateNode, payload: Variant = null) -> void:
	if _current_state:
		_current_state.exit()

	_current_state = next
	_current_state.enter(payload)


func tick(delta: float) -> void:
	if _current_state:
		_current_state.tick(delta)
