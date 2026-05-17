extends Node
## Global Game State Manager (Autoload)
## Manages the Tug-of-War economy and player resources.
##
## Networking seam: request_* functions are public entrypoints (future @rpc("any_peer")).
## _apply_* functions are authority-only state mutators (future @rpc("authority")).
## Locally, request_* calls _apply_* directly — zero behavior change, zero networking needed now.

const PLAYER_ONE: int = 0
const PLAYER_TWO: int = 1

@export var max_ap_tracker_value: float = 10.0
@export var base_income: int = 2
@export var pass_turn_starting_ap: int = 3

var active_player: int = PLAYER_ONE
var ap_tracker: float = 0.0
var player_resources: Dictionary = {
	PLAYER_ONE: { "currency": 0 },
	PLAYER_TWO: { "currency": 0 },
}


func _ready() -> void:
	pass


func reset() -> void:
	active_player = PLAYER_ONE
	ap_tracker = 0.0
	player_resources = {
		PLAYER_ONE: { "currency": 0 },
		PLAYER_TWO: { "currency": 0 },
	}


func _is_player_1() -> bool:
	return active_player == PLAYER_ONE


func request_add_ap(amount: int) -> void:
	_apply_add_ap(amount)


func _apply_add_ap(amount: int) -> void:
	if _is_player_1():
		ap_tracker = clamp(ap_tracker + amount, -max_ap_tracker_value, max_ap_tracker_value)
	else:
		ap_tracker = clamp(ap_tracker - amount, -max_ap_tracker_value, max_ap_tracker_value)
	SignalBus.ap_tracker_moved.emit(ap_tracker)


func can_spend_ap(amount: int) -> bool:
	if _is_player_1():
		return amount <= ap_tracker + max_ap_tracker_value

	return amount <= abs(ap_tracker) + max_ap_tracker_value


func request_spend_ap(amount: int) -> void:
	if not can_spend_ap(amount):
		SignalBus.ap_spend_failed.emit(active_player)
		return
	_apply_spend_ap(amount)


func _apply_spend_ap(amount: int) -> void:
	# DESIGN TODO: ap tracker direction is a 2-player mechanic
	#   revisit if N-player is ever designed
	if _is_player_1():
		ap_tracker = clamp(ap_tracker - amount, -max_ap_tracker_value, max_ap_tracker_value)
	else:
		ap_tracker = clamp(ap_tracker + amount, -max_ap_tracker_value, max_ap_tracker_value)

	SignalBus.ap_tracker_moved.emit(ap_tracker)
	SignalBus.resources_updated.emit(
		active_player,
		player_resources[active_player]["currency"],
	)

	if _is_player_1():
		if ap_tracker < 0:
			_apply_switch_turn()
	elif ap_tracker > 0:
		_apply_switch_turn()


func request_add_currency(player: int, amount: int) -> void:
	_apply_add_currency(player, amount)


func _apply_add_currency(player: int, amount: int) -> void:
	player_resources[player]["currency"] += amount
	SignalBus.resources_updated.emit(
		player,
		player_resources[player]["currency"],
	)


func request_switch_turn() -> void:
	_apply_switch_turn()


func _apply_switch_turn() -> void:
	active_player = (active_player + 1) % 2
	SignalBus.player_switched.emit(active_player)
	_apply_add_currency(active_player, base_income)


func request_pass_turn() -> void:
	_apply_pass_turn()

func _apply_pass_turn() -> void:
	if _is_player_1():
		ap_tracker = -pass_turn_starting_ap
	else:
		ap_tracker = pass_turn_starting_ap
	SignalBus.ap_tracker_moved.emit(ap_tracker)
	_apply_switch_turn()