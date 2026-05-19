class_name TurnPhaseDrawCard
extends FiniteState


func enter() -> void:
	print("[Flow] Entering TurnPhaseDrawCard")
	SignalBus.card_draw_requested.emit()
	await SignalBus.card_draw_animation_complete
	_fsm.change_state(TurnPhaseMain.new(_fsm))


func exit() -> void:
	print("[Flow] Exiting TurnPhaseDrawCard")
