extends Node


func _ready() -> void:
	SignalBus.active_player_synced.connect(_on_active_player_synced)

func _exit_tree() -> void:
	SignalBus.active_player_synced.disconnect(_on_active_player_synced)

func _on_active_player_synced(new_active_player_id: int) -> void:
	if new_active_player_id == multiplayer.get_unique_id():
		SignalBus.notification_fired.emit("Your Turn.")
	else:
		SignalBus.notification_fired.emit("Opponent's Turn.")


