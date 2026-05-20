extends Node3D

@export var game_manager: GameManager

func _ready() -> void:
	print("Main scene loaded - 3D world ready")
	game_manager.start()