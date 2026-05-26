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

# TODO: Make these a resource
@export var max_ap_value: int = 10
@export var base_income: int = 2
@export var pass_turn_starting_ap: int = 3

# TODO: Remove - Test data
@export var test_deck: DeckData


## ---- Public Variables ----------------------------------------------


## ---- Private Variables ---------------------------------------------

var _game_state: GameState = GameState.new()
var _game_fsm: FiniteStateMachine = null
var _phase_constructors: Dictionary = {
	GameState.Phase.START:     func(gm): return GamePhaseStart.new(gm),
	GameState.Phase.DRAW_CARD: func(gm): return GamePhaseDrawCard.new(gm),
	GameState.Phase.MAIN:      func(gm): return GamePhaseMain.new(gm),
}


## ---- @onready Variables --------------------------------------------

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner


## ---- Static Methods ------------------------------------------------


## ---- Lifecycle -----------------------------------------------------
func _ready() -> void:
	Loggit.p("GameManager ready", "Flow")

	if multiplayer.is_server():
		Loggit.p("GameManager is server", "Flow")

		_game_fsm = FiniteStateMachine.new()
		transition_to_phase(GameState.Phase.START)
	else:
		SignalBus.add_ap_requested.connect(_on_add_ap_requested)


func _exit_tree() -> void:
	if not multiplayer.is_server():
		SignalBus.add_ap_requested.disconnect(_on_add_ap_requested)


## ---- Signal Callbacks ----------------------------------------------
func _on_add_ap_requested(amount: int) -> void:
	if multiplayer.is_server():
		return

	request_spend_ap.rpc_id(1, amount)

## ---- Public Methods ------------------------------------------------

# Getters

func get_turn() -> int:
	return _game_state.turn


func get_current_phase() -> GameState.Phase:
	return _game_state.current_phase


func get_active_player_id() -> int:
	return _game_state.active_player_id


func get_ap() -> int:
	return _game_state.ap


func get_player_id_turn_order() -> Array[int]:
	return _game_state.player_id_turn_order


func get_player_currency(player_id: int) -> int:
	if not _game_state.player_states.has(player_id):
		Loggit.p("Invalid player ID for currency retrieval: %d" % player_id, "Error")
		return 0

	return _game_state.player_states[player_id].currency


func get_player_hand(player_id: int) -> Array[GameCard]:
	if not _game_state.player_states.has(player_id):
		Loggit.p("Invalid player ID for hand retrieval: %d" % player_id, "Error")
		return []

	return _game_state.player_states[player_id].hand


func get_player_deck(player_id: int) -> Array[GameCard]:
	if not _game_state.player_states.has(player_id):
		Loggit.p("Invalid player ID for deck retrieval: %d" % player_id, "Error")
		return []

	return _game_state.player_states[player_id].deck


func get_player_discard(player_id: int) -> Array[GameCard]:
	if not _game_state.player_states.has(player_id):
		Loggit.p("Invalid player ID for discard retrieval: %d" % player_id, "Error")
		return []

	return _game_state.player_states[player_id].discard


# Requests (Any Peer)

@rpc("any_peer", "reliable")
func request_spend_ap(amount: int) -> void:
	if not multiplayer.is_server():
		Loggit.p("Only the server can process spend AP requests", "Error")
		return

	var player_id: int = multiplayer.get_remote_sender_id()
	_apply_spend_ap(amount)


# Sync
func sync_active_player_to_all_peers() -> void:
	if not multiplayer.is_server():
		Loggit.p("Only the server can sync game state to peers", "Error")
		return

	_rpc_sync_active_player.rpc(_game_state.active_player_id)


func sync_ap_to_all_peers() -> void:
	if not multiplayer.is_server():
		Loggit.p("Only the server can sync game state to peers", "Error")
		return

	_rpc_sync_ap.rpc(_game_state.ap)


func sync_player_currency_to_all_peers(player_id: int) -> void:
	if not multiplayer.is_server():
		Loggit.p("Only the server can sync game state to peers", "Error")
		return

	var player_state: PlayerState = _game_state.player_states[player_id]

	_rpc_sync_player_currency.rpc(
		player_id,
		player_state.currency,
	)


