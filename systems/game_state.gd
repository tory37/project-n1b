extends Node

## Global Game State Manager (Autoload)
## Manages the Tug-of-War economy and player resources.

enum Player { ONE, TWO }

@export var max_marker_value: float = 5.0
@export var base_income: int = 2

var active_player: Player = Player.ONE
var marker_position: float = 0.0 # Positive for Player 2, Negative for Player 1 (Tug of War)
var player_resources = {
	Player.ONE: {"ap": 1, "coins": 0},
	Player.TWO: {"ap": 0, "coins": 0}
}

func _ready():
	# Initial setup as per MVP plan
	pass

## Move the marker towards the opponent's side.
func spend_ap(amount: int):
	player_resources[active_player]["ap"] -= amount

	# Moving marker: Player 1 moves it towards positive (Player 2 side)
	# Player 2 moves it towards negative (Player 1 side)
	var move_direction = 1.0 if active_player == Player.ONE else -1.0
	marker_position += (amount * move_direction)

	SignalBus.marker_moved.emit(marker_position)
	SignalBus.resources_updated.emit(
		active_player,
		player_resources[active_player]["ap"],
		player_resources[active_player]["coins"]
	)

	if abs(marker_position) >= max_marker_value:
		switch_turn()

func add_coins(player: Player, amount: int):
	player_resources[player]["coins"] += amount
	SignalBus.resources_updated.emit(
		player,
		player_resources[player]["ap"],
		player_resources[player]["coins"]
	)

func switch_turn():
	# Restock merchant would happen here (emitted via signal or called directly)

	active_player = Player.TWO if active_player == Player.ONE else Player.ONE

	# Income phase
	add_coins(active_player, base_income)

	# Marker bonus/reset logic as per design
	# "The opponent then receives those points plus a base amount."
	# For MVP: We convert the marker position into starting AP for the new player.
	var starting_ap = abs(marker_position)
	player_resources[active_player]["ap"] = int(starting_ap)

	# Reset marker for the new turn perspective?
	# Or keep it as a continuous track?
	# Design says "A track shared by both players."
	# If Player 1 pushed it to +6, it starts at +6 for Player 2.

	SignalBus.player_switched.emit(active_player)
	SignalBus.resources_updated.emit(
		active_player,
		player_resources[active_player]["ap"],
		player_resources[active_player]["coins"]
	)

func end_turn_manual():
	# Can only end if marker is on opponent's side
	var is_p1_valid = (active_player == Player.ONE and marker_position > 0)
	var is_p2_valid = (active_player == Player.TWO and marker_position < 0)
	var on_opponent_side = is_p1_valid or is_p2_valid

	if on_opponent_side:
		switch_turn()
