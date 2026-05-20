class_name TurnPhaseDrawCard
extends FiniteState

func _init(fsm: FiniteStateMachine) -> void:
	super(fsm)


func enter() -> void:
	print("[Flow] Entering TurnPhaseDrawCard")
	SignalBus.card_draw_animation_complete.connect(_on_card_draw_animation_complete)
	SignalBus.card_draw_requested.emit()


func exit() -> void:
	print("[Flow] Exiting TurnPhaseDrawCard")
	SignalBus.card_draw_animation_complete.disconnect(_on_card_draw_animation_complete)


func _on_card_draw_animation_complete() -> void:
	print("[Flow] Received card draw animation complete signal")
	_fsm.change_state(TurnPhaseMain.new(_fsm))