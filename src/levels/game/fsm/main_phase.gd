class_name MainPhase
extends GamePhase

@export var on_card_played_phase: GamePhase

func enter(_payload: Variant) -> void:
	if not _game_manager.multiplayer.is_server():
		return

	_state_entered.rpc()

	var current_player_id: int = _game_manager.active_player.value
	_player_card_play_enabled.rpc_id(current_player_id, true)


func exit() -> void:
	if not _game_manager.multiplayer.is_server():
		return

	_state_exited.rpc()
	var current_player_id: int = _game_manager.active_player.value
	_player_card_play_enabled.rpc_id(current_player_id, false)

# Play Card


func _on_play_card_requested(uuid: String) -> void:
	Loggit.p("Play card requested for card UUID: %s" % uuid, "PlayDebug")
	_try_play_card.rpc_id(1, uuid)


@rpc("any_peer", "call_remote", "reliable")
func _try_play_card(uuid: String) -> void:
	Loggit.p("Trying to play card with UUID before check: %s" % uuid, "PlayDebug")

	if not _game_manager.multiplayer.is_server():
		return

	Loggit.p("Trying to play card with UUID after check: %s" % uuid, "PlayDebug")

	var caller_id: int = _game_manager.multiplayer.get_remote_sender_id()

	Loggit.p("Caller ID for play card request: %d" % caller_id, "PlayDebug")

	var game_card = _game_manager.get_player(caller_id).hand.get_card_by_uuid(uuid)

	Loggit.p("Game card found in player's hand: %s" % (game_card != null), "PlayDebug")

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
		_game_manager.transition_to_phase(on_card_played_phase, card_data)
	else:
		Loggit.p("Card play failed validation for card %s with UUID %s" % [card_data.title, uuid], "PlayDebug")
		_card_play_failed.rpc_id(
			_game_manager.multiplayer.get_remote_sender_id(),
			game_card.uuid,
			"Not enough action points",
		)

	# If we reach here, the card play is valid. Proceed with applying the card's effects.


@rpc("any_peer", "call_remote", "reliable")
func _state_entered() -> void:
	Loggit.p("Entered MainPhase", "DrawDebug")
	if _game_manager.multiplayer.is_server():
		return

	SignalBus.play_card_requested.connect(_on_play_card_requested)


@rpc("any_peer", "call_remote", "reliable")
func _state_exited() -> void:
	if _game_manager.multiplayer.is_server():
		return

	SignalBus.play_card_requested.disconnect(_on_play_card_requested)


@rpc("any_peer", "call_remote", "reliable")
func _card_played(peer_id: int, card_uuid: String) -> void:
	SignalBus.card_played.emit(peer_id, card_uuid)


@rpc("any_peer", "call_remote", "reliable")
func _card_play_failed(card_uuid: String, reason: String) -> void:
	SignalBus.card_play_failed.emit(card_uuid, reason)


@rpc("any_peer", "call_remote", "reliable")
func _player_card_play_enabled(enabled: bool) -> void:
	if enabled:
		SignalBus.play_card_enabled.emit()
	else:
		SignalBus.play_card_disabled.emit()