func sync_player_hand_to_all_peers(player_id: int) -> void:
	if not multiplayer.is_server():
		Loggit.p("Only the server can sync game state to peers", "Error")
		return

	var hand: Array[GameCard] = _game_state.player_states[player_id].hand

	_rpc_sync_player_hand.rpc_id(
		player_id,
		player_id,
		hand,
	)

	_rpc_sync_player_hand.rpc_id(
		_get_opponent_id(player_id),
		player_id,
		_get_masked_cards(hand),
	)


func sync_player_deck_to_all_peers(player_id: int) -> void:
	if not multiplayer.is_server():
		Loggit.p("Only the server can sync game state to peers", "Error")
		return

	var deck: Array[GameCard] = _game_state.player_states[player_id].deck

	_rpc_sync_player_deck.rpc_id(
		player_id,
		player_id,
		deck
	)

	_rpc_sync_player_deck.rpc_id(
		_get_opponent_id(player_id),
		player_id,
		_get_masked_cards(deck)
	)


func sync_player_discard_to_all_peers(player_id: int) -> void:
	if not multiplayer.is_server():
		Loggit.p("Only the server can sync game state to peers", "Error")
		return

	var discard: Array[GameCard] = _game_state.player_states[player_id].discard

	_rpc_sync_player_discard.rpc_id(
		player_id,
		player_id,
		discard
	)

	_rpc_sync_player_discard.rpc_id(
		_get_opponent_id(player_id),
		player_id,
		_get_masked_cards(discard)
	)


# FSM

func transition_to_phase(phase: GameState.Phase) -> void:
	_game_state.current_phase = phase
	_game_fsm.change_state(_phase_constructors[phase].call(self))


# Checks

func can_spend_ap(player_id: int, amount: int) -> bool:
	if _is_player_1(player_id):
		return amount <= _game_state.ap + max_ap_value

	return amount <= abs(_game_state.ap) + max_ap_value


func can_draw_card(player_id: int) -> bool:
	if not _game_state.player_states.has(player_id):
		Loggit.p("Invalid player ID for can card draw: %d" % player_id, "Error")
		return false

	return _game_state.player_states[player_id].deck.size() > 0


# Exposed Actions for GamePhaseStates
func initialize_all_players() -> void:
	if not multiplayer.is_server():
		Loggit.p("Only the server can initialize players", "Error")
		return

	for peer_id in multiplayer.get_peers():
		_initialize_player(peer_id)


func draw_cards(player_id: int, count: int) -> void:
	if not multiplayer.is_server():
		Loggit.p("Only the server can draw cards", "Error")
		return

	_apply_draw_cards(player_id, count)


func add_currency(player_id: int, amount: int) -> void:
	if not multiplayer.is_server():
		Loggit.p("Only the server can add currency", "Error")
		return

	_apply_add_currency(player_id, amount)


func set_active_player(player_id: int) -> void:
	if not multiplayer.is_server():
		Loggit.p("Only the server can set the active player", "Error")
		return

	_apply_active_player(player_id)


# Debug
func print_game_state() -> void:
	_game_state.print_debug_state()


## ---- Private Methods -----------------------------------------------

# Apply: Authority State Mutators 

func _apply_active_player(player_id: int) -> void:
	_game_state.active_player_id = player_id

	_rpc_sync_active_player.rpc(player_id)


func _apply_teardown_player(peer_id: int) -> void:
	_game_state.player_states.erase(peer_id)


func _apply_draw_cards(player_id: int, count: int) -> void:
	if not _game_state.player_states.has(player_id):
		Loggit.p("Invalid player ID for card draw: %d" % player_id, "Error")
		return

	_game_state.player_states[player_id].deck_to_hand(count)

	Loggit.p(
		"Player %d hand after draw: %s" % [player_id, _game_state.player_states[player_id].hand], 
		"Flow"
	)

	sync_player_hand_to_all_peers(player_id)


func _apply_add_ap(amount: int) -> void:
	_game_state.ap = clamp(
		_game_state.ap + amount, 
		-max_ap_value, 
		max_ap_value
	)

	_rpc_sync_ap.rpc(_game_state.ap)


func _apply_spend_ap(amount: int) -> void:
	_game_state.ap = clamp(
		_game_state.ap - amount,
		-max_ap_value,
		max_ap_value
	)
	
	_rpc_sync_ap.rpc(_game_state.ap)

