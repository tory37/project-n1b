class_name Effect
extends Resource


func execute(_caller: Variant, _state: Variant, _previous_effect: Effect) -> void:
	# To be overridden by subclasses
	pass

func cancel() -> void:
	# To be overridden by subclasses if they have ongoing effects that can be cancelled
	pass