class_name GameManager
extends Node
## Manages the Tug-of-War economy and player resources.
##
## Networking seam: request_* functions are public entrypoints (future @rpc("any_peer")).
## _apply_* functions are authority-only state mutators (future @rpc("authority")).
## Locally, request_* calls _apply_* directly — zero behavior change, zero networking needed now.

## ---- Signals -------------------------------------------------------

## ---- Enums ---------------------------------------------------------

enum GamePhase {
	WAITING_FOR_PLAYERS,
	START,
	DRAW_CARD,
	MAIN,
	RESOLVING_CARD,
}

## ---- Constants -----------------------------------------------------

## ---- Static Variables ----------------------------------------------

## ---- Exports -------------------------------------------------------

# TODO: Make these a resource
@export var starting_action_points: int = 0
@export var starting_spirit_points: int = 0
@export var pass_turn_starting_ap: int = 3

# TODO: Remove - Test data
@export var test_deck: DeckData

## ---- Public Variables ----------------------------------------------

## ---- Private Variables ---------------------------------------------

var _game_fsm: FiniteStateMachine = null
var _ready_peers: Array[int] = []

## ---- @onready Variables --------------------------------------------

@onready var _player_registry: PlayerRegistry = $PlayerRegistry

# State

@onready var player_1: NetworkedPlayer = $PlayerRegistry/Player1
@onready var player_2: NetworkedPlayer = $PlayerRegistry/Player2

@onready var round_number: RoundNumberComponent = $GameState/RoundNumberComponent
@onready var active_player: ActivePlayerComponent = $GameState/ActivePlayerComponent
@onready var turn_order: TurnOrderComponent = $GameState/TurnOrderComponent
@onready var action_points: ActionPointsComponent = $GameState/ActionPointsComponent
var _phase_nodes: Dictionary

var phase_nodes: Dictionary:
	get:
		return _phase_nodes

## ---- Static Methods ------------------------------------------------

## ---- Lifecycle -----------------------------------------------------


func _ready() -> void:
	if multiplayer.is_server():
		_game_fsm = FiniteStateMachine.new()

		# We don't use as here, because it breaks and returns Nil.  known godot bug.
		_phase_nodes = {
			GamePhase.START: $FSM/Start,
			GamePhase.DRAW_CARD: $FSM/DrawCard,
			GamePhase.MAIN: $FSM/Main,
			GamePhase.RESOLVING_CARD: $FSM/ResolvingCard,
		}

		_phase_nodes[GamePhase.START].setup(self)
		_phase_nodes[GamePhase.DRAW_CARD].setup(self)
		_phase_nodes[GamePhase.MAIN].setup(self)
		_phase_nodes[GamePhase.RESOLVING_CARD].setup(self)

		SignalBus.notification_fired.connect(_on_notification_fired)
	else:
		notify_ready.rpc_id(1)

## ---- Public Methods ------------------------------------------------


func get_player(peer_id: int) -> NetworkedPlayer:
	return _player_registry.get_player(peer_id)


func transition_to_phase(phase: GamePhase, payload: Variant = {}) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can transition phases")
		return

	_game_fsm.change_state(_phase_nodes[phase], payload)


func draw_cards(player_id: int, count: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can draw cards")
		return

	var player = _player_registry.get_player(player_id)

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


func _setup_players() -> void:
	if not multiplayer.is_server():
		return

	var seat = 1
	for peer_id: int in multiplayer.get_peers():
		var player: NetworkedPlayer

		if seat == 1:
			player = player_1
		elif seat == 2:
			player = player_2
		else:
			push_error("Unsupported seat number %d for peer_id %d" % [seat, peer_id])
			continue

		_player_registry.add_player(peer_id, player)

		player.set_peer_id(peer_id)
		player.seat.set_value(seat)
		player.spirit_points.set_value(starting_spirit_points)
		player.hand.setup(peer_id, GameCardCollection.new())
		player.deck.setup(peer_id, GameCardCollection.from_card_data_array(test_deck.cards.duplicate()))
		player.discard.setup(peer_id, GameCardCollection.new())

		seat += 1


func _initialize_game_state() -> void:
	if not multiplayer.is_server():
		return

	for peer_id: int in multiplayer.get_peers():
		turn_order.push_value(peer_id)

	active_player.set_value(turn_order.get_player_at_number(1))


# Apply: Authority State Mutators
func _apply_teardown_player(_peer_id: int) -> void:
	return


@rpc("any_peer", "call_remote", "reliable")
func notify_ready() -> void:
	if not multiplayer.is_server():
		return

	_ready_peers.append(multiplayer.get_remote_sender_id())
	if _ready_peers.size() == multiplayer.get_peers().size():
		_initialize_game_state()
		_setup_players()

		transition_to_phase.call_deferred(GamePhase.START)


func _on_notification_fired(message: String) -> void:
	_emit_game_notification.rpc(message)

@rpc("any_peer", "call_remote", "reliable")
func _emit_game_notification(message: String) -> void:
	if multiplayer.is_server():
		return
		
	SignalBus.notification_fired.emit(message)