func _apply_add_currency(player: int, amount: int) -> void:
	_game_state.player_states[player].currency += amount

	_rpc_sync_player_currency.rpc(player, _game_state.player_states[player].currency)


func _apply_switch_turn() -> void:
	_game_state.active_player_id = (_game_state.active_player_id + 1) % 2
	SignalBus.player_switched.emit(_game_state.active_player_id)
	transition_to_phase(GameState.Phase.DRAW_CARD)
	_apply_add_currency(_game_state.active_player_id, base_income)


func _apply_pass_turn() -> void:
	if _is_player_1(_game_state.active_player_id):
		_game_state.ap = -pass_turn_starting_ap
	else:
		_game_state.ap = pass_turn_starting_ap

	SignalBus.ap_moved.emit(_game_state.ap)
	_apply_switch_turn()


# --- RPC ---

@rpc("authority", "reliable")
func _rpc_register_player(peer_id: int) -> void:
	if not _game_state.player_states.has(peer_id):
		_game_state.player_states[peer_id] = PlayerState.new()


@rpc("authority", "reliable")
func _rpc_sync_active_player(active_player_id: int) -> void:
	_game_state.active_player_id = active_player_id

	SignalBus.active_player_synced.emit(active_player_id)


@rpc("authority", "reliable")
func _rpc_sync_ap(ap: int) -> void:
	_game_state.ap = ap

	SignalBus.ap_synced.emit(ap)


@rpc("authority", "reliable")
func _rpc_sync_player_currency(
	player_id: int, 
	player_currency: int, 
) -> void:
	_game_state.player_states[player_id].currency = player_currency

	SignalBus.currency_synced.emit(player_id, player_currency)


@rpc("authority", "reliable")
func _rpc_sync_player_hand(player_id: int, hand: Array[GameCard]) -> void:
	_game_state.player_states[player_id].hand = hand

	SignalBus.player_hand_synced.emit(player_id, hand)


@rpc("authority", "reliable")
func _rpc_sync_player_deck(player_id: int, deck: Array[GameCard]) -> void:
	_game_state.player_states[player_id].deck = deck

	SignalBus.player_deck_synced.emit(player_id, deck)


@rpc("authority", "reliable")
func _rpc_sync_player_discard(player_id: int, discard: Array[GameCard]) -> void:
	_game_state.player_states[player_id].discard = discard


	SignalBus.player_discard_synced.emit(player_id, discard)


func _serialize_own_state(player_state: PlayerState) -> Dictionary:
	return {
		"currency": player_state.currency,
		"hand": player_state.hand,
		"deck": player_state.deck,
		"discard": player_state.discard,
	}


# --- Helpers ---

func _initialize_player(peer_id: int) -> void:
	_game_state.player_states[peer_id] = PlayerState.new()
	_rpc_register_player.rpc(peer_id)

	var new_deck: Array[GameCard] = []
	for card_data: CardData in test_deck.cards:
		new_deck.append(GameCard.new(card_data))
	_game_state.player_states[peer_id].deck = new_deck

	_game_state.player_id_turn_order.append(peer_id)


func _is_player_1(player_id: int) -> bool:
	return _game_state.player_id_turn_order.find(player_id) == 0


func _get_opponent_id(player_id: int) -> int:
	for id in _game_state.player_states.keys():
		if id != player_id:
			return id
	return -1


func _get_masked_cards(opponent_hand: Array[GameCard]) -> Array[GameCard]:
	var masked_opponent_hand: Array[GameCard] = []
	for opponent_card in opponent_hand:
		if opponent_card is GameCard:
			if opponent_card.revealed:
				masked_opponent_hand.append(opponent_card)
			else:
				masked_opponent_hand.append(null)
		else:
			masked_opponent_hand.append(null)

	return masked_opponent_hand


func _get_opponent_state(player_id: int) -> PlayerState:
	var opponent_id: int = _get_opponent_id(player_id)
	if opponent_id == -1:
		return null

	return _game_state.player_states[opponent_id]


# --- Debug ---

func _print_players_hands() -> void:
	Loggit.p("Player 1 hand: %s" % _game_state.player_states[_game_state.player_id_turn_order[0]].hand, "Debug")
	Loggit.p("Player 2 hand: %s" % _game_state.player_states[_game_state.player_id_turn_order[1]].hand, "Debug")
