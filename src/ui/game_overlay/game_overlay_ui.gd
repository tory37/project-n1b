extends Node

@onready var _turn_label: Label = %TurnLabel
@onready var _active_player_label: Label = %ActivePlayerLabel
@onready var _ap_label: Label = %ApLabel

@onready var _self_player_number_label: Label = %SelfPlayerNumberLabel
@onready var _self_id_label: Label = %SelfIdLabel
@onready var _self_spirit_points_label: Label = %SelfSpiritPointsLabel
@onready var _self_hand_label: Label = %SelfHandLabel
@onready var _self_deck_label: Label = %SelfDeckLabel
@onready var _self_discard_label: Label = %SelfDiscardLabel

@onready var _opponent_player_number_label: Label = %OpponentPlayerNumberLabel
@onready var _opponent_id_label: Label = %OpponentIdLabel
@onready var _opponent_spirit_points_label: Label = %OpponentSpiritPointsLabel
@onready var _opponent_hand_label: Label = %OpponentHandLabel
@onready var _opponent_deck_label: Label = %OpponentDeckLabel
@onready var _opponent_discard_label: Label = %OpponentDiscardLabel

var _player_registry: PlayerRegistry


func _ready() -> void:
	if multiplayer.is_server():
		return

	Loggit.p("GameOverlayUI ready", "GameOverlayUI")

	Loggit.p("Finding PlayerRegistry node", "SeatFlow")
	_player_registry = get_tree().get_first_node_in_group(
		"player_registry",
	) as PlayerRegistry

	Loggit.p("Connecting to PlayerRegistry.player_added signal", "SeatFlow")

	_player_registry.player_added.connect(_on_player_added)

	SignalBus.turn_order_synced.connect(_on_turn_order_synced)
	SignalBus.active_player_synced.connect(_on_active_player_synced)
	SignalBus.action_points_synced.connect(_on_action_points_synced)
	SignalBus.player_hand_synced.connect(_on_player_hand_synced)
	SignalBus.player_deck_synced.connect(_on_player_deck_synced)
	SignalBus.player_discard_synced.connect(_on_player_discard_synced)


func _exit_tree() -> void:
	if multiplayer.is_server():
		return

	if _player_registry:
		_player_registry.player_added.disconnect(_on_player_added)
		_disconnect_all()


func _on_player_added(peer_id: int, player: NetworkedPlayer) -> void:
	Loggit.p("Received player_added signal for peer_id %d" % peer_id, "SeatFlow")
	if peer_id == multiplayer.get_unique_id():
		Loggit.p("Connecting to self seat synced signal for peer_id %d" % peer_id, "SeatFlow")
		player.seat.synced.connect(_on_self_seat_synced)
		player.spirit_points.synced.connect(_on_self_spirit_points_synced)
	else:
		player.seat.synced.connect(_on_opponent_seat_synced)
		player.spirit_points.synced.connect(_on_opponent_spirit_points_synced)


func _disconnect_all() -> void:
	for player in _player_registry.get_all_players():
		if player.peer_id == multiplayer.get_unique_id():
			player.seat.synced.disconnect(_on_self_seat_synced)
			player.spirit_points.synced.disconnect(_on_self_spirit_points_synced)
		else:
			player.seat.synced.disconnect(_on_opponent_seat_synced)
			player.spirit_points.synced.disconnect(_on_opponent_spirit_points_synced)

	SignalBus.turn_order_synced.disconnect(_on_turn_order_synced)
	SignalBus.active_player_synced.disconnect(_on_active_player_synced)
	SignalBus.action_points_synced.disconnect(_on_action_points_synced)
	SignalBus.player_hand_synced.disconnect(_on_player_hand_synced)
	SignalBus.player_deck_synced.disconnect(_on_player_deck_synced)
	SignalBus.player_discard_synced.disconnect(_on_player_discard_synced)


# Seat
func _on_self_seat_synced(seat: int) -> void:
	Loggit.p("Received self seat synced signal. Seat is now: %d" % seat, "SeatFlow")
	_self_player_number_label.text = "You: %d" % seat


