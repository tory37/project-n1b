extends Node3D

@export var game_manager: GameManager

func _ready() -> void:
	print("Main scene loaded - 3D world ready")
	if game_manager:
		game_manager.start()
	else:
		push_error("Main scene: GameManager not assigned")