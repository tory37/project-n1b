class_name DoneAction
extends FiniteStateResource

@export var on_done_key: String = "on_done"

func _enter(_payload: Dictionary) -> void:
    Loggit.p("Executing DoneAction. Payload: %s" % [_payload], "ActionDebug")
    var on_done: Callable = _payload.get(on_done_key, null)
    if on_done and on_done is Callable:
        on_done.call()