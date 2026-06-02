class_name HandsNetworkedState
extends GameCardCollectionsNetworkedState

func _call_synced_signal(_peer_id: int, _new_value: GameCardCollection) -> void:
	SignalBus.player_hand_synced.emit(_peer_id, _new_value)