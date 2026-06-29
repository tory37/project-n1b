class_name CardManager
extends SubGameManager


#region Server

# Setup
func _ready() -> void:
	if not multiplayer.is_server():
		return

	ServerSignalBus.card_play_enabled.connect(_on_card_play_enabled)
	ServerSignalBus.card_draw_requested.connect(_on_server_card_draw_requested)


func _exit_tree() -> void:
	if not multiplayer.is_server():
		return

	if ServerSignalBus.card_play_enabled.is_connected(_on_card_play_enabled):
		ServerSignalBus.card_play_enabled.disconnect(_on_card_play_enabled)
	if ServerSignalBus.card_play_disabled.is_connected(_on_card_play_disabled):
		ServerSignalBus.card_play_disabled.disconnect(_on_card_play_disabled)
	if ServerSignalBus.card_draw_requested.is_connected(_on_server_card_draw_requested):
		ServerSignalBus.card_draw_requested.disconnect(_on_server_card_draw_requested)


# Server Signal Handlers
func _on_card_play_enabled(peer_id: int) -> void:
	ServerSignalBus.card_play_enabled.disconnect(_on_card_play_enabled)
	ServerSignalBus.card_play_disabled.connect(_on_card_play_disabled)
	enable_card_play.rpc_id(peer_id)


func _on_card_play_disabled(peer_id: int) -> void:
	ServerSignalBus.card_play_disabled.disconnect(_on_card_play_disabled)
	disable_card_play.rpc_id(peer_id)

func _on_server_card_draw_requested(player_id: int, count: int) -> void:
	draw_cards(player_id, count)


# Server Side RPCs
@rpc("any_peer", "call_remote", "reliable")
func request_card_play(uuid: String) -> void:
	Loggit.p("Trying to play card with UUID before check: %s" % uuid, "PlayDebug")

	if not multiplayer.is_server():
		return

	var caller_id: int = multiplayer.get_remote_sender_id()
	var game_card = _game_manager.get_player(caller_id).hand.get_card_by_uuid(uuid)

	if not game_card:
		push_error("Card with UUID %s not found in player's hand" % uuid)
		return

	var card_data: CardData = CardRegistry.get_card(game_card.data.unique_id)

	if not card_data:
		push_error("Card data not found for id: " + game_card.unique_id)
		return

	if validate_card_play(card_data):
		# card_played_succeeded.rpc(multiplayer.get_remote_sender_id(), card_uuid)
		ServerSignalBus.card_play_validated.emit(game_card)
	else:
		card_play_failed.rpc_id(
			multiplayer.get_remote_sender_id(),
			game_card.uuid,
			"Not enough action points",
		)

	# If we reach here, the card play is valid. Proceed with applying the card's effects.


# Helper Methods
func draw_cards(player_id: int, count: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can draw cards")
		return

	var player = _game_manager.player_registry.get_player(player_id)

	if not player.deck.value.size() >= count:
		push_error(
			"Cannot draw %d cards for player %d: not enough cards in decks" % [count, player_id],
		)
		return

	# EXAMPLE DATA MODIFICATION FLOW: 
	#  We always duplicate, modify, then set to ensure the synced data is 
	#  properly updated and emits signals.
	var new_hand: GameCardCollection = player.hand.value.copy()
	var new_deck: GameCardCollection = player.deck.value.copy()
	var drawn_cards: GameCardCollection = new_deck.pop_back(count)

	Loggit.p("Drawing %d cards for player %d" % [count, player_id], "DrawDebug")

	new_hand.push_back_collection(drawn_cards)

	player.hand.set_value(new_hand)
	player.deck.set_value(new_deck)


# TODO: Extend this to check "requirements" in the card data.
# TODO: Implement "requirements" in the card data.
func validate_card_play(card: CardData) -> bool:
	if not multiplayer.is_server():
		push_error("validate_card_play should only be called on the server")
		return false

	if _game_manager.action_points.value + 10 >= card.ap_cost:
		return true

	return false

#endregion


#region Client

# Signal Handlers
func _on_play_card_requested(uuid: String) -> void:
	Loggit.p("Play card requested for card UUID: %s" % uuid, "PlayDebug")
	request_card_play.rpc_id(1, uuid)


# Client Side RPCs
@rpc("any_peer", "call_remote", "reliable")
func enable_card_play() -> void:
	if multiplayer.is_server():
		return

	ClientSignalBus.card_play_requested.connect(_on_play_card_requested)
	ClientSignalBus.card_play_enabled.emit()


@rpc("any_peer", "call_remote", "reliable")
func disable_card_play() -> void:
	if multiplayer.is_server():
		return

	ClientSignalBus.card_play_requested.disconnect(_on_play_card_requested)
	ClientSignalBus.card_play_disabled.emit()


@rpc("any_peer", "call_remote", "reliable")
func card_played_succeeded(peer_id: int, card_uuid: String) -> void:
	SignalBus.card_play_request_succeeded.emit(peer_id, card_uuid)


@rpc("any_peer", "call_remote", "reliable")
func card_play_failed(card_uuid: String, reason: String) -> void:
	SignalBus.card_play_request_failed.emit(card_uuid, reason)

#endregion