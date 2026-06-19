class_name Action
extends Resource

signal completed(payload: Dictionary)
signal cancelled(payload: Dictionary)


func execute(_payload: Dictionary) -> void:
	# To be overridden by subclasses
	pass


func cancel() -> void:
	# To be overridden by subclasses if they have ongoing effects that can be cancelled
	pass


func is_server() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return true
	return not tree.multiplayer.has_multiplayer_peer() or tree.multiplayer.is_server()
