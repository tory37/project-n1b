extends Node

@onready var _root: Node = $NotificationPanel
@onready var _label: Label = $NotificationPanel/Margin/Label
@onready var _timer: Timer = $NotificationPanel/Timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.notification_fired.connect(_on_notification_fired)
	_timer.timeout.connect(_on_timer_timeout)
	_root.visible = false


func _exit_tree() -> void:
	SignalBus.notification_fired.disconnect(_on_notification_fired)
	_root.visible = false


func _on_notification_fired(message: String) -> void:
	_label.text = message
	_root.visible = true
	_timer.stop()
	# TODO: Get duration from config
	_timer.start(3.0)

func _on_timer_timeout() -> void:
	_root.visible = false
