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

## ---- Static Methods ------------------------------------------------

## ---- Lifecycle -----------------------------------------------------


func _ready() -> void:
	if multiplayer.is_server():
		turn_order = $GameState/TurnOrder
	else:
		turn_order = $GameState/TurnOrder
		notify_ready.rpc_id(1)

		

## ---- Public Methods ------------------------------------------------

func get_player(peer_id: int) -> NetworkedPlayer:
	return _player_registry.get_player(peer_id)

func transition_to_phase(phase: GamePhase) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can transition phases")
		return

	_game_fsm.change_state(_phase_constructors[phase].call(self))


func draw_cards(player_id: int, count: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can draw cards")
		return

	var player = _player_registry.get_player(player_id)

	if not player.deck.value.size() >= count:
		push_error(
			"Cannot draw %d cards for player %d: not enough cards in decks" % [count, player_id]
		)
		return

	# EXAMPLE DATA MODIFICATION FLOW: 
	#  We always duplicate, modify, then set to ensure the synced data is 
	#  properly updated and emits signals.
	var new_hand: GameCardCollection = player.hand.value.copy()
	var new_deck: GameCardCollection = player.deck.value.copy()
	var drawn_cards: GameCardCollection = new_deck.pop_back(count)

	new_hand.push_back_collection(drawn_cards)

	player.hand.set_value(new_hand)
	player.deck.set_value(new_deck)

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

		player.seat.set_value(seat)
		player.spirit_points.set_value(starting_spirit_points)
		player.hand.set_value(GameCardCollection.new())
		Loggit.p("Setting up player %d with test deck of %d cards" % [peer_id, test_deck.cards.size()], "CARD_STATE")
		player.deck.set_value(GameCardCollection.from_card_data_array(test_deck.cards.duplicate()))
		player.discard.set_value(GameCardCollection.new())
		
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
		
		_game_fsm = FiniteStateMachine.new()
		transition_to_phase.call_deferred(GamePhase.START)
