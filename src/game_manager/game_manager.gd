class_name GameManager
extends Node
## GameManager
## Manages the Tug-of-War economy and player resources.
##
## Networking seam: request_* functions are public entrypoints (future @rpc("any_peer")).
## _apply_* functions are authority-only state mutators (future @rpc("authority")).
## Locally, request_* calls _apply_* directly — zero behavior change, zero networking needed now.

@export var max_ap_tracker_value: float = 10.0
@export var base_income: int = 2
@export var pass_turn_starting_ap: int = 3

# TODO: Remove - Test data
@export var test_deck: DeckData = DeckData.new()

## Whose turn it is currently; changes on switch_turn.
var active_player: PlayerSeat.Type = PlayerSeat.PLAYER_ONE
## The seat this client controls; fixed after lobby assignment.
var local_player_id: PlayerSeat.Type = PlayerSeat.PLAYER_ONE
var ap_tracker: float = 0.0
var player_game_state: Dictionary[int, PlayerGameState] = {
	PlayerSeat.PLAYER_ONE: PlayerGameState.new(),
	PlayerSeat.PLAYER_TWO: PlayerGameState.new(),
}

var game_phase_fsm: FiniteStateMachine = null
var turn_phase_fsm: FiniteStateMachine = null


func _init() -> void:
	active_player = PlayerSeat.PLAYER_ONE
	ap_tracker = 0.0
	player_game_state = {
		PlayerSeat.PLAYER_ONE: PlayerGameState.new(),
		PlayerSeat.PLAYER_TWO: PlayerGameState.new(),
	}

	player_game_state[PlayerSeat.PLAYER_ONE].currency = 0
	player_game_state[PlayerSeat.PLAYER_TWO].currency = 0


func _ready() -> void:
	print("[Flow] GameManager ready")

	player_game_state[PlayerSeat.PLAYER_ONE].deck = test_deck.cards.duplicate()
	player_game_state[PlayerSeat.PLAYER_TWO].deck = test_deck.cards.duplicate()

	_subscribe_to_game_signals()


func _on_start_game_requested() -> void:
	print("[Flow] GameManager starting turn FSM")
	_apply_start_game()


func _on_request_card_draw() -> void:
	print("[Flow] Card draw requested by player")
	_apply_card_draw(active_player)


func _on_add_ap_requested(_player_id: int, amount: int) -> void:
	_apply_add_ap(amount)


func _on_spend_ap_requested(_player_id: int, amount: int) -> void:
	if not can_spend_ap(amount):
		SignalBus.ap_spend_failed.emit(active_player)
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
		return amount <= ap_tracker + max_ap_tracker_value

	return amount <= abs(ap_tracker) + max_ap_tracker_value


func _subscribe_to_game_signals() -> void:
	print("[Flow] GameManager subscribing to signals")
	SignalBus.game_start_requested.connect(_on_start_game_requested)
	SignalBus.card_draw_requested.connect(_on_request_card_draw)
	SignalBus.add_ap_requested.connect(_on_add_ap_requested)
	SignalBus.spend_ap_requested.connect(_on_spend_ap_requested)
	SignalBus.add_currency_requested.connect(_on_add_currency_requested)
	SignalBus.switch_turn_requested.connect(_on_switch_turn_requested)
	SignalBus.pass_turn_requested.connect(_on_pass_turn_requested)

	# TODO: Remove - Debug
	SignalBus.print_players_hands_requested.connect(_on_print_players_hands_requested)


func _is_player_1() -> bool:
	return active_player == PlayerSeat.PLAYER_ONE


func _apply_start_game() -> void:
	print("[Flow] GameManager applying start game")
	SignalBus.game_state_initialized.emit(active_player, ap_tracker)
	SignalBus.player_game_state_initialized.emit(player_game_state[active_player])
	turn_phase_fsm = FiniteStateMachine.new()
	turn_phase_fsm.change_state(TurnPhaseDrawCard.new(turn_phase_fsm))


func _apply_card_draw(player_id: int) -> void:
	if not player_game_state.has(player_id):
		print("[Error] Invalid player ID for card draw: %d" % player_id)
		return

	print("[Flow] Applying card draw for player %d" % player_id)
	player_game_state[player_id].deck_to_hand()
	print("[Flow] Player %d hand after draw: %s" % [player_id, player_game_state[player_id].hand])
	SignalBus.card_draw_animation_complete.emit.call_deferred()


func _apply_add_ap(amount: int) -> void:
	if _is_player_1():
		ap_tracker = clamp(ap_tracker + amount, -max_ap_tracker_value, max_ap_tracker_value)
	else:
		ap_tracker = clamp(ap_tracker - amount, -max_ap_tracker_value, max_ap_tracker_value)
	SignalBus.ap_tracker_moved.emit(ap_tracker)


func _apply_spend_ap(amount: int) -> void:
	# DESIGN TODO: ap tracker direction is a 2-player mechanic
	#   revisit if N-player is ever designed
	if _is_player_1():
		ap_tracker = clamp(ap_tracker - amount, -max_ap_tracker_value, max_ap_tracker_value)
	else:
		ap_tracker = clamp(ap_tracker + amount, -max_ap_tracker_value, max_ap_tracker_value)

	SignalBus.ap_tracker_moved.emit(ap_tracker)

	if _is_player_1():
		if ap_tracker < 0:
			_apply_switch_turn()
	elif ap_tracker > 0:
		_apply_switch_turn()


func _apply_add_currency(player: int, amount: int) -> void:
	player_game_state[player].currency += amount
	SignalBus.player_currency_updated.emit(
		player,
		player_game_state[player].currency,
	)


func _apply_switch_turn() -> void:
	active_player = (active_player + 1) % 2
	SignalBus.player_switched.emit(active_player)
	turn_phase_fsm.change_state(TurnPhaseDrawCard.new(turn_phase_fsm))
	_apply_add_currency(active_player, base_income)


func _apply_pass_turn() -> void:
	if _is_player_1():
		ap_tracker = -pass_turn_starting_ap
	else:
		ap_tracker = pass_turn_starting_ap
	SignalBus.ap_tracker_moved.emit(ap_tracker)
	_apply_switch_turn()


func _print_players_hands() -> void:
	print("Player 1 hand:")
	for card in player_game_state[PlayerSeat.PLAYER_ONE].hand:
		print("- %s" % card.name)

	print("Player 2 hand:")
	for card in player_game_state[PlayerSeat.PLAYER_TWO].hand:
		print("- %s" % card.name)
