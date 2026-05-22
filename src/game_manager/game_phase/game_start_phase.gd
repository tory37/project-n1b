class_name GameStartPhase
extends FiniteState

# todo: move to some global config file
var _starting_hand_count: int = 5


func enter() -> void:
	print("[Flow] Entering GameStartPhase")
	_trigger_start_sequences()


func _trigger_start_sequences() -> void:
	print("[Flow] Triggering start sequences")
	await _draw_starting_hands()
	print("[Flow] Starting hands drawn, transitioning to GamePhaseDrawCard")
	_fsm.change_state.call_deferred(GamePhaseDrawCard.new, _fsm)


func _draw_starting_hands() -> void:
	for i in range(_starting_hand_count):
		for player_id in PlayerSeat.Type.values():
			print("[Flow] Drawing starting hand card for player %d" % player_id)
			SignalBus.draw_card_requested.emit(player_id)
			await SignalBus.card_draw_animation_complete
			print("[Flow] Player %d draw successful, waiting for next draw" % player_id)
	