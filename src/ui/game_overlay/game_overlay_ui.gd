extends Node

@export var card_ui_scene: PackedScene

@onready var _round_number_label: Label = %RoundNumberLabel
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

@onready var _resolving_card_container: Node = $ResolvingCardPanel/Container

var _player_registry: PlayerRegistry


func _ready() -> void:
	if multiplayer.is_server():
		return

	_player_registry = get_tree().get_first_node_in_group(
		"player_registry",
	) as PlayerRegistry

	_player_registry.player_added.connect(_on_player_added)

	SignalBus.round_number_synced.connect(_on_round_number_synced)
	SignalBus.turn_order_synced.connect(_on_turn_order_synced)
	SignalBus.active_player_synced.connect(_on_active_player_synced)
	SignalBus.action_points_synced.connect(_on_action_points_synced)
	ClientSignalBus.card_resolution_started.connect(_on_card_resolution_started)
	ClientSignalBus.card_resolution_completed.connect(_on_card_resolution_completed)


func _exit_tree() -> void:
	if multiplayer.is_server():
		return

	if _player_registry:
		_player_registry.player_added.disconnect(_on_player_added)
		_disconnect_all()


func _on_player_added(peer_id: int, player: NetworkedPlayer) -> void:
	if peer_id == multiplayer.get_unique_id():
		player.seat.synced.connect(_on_self_seat_synced)
		player.spirit_points.synced.connect(_on_self_spirit_points_synced)
		player.hand.set_synced.connect(_on_self_hand_synced)
		player.hand.cards_added_synced.connect(_on_self_hand_cards_added)
		player.hand.cards_removed_synced.connect(_on_self_hand_cards_removed)
		player.deck.set_synced.connect(_on_self_deck_synced)
		player.deck.cards_added_synced.connect(_on_self_deck_cards_added)
		player.deck.cards_removed_synced.connect(_on_self_deck_cards_removed)
		player.discard.set_synced.connect(_on_self_discard_synced)
		player.discard.cards_added_synced.connect(_on_self_discard_cards_added)
		player.discard.cards_removed_synced.connect(_on_self_discard_cards_removed)
	else:
		player.seat.synced.connect(_on_opponent_seat_synced)
		player.spirit_points.synced.connect(_on_opponent_spirit_points_synced)
		player.hand.set_synced.connect(_on_opponent_hand_synced)
		player.deck.set_synced.connect(_on_opponent_deck_synced)
		player.discard.set_synced.connect(_on_opponent_discard_synced)


func _disconnect_all() -> void:
	for player in _player_registry.get_all_players():
		if player.peer_id == multiplayer.get_unique_id():
			player.seat.synced.disconnect(_on_self_seat_synced)
			player.spirit_points.synced.disconnect(_on_self_spirit_points_synced)
			player.hand.set_synced.disconnect(_on_self_hand_synced)
			player.deck.set_synced.disconnect(_on_self_deck_synced)
			player.discard.set_synced.disconnect(_on_self_discard_synced)
		else:
			player.seat.synced.disconnect(_on_opponent_seat_synced)
			player.spirit_points.synced.disconnect(_on_opponent_spirit_points_synced)
			player.hand.set_synced.disconnect(_on_opponent_hand_synced)
			player.deck.set_synced.disconnect(_on_opponent_deck_synced)
			player.discard.set_synced.disconnect(_on_opponent_discard_synced)

	SignalBus.turn_order_synced.disconnect(_on_turn_order_synced)
	SignalBus.active_player_synced.disconnect(_on_active_player_synced)
	SignalBus.action_points_synced.disconnect(_on_action_points_synced)


# Seat
func _on_self_seat_synced(seat: int) -> void:
	_self_player_number_label.text = "You are player: %d" % seat


func _on_opponent_seat_synced(seat: int) -> void:
	_opponent_player_number_label.text = "Opponent is player: %d" % seat


# Spirit Points
func _on_self_spirit_points_synced(spirit_points: int) -> void:
	_self_spirit_points_label.text = "Spirit Points: %d" % spirit_points


