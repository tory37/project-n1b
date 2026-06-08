class_name GamePhaseMain
extends GamePhaseState

var selected_card_from_hand: String = ""
var selected_tile_coords: Vector2i = Vector2i.MIN

var current_effect_chain: Array[Effect] = []
var current_effect_chain_index: int = 0


func enter() -> void:
	_on_server_enter()
	_on_client_enter()


func exit() -> void:
	_on_server_exit()
	_on_client_exit()


func _on_server_enter() -> void:
	if not _game_manager.multiplayer.is_server():
		return


func _on_client_enter() -> void:
	if _game_manager.multiplayer.is_server():
		return

	SignalBus.play_card_requested.connect(_on_play_card_requested)


func _on_server_exit() -> void:
	if not _game_manager.multiplayer.is_server():
		return


func _on_client_exit() -> void:
	if _game_manager.multiplayer.is_server():
		return

# Play Card

func _on_play_card_requested(card_uuid: String) -> void:
	_try_play_card.rpc_id(1, card_uuid)
		

@rpc("any_peer", "call_remote", "reliable")
func _try_play_card(card_uuid: String) -> void:
	if not _game_manager.multiplayer.is_server():
		return

	var card_data = CardRegistry.get_card(card_uuid)
	if not card_data:
		push_error("Card data not found for uuid: " + card_uuid)
		return

	if _game_manager.validate_card_play(card_data):
		_card_played(_game_manager.get_tree().get_rpc_sender_id(), card_uuid)
	else:
		_card_play_failed(
			_game_manager.get_tree().get_rpc_sender_id(), 
			card_uuid, 
			"Not enough action points"
		)
		

	# If we reach here, the card play is valid. Proceed with applying the card's effects.

@rpc("any_peer", "call_remote", "reliable")
func _card_played(peer_id: int, card_uuid: String) -> void:
	SignalBus.card_played.emit(peer_id, card_uuid)


@rpc("any_peer", "call_remote", "reliable")
func _card_play_failed(peer_id: int, card_uuid: String, reason: String) -> void:
	SignalBus.card_play_failed.emit(peer_id, card_uuid, reason)