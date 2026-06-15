extends Panel

@onready var _label: Label = $Margin/Label
@onready var _timer: Timer = $Timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.notification_fired.connect(_on_notification_fired)
	_timer.timeout.connect(_on_timer_timeout)
	hide()


func _exit_tree() -> void:
	SignalBus.notification_fired.disconnect(_on_notification_fired)
	hide()


func _on_notification_fired(message: String) -> void:
	_label.text = message
	show()
	_timer.stop()
	# TODO: Get duration from config
	_timer.start(3.0)

func _on_timer_timeout() -> void:
	hide()
