extends Node3D

func _ready() -> void:
	print("Main scene loaded - 3D world ready")
	SignalBus.game_start_requested.emit()