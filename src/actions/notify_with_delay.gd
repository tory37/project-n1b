@tool
class_name NotifyWithDelayAction
extends FiniteState

@export var delay_seconds: float = 1.0
@export var message: String = "Action executed after delay"
@export var message_context_key: String = &"notification_message"
@export var on_complete_state: FiniteState

func _on_enter() -> void:
	var context_message: String = _context.get_var(message_context_key, message)
	SignalBus.notification_fired.emit(context_message)
	await (Engine.get_main_loop() as SceneTree).create_timer(delay_seconds).timeout

	change_state(on_complete_state)
