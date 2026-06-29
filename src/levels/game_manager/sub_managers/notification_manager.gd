class_name NotificationManager
extends SubGameManager

#region Server

# Lifecyle / Setup
func _ready() -> void:
	if not multiplayer.is_server():
		return

	SignalBus.notification_fired.connect(_on_notification_fired)


func _exit_tree() -> void:
	if not multiplayer.is_server():
		return

	SignalBus.notification_fired.disconnect(_on_notification_fired)


# Signal Handlers
func _on_notification_fired(message: String) -> void:
	if not multiplayer.is_server():
		return

	emit_game_notification.rpc(message)

#endregion


#region Client

# Client Side RPCs
@rpc("any_peer", "call_remote", "reliable")
func emit_game_notification(message: String) -> void:
	if multiplayer.is_server():
		return

	SignalBus.notification_fired.emit(message)

#endregion