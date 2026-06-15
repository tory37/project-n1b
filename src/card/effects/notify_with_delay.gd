class_name NotifyWithDelayEffect
extends Effect

@export var delay_seconds: float = 1.0
@export var message: String = "Effect executed after delay"
@export var payload_key: String = "Key"

func execute(_payload: Dictionary) -> void:
	Loggit.p("Executing NotifyWithDelayEffect with message '%s' and delay of %f seconds. Payload: %s" % [message, delay_seconds, _payload], "EffectDebug")
	SignalBus.notification_fired.emit(message + ": Started")
	await (Engine.get_main_loop() as SceneTree).create_timer(delay_seconds).timeout
	SignalBus.notification_fired.emit(message + ": Completed")

	var new_payload = _payload.duplicate()
	new_payload[payload_key] = message

	effect_completed.emit(new_payload)