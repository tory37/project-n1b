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
var _phase_constructors: Dictionary = {
	GamePhase.START: func(gm): return GamePhaseStart.new(gm),
	GamePhase.DRAW_CARD: func(gm): return GamePhaseDrawCard.new(gm),
	GamePhase.MAIN: func(gm): return GamePhaseMain.new(gm),
}
var _ready_peers: Array[int] = []

## ---- @onready Variables --------------------------------------------

@onready var _player_registry: PlayerRegistry = $PlayerRegistry

# State

@onready var player_1: NetworkedPlayer = $PlayerRegistry/Player1
@onready var player_2: NetworkedPlayer = $PlayerRegistry/Player2

@onready var active_player: ActivePlayerNetworkedState = $GameState/ActivePlayer
@onready var turn_order: TurnOrderNetworkedState
@onready var action_points: ActionPointsNetworkedState = $GameState/ActionPoints
@onready var hands: GameCardCollectionsNetworkedState = $GameState/Hands
@onready var decks: GameCardCollectionsNetworkedState = $GameState/Decks
@onready var discards: GameCardCollectionsNetworkedState = $GameState/Discards

## ---- Static Methods ------------------------------------------------

## ---- Lifecycle -----------------------------------------------------


func _ready() -> void:
	if multiplayer.is_server():
		turn_order = $GameState/TurnOrder
		Loggit.p("GameManager is server", "SeatFlow")
	else:
		turn_order = $GameState/TurnOrder
		notify_ready.rpc_id(1)

		

## ---- Public Methods ------------------------------------------------


func transition_to_phase(phase: GamePhase) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can transition phases")
		return

	_game_fsm.change_state(_phase_constructors[phase].call(self))


func draw_cards(player_id: int, count: int) -> void:
	if not multiplayer.is_server():
		Loggit.p("Only the server can draw cards", "Error")
		return

	if not decks.can_pop_cards(player_id, count):
		Loggit.p(
			"Cannot draw %d cards for player %d: not enough cards in decks" % [count, player_id],
			"Error",
		)
		return

	var drawn_cards: GameCardCollection = decks.pop_back(player_id, count)
	for card: GameCard in drawn_cards.value:
		hands.push_back(player_id, card)

## ---- Private Methods -----------------------------------------------


func _setup_players() -> void:
	Loggit.p("Entering _setup_players", "SeatFlow")
	if not multiplayer.is_server():
		return

	Loggit.p("Setting up players", "SeatFlow")
	var seat = 1
	for peer_id: int in multiplayer.get_peers():
		Loggit.p("Instantiating player for peer_id %d at seat %d" % [peer_id, seat], "SeatFlow")
		var player

		if seat == 1:
			player = player_1
		elif seat == 2:
			player = player_2
		else:
			push_error("Unsupported seat number %d for peer_id %d" % [seat, peer_id])
			continue

		_player_registry.add_player(peer_id, player)

		player.seat.set_value(seat)
		player.spirit_points.set_value(starting_spirit_points)
		
		seat += 1


func _initialize_game_state() -> void:
	if not multiplayer.is_server():
		return

	Loggit.p("Initializing game state", "Flow")

	for peer_id: int in multiplayer.get_peers():
		Loggit.p("Initializing game state for peer %d" % peer_id, "Flow")
		turn_order.push_value(peer_id)
		Loggit.p("Initializing deck for peer %d" % peer_id, "Flow")
		decks.from_card_data(peer_id, test_deck.cards.duplicate())

	Loggit.p("Setting turn number to 1", "Flow")
	active_player.set_value(turn_order.get_player_at_number(1))


# Apply: Authority State Mutators
func _apply_teardown_player(_peer_id: int) -> void:
	return


@rpc("any_peer", "call_remote", "reliable")
func notify_ready() -> void:
	if not multiplayer.is_server():
		Loggit.p("Notifying server of ready state", "SeatFlow")
		return

	_ready_peers.append(multiplayer.get_remote_sender_id())
	if _ready_peers.size() == multiplayer.get_peers().size():
		_initialize_game_state()
		Loggit.p("Finished initializing game state", "SeatFlow")
		_setup_players()
		
		_game_fsm = FiniteStateMachine.new()
		transition_to_phase.call_deferred(GamePhase.START)