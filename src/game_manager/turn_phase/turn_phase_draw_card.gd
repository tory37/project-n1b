class_name TurnPhaseDrawCard
extends FiniteState


func _init(fsm: FiniteStateMachine) -> void:
	super(fsm)


func enter() -> void:
	print("[Flow] Entering TurnPhaseDrawCard")
	SignalBus.card_draw_requested.emit()
	await SignalBus.card_draw_animation_complete
	print("[Flow] Card draw animation complete, transitioning to TurnPhaseMain")
	_fsm.change_state(TurnPhaseMain.new(_fsm))


func exit() -> void:
	print("[Flow] Exiting TurnPhaseDrawCard")
