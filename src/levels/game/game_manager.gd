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
@export var base_income: int = 2
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

## ---- @onready Variables --------------------------------------------

# State

@onready var turn_number: TurnNumberNetworkedState = $GameState/TurnNumber
@onready var active_player: ActivePlayerNetworkedState = $GameState/ActivePlayer
@onready var turn_order: TurnOrderNetworkedState = $GameState/TurnOrder
@onready var action_points: ActionPointsNetworkedState = $GameState/ActionPoints
@onready var currencies: CurrencyNetworkedState = $GameState/Currencies
@onready var hands: GameCardCollectionsNetworkedState = $GameState/Hands
@onready var decks: GameCardCollectionsNetworkedState = $GameState/Decks
@onready var discards: GameCardCollectionsNetworkedState = $GameState/Discards

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner

## ---- Static Methods ------------------------------------------------

## ---- Lifecycle -----------------------------------------------------


func _ready() -> void:
	if multiplayer.is_server():
		Loggit.p("GameManager is server", "Flow")

		_game_fsm = FiniteStateMachine.new()
		_initialize_game_state.call_deferred()
		transition_to_phase.call_deferred(GamePhase.START)

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
			"Error"
		)
		return

	var drawn_cards: GameCardCollection = decks.pop_back(player_id, count)
	for card: GameCard in drawn_cards.value:
		hands.push_back(player_id, card)

## ---- Private Methods -----------------------------------------------


func _initialize_game_state() -> void:
	Loggit.p("Initializing game state", "Flow")

	if not multiplayer.is_server():
		return

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
