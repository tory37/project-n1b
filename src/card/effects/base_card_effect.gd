class_name Effect
extends Resource

signal effect_completed(payload: Dictionary)
signal effect_cancelled(payload: Dictionary)


func execute(_payload: Dictionary) -> void:
	# To be overridden by subclasses
	pass


func cancel() -> void:
	# To be overridden by subclasses if they have ongoing effects that can be cancelled
	pass
