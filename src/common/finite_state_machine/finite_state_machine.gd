class_name FiniteStateMachine
extends RefCounted

var _current_state: FiniteState = null


func change_state(next: FiniteState) -> void:
	if _current_state:
		_current_state.exit()

	_current_state = next
	_current_state.enter()


func tick(delta: float) -> void:
	if _current_state:
		_current_state.tick(delta)
