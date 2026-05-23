class_name GameManager
extends Node
## GameManager
## Manages the Tug-of-War economy and player resources.
##
## Networking seam: request_* functions are public entrypoints (future @rpc("any_peer")).
## _apply_* functions are authority-only state mutators (future @rpc("authority")).
## Locally, request_* calls _apply_* directly — zero behavior change, zero networking needed now.

@export var max_ap_tracker_value: int = 10
@export var base_income: int = 2
@export var pass_turn_starting_ap: int = 3

# TODO: Remove - Test data
@export var test_deck: DeckData


@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var players_container: Node = $Players


## Whose turn it is currently; changes on switch_turn.
var _player_states: Dictionary[int, PlayerState] = {} # peer_id: PlayerState
var _active_player: PlayerSeat.Type = PlayerSeat.PLAYER_ONE
var _ap_tracker: int = 0

var _game_fsm: FiniteStateMachine = null


## The seat this client controls; fixed after lobby assignment.
func _ready() -> void:
	var _local_player_id: PlayerSeat.Type = PlayerSeat.PLAYER_ONE
	print("[Flow] GameManager ready")

	if multiplayer.is_server():
		# Spawn a player for each connected peer
		for peer_id in NetworkManager.connected_players:
			_initialize_player(peer_id)

		# Also spawn for future connections
		NetworkManager.player_connected.connect(_initialize_player)
		NetworkManager.player_disconnected.connect(_teardown_player)

	_subscribe_to_game_signals()


func _initialize_player(peer_id: int) -> void:
	# Register state, deal starting hand, etc.
	_player_states[peer_id] = PlayerState.new()
	_player_states[peer_id].deck = test_deck.cards.duplicate()


func _teardown_player(peer_id: int) -> void:
	# Cleanup state, etc.
	_player_states.erase(peer_id)

## 


func _on_start_game_requested() -> void:
	print("[Flow] GameManager starting turn FSM")
	_apply_start_game()


func _on_draw_card_requested() -> void:
	print("[Flow] Card draw requested by player")
	_apply_card_draw(_active_player)


func _on_add_ap_requested(amount: int) -> void:
	_apply_add_ap(amount)


func _on_spend_ap_requested(_player_id: int, amount: int) -> void:
	if not can_spend_ap(amount):
		SignalBus.ap_spend_failed.emit(_active_player)
		return
	_apply_spend_ap(amount)


func _on_add_currency_requested(player: int, amount: int) -> void:
	_apply_add_currency(player, amount)


func _on_switch_turn_requested() -> void:
	_apply_switch_turn()


func _on_pass_turn_requested() -> void:
	_apply_pass_turn()


# Debug
func _on_print_players_hands_requested() -> void:
	_print_players_hands()


func can_spend_ap(amount: int) -> bool:
	if _is_player_1():
		return amount <= _ap_tracker + max_ap_tracker_value

	return amount <= abs(_ap_tracker) + max_ap_tracker_value


func _subscribe_to_game_signals() -> void:
	print("[Flow] GameManager subscribing to signals")
	SignalBus.game_start_requested.connect(_on_start_game_requested)
	SignalBus.draw_card_requested.connect(_on_draw_card_requested)
	SignalBus.add_ap_requested.connect(_on_add_ap_requested)
	SignalBus.spend_ap_requested.connect(_on_spend_ap_requested)
	SignalBus.add_currency_requested.connect(_on_add_currency_requested)
	SignalBus.switch_turn_requested.connect(_on_switch_turn_requested)
	SignalBus.pass_turn_requested.connect(_on_pass_turn_requested)

	# TODO: Remove - Debug
	SignalBus.print_players_hands_requested.connect(_on_print_players_hands_requested)


func _is_player_1() -> bool:
	return _active_player == PlayerSeat.PLAYER_ONE


func _apply_start_game() -> void:
	print("[Flow] GameManager applying start game")
	SignalBus.game_state_initialized.emit(_active_player, _ap_tracker)
	SignalBus.player_state_initialized.emit(_player_states[_active_player])
	
	_game_fsm = FiniteStateMachine.new()
	_game_fsm.change_state(GameStartPhase.new(_game_fsm))


func _apply_card_draw(player_id: int) -> void:
	if not _player_states.has(player_id):
		print("[Error] Invalid player ID for card draw: %d" % player_id)
		return

	print("[Flow] Applying card draw for player %d" % player_id)
	_player_states[player_id].deck_to_hand()
	print("[Flow] Player %d hand after draw: %s" % [player_id, _player_states[player_id].hand])
	SignalBus.card_draw_animation_complete.emit.call_deferred()


func _apply_add_ap(amount: int) -> void:
	if _is_player_1():
		_ap_tracker = clamp(_ap_tracker + amount, -max_ap_tracker_value, max_ap_tracker_value)
	else:
		_ap_tracker = clamp(_ap_tracker - amount, -max_ap_tracker_value, max_ap_tracker_value)
	SignalBus.ap_tracker_moved.emit(_ap_tracker)


func _apply_spend_ap(amount: int) -> void:
	# DESIGN TODO: ap tracker direction is a 2-player mechanic
	#   revisit if N-player is ever designed
	if _is_player_1():
		_ap_tracker = clamp(_ap_tracker - amount, -max_ap_tracker_value, max_ap_tracker_value)
	else:
		_ap_tracker = clamp(_ap_tracker + amount, -max_ap_tracker_value, max_ap_tracker_value)

	SignalBus.ap_tracker_moved.emit(_ap_tracker)

	if _is_player_1():
		if _ap_tracker < 0:
			_apply_switch_turn()
	elif _ap_tracker > 0:
		_apply_switch_turn()


func _apply_add_currency(player: int, amount: int) -> void:
	_player_states[player].currency += amount
	SignalBus.player_currency_updated.emit(
		player,
		_player_states[player].currency,
	)


func _apply_switch_turn() -> void:
	_active_player = (_active_player + 1) % 2
	SignalBus.player_switched.emit(_active_player)
	_game_fsm.change_state(GamePhaseDrawCard.new(_game_fsm))
	_apply_add_currency(_active_player, base_income)


func _apply_pass_turn() -> void:
	if _is_player_1():
		_ap_tracker = -pass_turn_starting_ap
	else:
		_ap_tracker = pass_turn_starting_ap
	SignalBus.ap_tracker_moved.emit(_ap_tracker)
	_apply_switch_turn()


func _print_players_hands() -> void:
	print("Player 1 hand:")
	for card in _player_states[PlayerSeat.PLAYER_ONE].hand:
		print("- %s" % card.name)

	print("Player 2 hand:")
	for card in _player_states[PlayerSeat.PLAYER_TWO].hand:
		print("- %s" % card.name)
