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
# We do not block use to the active plaer as there are times when the active player is not the one requesting AP (e.g. during opponent's turn, or when a card effect is used).
# TODO: This will need to be handled correctly though when that feature is implemented in a card
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

	_initialize_player(1)
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
	var next_id: int = _get_next_player_id()
	if (next_id == _game_state.player_id_turn_order[0]):
		_apply_increment_turn()
	_apply_active_player(next_id)


func _apply_increment_turn() -> void:
	_game_state.turn += 1

	_rpc_sync_turn.rpc(_game_state.turn)


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
func _rpc_sync_turn(turn: int) -> void:
	_game_state.turn = turn

	SignalBus.turn_synced.emit(turn)


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


func _get_next_player_id() -> int:
	var current_id: int = _game_state.active_player_id
	var current_index: int = _game_state.player_id_turn_order.find(current_id)
	if current_index == -1:
		Loggit.p("Current player ID not found in turn order: %d" % current_id, "Error")
		return -1

	var next_index: int = (current_index + 1) % _game_state.player_id_turn_order.size()
	return _game_state.player_id_turn_order[next_index]


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