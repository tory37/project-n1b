class_name GameManager
extends Node
## Manages the Tug-of-War economy and player resources.
##
## Networking seam: request_* functions are public entrypoints (future @rpc("any_peer")).
## _apply_* functions are authority-only state mutators (future @rpc("authority")).
## Locally, request_* calls _apply_* directly — zero behavior change, zero networking needed now.

## ---- Signals -------------------------------------------------------
signal card_play_validated(card: GameCard)

## ---- Enums ---------------------------------------------------------

## ---- Constants -----------------------------------------------------

## ---- Static Variables ----------------------------------------------

## ---- Exports -------------------------------------------------------

@export var fsm: FiniteStateMachine

# TODO: Make these a resource
@export var starting_action_points: int = 0
@export var starting_spirit_points: int = 0
@export var pass_turn_starting_ap: int = 3

# TODO: Remove - Test data
@export var test_deck: DeckData

## ---- Public Variables ----------------------------------------------
var _run_fsm: FiniteStateMachine = null

## ---- Private Variables ---------------------------------------------

## ---- @onready Variables --------------------------------------------

@onready var player_registry: PlayerRegistry = $PlayerRegistry

# State

@onready var player_1: NetworkedPlayer = $PlayerRegistry/Player1
@onready var player_2: NetworkedPlayer = $PlayerRegistry/Player2

@onready var round_number: RoundNumberComponent = $State/RoundNumberComponent
@onready var active_player: ActivePlayerComponent = $State/ActivePlayerComponent
@onready var turn_order: TurnOrderComponent = $State/TurnOrderComponent
@onready var action_points: ActionPointsComponent = $State/ActionPointsComponent

## ---- Static Methods ------------------------------------------------

## ---- Lifecycle -----------------------------------------------------


func _ready() -> void:
	if not multiplayer.is_server():
		return

	SignalBus.notification_fired.connect(_on_notification_fired)

	# transition_to_phase(entry_phase)
	_run_fsm = fsm.instantiate()
	var context := StateContext.new()
	context.agent = self
	_run_fsm.start(context)

## ---- Public Methods ------------------------------------------------


func get_player(peer_id: int) -> NetworkedPlayer:
	return player_registry.get_player(peer_id)


func draw_cards(player_id: int, count: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can draw cards")
		return

	var player = player_registry.get_player(player_id)

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
	if action_points.value + 10 >= card.ap_cost:
		return true

	return false

## ---- Private Methods -----------------------------------------------


func _on_notification_fired(message: String) -> void:
	emit_game_notification.rpc(message)


@rpc("any_peer", "call_remote", "reliable")
func emit_game_notification(message: String) -> void:
	if multiplayer.is_server():
		return

	SignalBus.notification_fired.emit(message)


@rpc("any_peer", "call_remote", "reliable")
func try_play_card(uuid: String) -> void:
	Loggit.p("Trying to play card with UUID before check: %s" % uuid, "PlayDebug")

	if not multiplayer.is_server():
		return

	var caller_id: int = multiplayer.get_remote_sender_id()
	var game_card = get_player(caller_id).hand.get_card_by_uuid(uuid)

	if not game_card:
		push_error("Card with UUID %s not found in player's hand" % uuid)
		return

	var card_data: CardData = CardRegistry.get_card(game_card.data.unique_id)

	if not card_data:
		push_error("Card data not found for id: " + game_card.unique_id)
		return

	if validate_card_play(card_data):
		# card_played_succeeded.rpc(multiplayer.get_remote_sender_id(), card_uuid)
		card_play_validated.emit(game_card)
	else:
		card_play_failed.rpc_id(
			multiplayer.get_remote_sender_id(),
			game_card.uuid,
			"Not enough action points",
		)

	# If we reach here, the card play is valid. Proceed with applying the card's effects.


@rpc("any_peer", "call_remote", "reliable")
func listen_for_card_play_enabled() -> void:
	Loggit.p("Entered MainPhase", "DrawDebug")
	if multiplayer.is_server():
		return

	SignalBus.play_card_requested.connect(_on_play_card_requested)


@rpc("any_peer", "call_remote", "reliable")
func listen_for_card_play_disabled() -> void:
	if multiplayer.is_server():
		return

	SignalBus.play_card_requested.disconnect(_on_play_card_requested)


@rpc("any_peer", "call_remote", "reliable")
func card_played_succeeded(peer_id: int, card_uuid: String) -> void:
	SignalBus.card_played.emit(peer_id, card_uuid)


@rpc("any_peer", "call_remote", "reliable")
func card_play_failed(card_uuid: String, reason: String) -> void:
	SignalBus.card_play_failed.emit(card_uuid, reason)


@rpc("any_peer", "call_remote", "reliable")
func player_card_play_enabled(enabled: bool) -> void:
	if enabled:
		SignalBus.play_card_enabled.emit()
	else:
		SignalBus.play_card_disabled.emit()


func _on_play_card_requested(uuid: String) -> void:
	Loggit.p("Play card requested for card UUID: %s" % uuid, "PlayDebug")
	try_play_card.rpc_id(1, uuid)
