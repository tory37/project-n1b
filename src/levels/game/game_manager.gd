class_name GameManager
extends Node
## Manages the Tug-of-War economy and player resources.
##
## Networking seam: request_* functions are public entrypoints (future @rpc("any_peer")).
## _apply_* functions are authority-only state mutators (future @rpc("authority")).
## Locally, request_* calls _apply_* directly — zero behavior change, zero networking needed now.

## ---- Signals -------------------------------------------------------

## ---- Enums ---------------------------------------------------------

## ---- Constants -----------------------------------------------------

## ---- Static Variables ----------------------------------------------

## ---- Exports -------------------------------------------------------

@export var entry_phase: GamePhase

# TODO: Make these a resource
@export var starting_action_points: int = 0
@export var starting_spirit_points: int = 0
@export var pass_turn_starting_ap: int = 3

# TODO: Remove - Test data
@export var test_deck: DeckData

## ---- Public Variables ----------------------------------------------
var ready_peers: Array[int] = []


## ---- Private Variables ---------------------------------------------

var _game_fsm: FiniteStateMachineNode = null

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
	if multiplayer.is_server():
		_game_fsm = FiniteStateMachineNode.new()

		SignalBus.notification_fired.connect(_on_notification_fired)

		transition_to_phase(entry_phase)

## ---- Public Methods ------------------------------------------------


func get_player(peer_id: int) -> NetworkedPlayer:
	return player_registry.get_player(peer_id)


func transition_to_phase(phase: GamePhase, payload: Variant = { }) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can transition phases")
		return

	_game_fsm.change_state(phase, payload)


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
	_emit_game_notification.rpc(message)


@rpc("any_peer", "call_remote", "reliable")
func _emit_game_notification(message: String) -> void:
	if multiplayer.is_server():
		return

	SignalBus.notification_fired.emit(message)
