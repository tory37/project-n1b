extends Node
## Global Game State Manager (Autoload)
## Manages the Tug-of-War economy and player resources.
##
## Networking seam: request_* functions are public entrypoints (future @rpc("any_peer")).
## _apply_* functions are authority-only state mutators (future @rpc("authority")).
## Locally, request_* calls _apply_* directly — zero behavior change, zero networking needed now.

const PLAYER_ONE: int = 0
const PLAYER_TWO: int = 1

@export var max_marker_value: float = 5.0
@export var base_income: int = 2

var active_player: int = PLAYER_ONE
var marker_position: float = 0.0
var player_resources: Dictionary = {
	PLAYER_ONE: { "ap": 1, "currency": 0 },
	PLAYER_TWO: { "ap": 0, "currency": 0 },
}


func _ready() -> void:
	pass


func reset() -> void:
	active_player = PLAYER_ONE
	marker_position = 0.0
	player_resources = {
		PLAYER_ONE: { "ap": 1, "currency": 0 },
		PLAYER_TWO: { "ap": 0, "currency": 0 },
	}


func request_spend_ap(amount: int) -> void:
	_apply_spend_ap(amount)


func _apply_spend_ap(amount: int) -> void:
	player_resources[active_player]["ap"] -= amount

	# DESIGN TODO: marker direction is a 2-player mechanic — revisit if N-player is ever designed
	var move_direction: float = 1.0 if active_player == PLAYER_ONE else -1.0
	marker_position += (amount * move_direction)

	SignalBus.marker_moved.emit(marker_position)
	SignalBus.resources_updated.emit(
		active_player,
		player_resources[active_player]["ap"],
		player_resources[active_player]["currency"],
	)

	if abs(marker_position) >= max_marker_value:
		_apply_switch_turn()


func request_add_currency(player: int, amount: int) -> void:
	_apply_add_currency(player, amount)


func _apply_add_currency(player: int, amount: int) -> void:
	player_resources[player]["currency"] += amount
	SignalBus.resources_updated.emit(
		player,
		player_resources[player]["ap"],
		player_resources[player]["currency"],
	)


func request_switch_turn() -> void:
	_apply_switch_turn()


func _apply_switch_turn() -> void:
	active_player = (active_player + 1) % 2

	_apply_add_currency(active_player, base_income)

	# Convert marker distance into starting AP for the incoming player
	player_resources[active_player]["ap"] = int(abs(marker_position))

	SignalBus.player_switched.emit(active_player)
	SignalBus.resources_updated.emit(
		active_player,
		player_resources[active_player]["ap"],
		player_resources[active_player]["currency"],
	)


func request_end_turn_manual() -> void:
	var is_p1_valid: bool = (active_player == PLAYER_ONE and marker_position > 0)
	var is_p2_valid: bool = (active_player == PLAYER_TWO and marker_position < 0)
	if is_p1_valid or is_p2_valid:
		_apply_switch_turn()
