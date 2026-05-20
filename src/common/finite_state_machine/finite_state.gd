class_name FiniteState
extends RefCounted

var _fsm: FiniteStateMachine


func _init(fsm: FiniteStateMachine) -> void:
	_fsm = fsm


func enter() -> void:
	pass


func exit() -> void:
	pass
