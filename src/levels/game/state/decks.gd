class_name DecksNetworkedState
extends GameCardCollectionsNetworkedState

func _call_synced_signal(_peer_id: int, _new_value: GameCardCollection) -> void:
	SignalBus.player_deck_synced.emit(_peer_id, _new_value)