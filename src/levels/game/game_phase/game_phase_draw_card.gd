class_name GamePhaseDrawCard
extends FiniteState

func _init(fsm: FiniteStateMachine) -> void:
	super(fsm)


func enter() -> void:
	print("[Flow] Entering GamePhaseDrawCard")
	SignalBus.card_draw_animation_complete.connect(_on_card_draw_animation_complete)
	SignalBus.draw_card_requested.emit()


func exit() -> void:
	print("[Flow] Exiting GamePhaseDrawCard")
	SignalBus.card_draw_animation_complete.disconnect(_on_card_draw_animation_complete)


func _on_card_draw_animation_complete() -> void:
	print("[Flow] Received card draw animation complete signal")
	_fsm.change_state(GameMainPhase.new(_fsm))