func _on_opponent_spirit_points_synced(spirit_points: int) -> void:
	_opponent_spirit_points_label.text = "Spirit Points: %d" % spirit_points


# Hand
func _on_self_hand_synced(hand: GameCardCollection) -> void:
	_self_hand_label.text = "Hand Count: %s" % hand.cards.size()


func _on_self_hand_cards_added(added_cards: GameCardCollection) -> void:
	var current_count: int = int(_self_hand_label.text.split(": ")[1])
	_self_hand_label.text = "Hand Count: %d" % (current_count + added_cards.cards.size())


func _on_self_hand_cards_removed(removed_uuids: Array[String]) -> void:
	var current_count: int = int(_self_hand_label.text.split(": ")[1])
	_self_hand_label.text = "Hand Count: %d" % (current_count - removed_uuids.size())


func _on_opponent_hand_synced(hand: GameCardCollection) -> void:
	_opponent_hand_label.text = "Hand Count: %s" % hand.cards.size()


# Deck
func _on_self_deck_synced(deck: GameCardCollection) -> void:
	_self_deck_label.text = "Deck Count: %s" % deck.cards.size()


func _on_self_deck_cards_added(added_cards: GameCardCollection) -> void:
	var current_count: int = int(_self_deck_label.text.split(": ")[1])
	_self_deck_label.text = "Deck Count: %d" % (current_count + added_cards.cards.size())


func _on_self_deck_cards_removed(removed_uuids: Array[String]) -> void:
	var current_count: int = int(_self_deck_label.text.split(": ")[1])
	_self_deck_label.text = "Deck Count: %d" % (current_count - removed_uuids.size())


func _on_opponent_deck_synced(deck: GameCardCollection) -> void:
	_opponent_deck_label.text = "Deck Count: %s" % deck.cards.size()


# Discard
func _on_self_discard_synced(discard: GameCardCollection) -> void:
	_self_discard_label.text = "Discard Count: %s" % discard.cards.size()


func _on_self_discard_cards_added(added_cards: GameCardCollection) -> void:
	var current_count: int = int(_self_discard_label.text.split(": ")[1])
	_self_discard_label.text = "Discard Count: %d" % (current_count + added_cards.cards.size())


func _on_self_discard_cards_removed(removed_uuids: Array[String]) -> void:
	var current_count: int = int(_self_discard_label.text.split(": ")[1])
	_self_discard_label.text = "Discard Count: %d" % (current_count - removed_uuids.size())


func _on_opponent_discard_synced(discard: GameCardCollection) -> void:
	_opponent_discard_label.text = "Discard Count: %s" % discard.cards.size()


# Round Number
func _on_round_number_synced(round_number: int) -> void:
	_round_number_label.text = "Round: %d" % round_number

# Turn Order


func _on_turn_order_synced(turn_order: Array[int]) -> void:
	var self_player_number: int = turn_order.find(multiplayer.get_unique_id()) + 1
	var self_id: int = multiplayer.get_unique_id()
	_self_player_number_label.text = "You are: %d" % self_player_number
	_self_id_label.text = "ID: %d" % self_id

	if turn_order.size() > 1:
		var opponent_player_number: int = 2 if self_player_number == 1 else 1
		var opponent_id: int = turn_order[opponent_player_number - 1]
		_opponent_player_number_label.text = "Opponent is: %d" % opponent_player_number
		_opponent_id_label.text = "ID: %d" % opponent_id

# Active Player


func _on_active_player_synced(player_id: int) -> void:
	if player_id == multiplayer.get_unique_id():
		_active_player_label.text = "Active Player: You"
	else:
		_active_player_label.text = "Active Player: %d" % player_id

# Action Points


func _on_action_points_synced(ap: int) -> void:
	_ap_label.text = "AP: %d" % ap


# Card Resolution

func _on_card_resolution_started(card_data: CardData) -> void:
	var card_ui_instance = card_ui_scene.instantiate() as GameCardUI
	_resolving_card_container.add_child(card_ui_instance)
	card_ui_instance.card = card_data
	card_ui_instance.setup()
	card_ui_instance.hide_selected()

func _on_card_resolution_completed() -> void:
	_resolving_card_container.clear()	
