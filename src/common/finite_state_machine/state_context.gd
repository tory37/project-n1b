class_name StateContext
extends RefCounted

var agent: Object
var blackboard: Dictionary = {}

func get_var(key: StringName, default = null): return blackboard.get(key, default)
func set_var(key: StringName, value): blackboard[key] = value
func clear_var(key: StringName): blackboard.erase(key)