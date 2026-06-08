class_name GamePhaseMain
extends GamePhaseState

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


func _on_play_card_requested(uuid: String) -> void:
	Loggit.p("Play card requested for card UUID: %s" % uuid, "PlayDebug")
	_try_play_card.rpc_id(1, uuid)


@rpc("any_peer", "call_remote", "reliable")
func _try_play_card(uuid: String) -> void:
	if not _game_manager.multiplayer.is_server():
		return

	var caller_id: int = _game_manager.multiplayer.get_remote_sender_id()

	var game_card = _game_manager.get_player(caller_id).hand.get_card_by_uuid(uuid)
	
	if not game_card:
		push_error("Card with UUID %s not found in player's hand" % uuid)
		return

	var card_data: CardData = CardRegistry.get_card(game_card.data.unique_id)

	if not card_data:
		push_error("Card data not found for id: " + game_card.unique_id)
		return


	if _game_manager.validate_card_play(card_data):
		Loggit.p("Card play validated for card %s with UUID %s" % [card_data.title, uuid], "PlayDebug")
		# _card_played.rpc(_game_manager.multiplayer.get_remote_sender_id(), card_uuid)
		_game_manager.phase_nodes[GameManager.GamePhase.RESOLVING_CARD].card_being_resolved = card_data
		_game_manager.transition_to_phase(GameManager.GamePhase.RESOLVING_CARD)
	else:
		Loggit.p("Card play failed validation for card %s with UUID %s" % [card_data.title, uuid], "PlayDebug")
		_card_play_failed.rpc_id(
			_game_manager.multiplayer.get_remote_sender_id(),
			game_card.uuid,
			"Not enough action points",
		)

	# If we reach here, the card play is valid. Proceed with applying the card's effects.


@rpc("any_peer", "call_remote", "reliable")
func _card_played(peer_id: int, card_uuid: String) -> void:
	SignalBus.card_played.emit(peer_id, card_uuid)


@rpc("any_peer", "call_remote", "reliable")
func _card_play_failed(card_uuid: String, reason: String) -> void:
	SignalBus.card_play_failed.emit(card_uuid, reason)