func _on_opponent_seat_synced(seat: int) -> void:
	Loggit.p("Received opponent seat synced signal. Seat is now: %d" % seat, "SeatFlow")
	_opponent_player_number_label.text = "Opponent: %d" % seat


# Spirit Points
func _on_self_spirit_points_synced(spirit_points: int) -> void:
	Loggit.p("Received self spirit points synced signal. Spirit points are now: %d" % spirit_points, "GameOverlayUI")
	_self_spirit_points_label.text = "Spirit Points: %d" % spirit_points


func _on_opponent_spirit_points_synced(spirit_points: int) -> void:
	Loggit.p("Received opponent spirit points synced signal. Spirit points are now: %d" % spirit_points, "GameOverlayUI")
	_opponent_spirit_points_label.text = "Spirit Points: %d" % spirit_points


func _on_turn_order_synced(turn_order: Array[int]) -> void:
	Loggit.p(
		"Received turn order synced signal. Turn order is now: %s" % turn_order,
		"GameOverlayUI",
	)

	var self_player_number: int = turn_order.find(multiplayer.get_unique_id()) + 1
	var self_id: int = multiplayer.get_unique_id()
	_self_player_number_label.text = "You: %d" % self_player_number
	_self_id_label.text = "ID: %d" % self_id

	if turn_order.size() > 1:
		var opponent_player_number: int = 2 if self_player_number == 1 else 1
		var opponent_id: int = turn_order[opponent_player_number - 1]
		_opponent_player_number_label.text = "Opponent: %d" % opponent_player_number
		_opponent_id_label.text = "ID: %d" % opponent_id


func _on_active_player_synced(player_id: int) -> void:
	Loggit.p("Received active player synced signal. Active player is now: %d" % player_id, "GameOverlayUI")
	if player_id == multiplayer.get_unique_id():
		_active_player_label.text = "Active Player: You"
	else:
		_active_player_label.text = "Active Player: %d" % player_id


func _on_action_points_synced(ap: int) -> void:
	Loggit.p("Received AP synced signal. AP is now: %d" % ap, "GameOverlayUI")
	_ap_label.text = "AP: %d" % ap


func _on_player_hand_synced(_player_id: int, hand: GameCardCollection) -> void:
	if _player_id == multiplayer.get_unique_id():
		Loggit.p("Received hand synced signal. Player 1 hand count is now: %d" % hand.cards.size(), "GameOverlayUI")
		_self_hand_label.text = "Hand Count: %s" % hand.cards.size()
	else:
		Loggit.p("Received hand synced signal. Player 2 hand count is now: %d" % hand.cards.size(), "GameOverlayUI")
		_opponent_hand_label.text = "Hand Count: %s" % hand.cards.size()


func _on_player_deck_synced(_player_id: int, deck: GameCardCollection) -> void:
	if _player_id == multiplayer.get_unique_id():
		Loggit.p("Received deck synced signal. Player 1 deck count is now: %d" % deck.cards.size(), "GameOverlayUI")
		_self_deck_label.text = "Deck Count: %s" % deck.cards.size()
	else:
		Loggit.p("Received deck synced signal. Player 2 deck count is now: %d" % deck.cards.size(), "GameOverlayUI")
		_opponent_deck_label.text = "Deck Count: %s" % deck.cards.size()


func _on_player_discard_synced(_player_id: int, discard: GameCardCollection) -> void:
	if _player_id == multiplayer.get_unique_id():
		Loggit.p("Received discard synced signal. Player 1 discard count is now: %d" % discard.cards.size(), "GameOverlayUI")
		_self_discard_label.text = "Discard Count: %s" % discard.cards.size()
	else:
		Loggit.p("Received discard synced signal. Player 2 discard count is now: %d" % discard.cards.size(), "GameOverlayUI")
		_opponent_discard_label.text = "Discard Count: %s" % discard.cards.size()
