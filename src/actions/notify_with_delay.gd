@tool
class_name NotifyWithDelayAction
extends FiniteState

@export var delay_seconds: float = 1.0
@export var message: String = "Action executed after delay"
@export var payload_key: String = "Key"
@export var on_complete_state: FiniteState

func enter(payload: Variant) -> void:
	var current_payload: Dictionary = {}
	if payload is Dictionary:
		current_payload = payload

	Loggit.p("Executing NotifyWithDelayAction with message '%s' and delay of %f seconds. Payload: %s" % [message, delay_seconds, current_payload], "ActionDebug")
	SignalBus.notification_fired.emit(message)
	await (Engine.get_main_loop() as SceneTree).create_timer(delay_seconds).timeout

	var new_payload := current_payload.duplicate()
	new_payload[payload_key] = message

	state_change_requested.emit(on_complete_state, new_payload)
