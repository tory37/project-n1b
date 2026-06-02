extends Node
## UI component to display AP and Currency for the active player.

@onready var _turn_label: Label = %TurnLabel
@onready var _active_player_label: Label = %ActivePlayerLabel
@onready var _ap_label: Label = %ApLabel

@onready var _self_player_number_label: Label = %SelfPlayerNumberLabel
@onready var _self_id_label: Label = %SelfIdLabel
@onready var _self_currency_label: Label = %SelfCurrencyLabel
@onready var _self_hand_label: Label = %SelfHandLabel
@onready var _self_deck_label: Label = %SelfDeckLabel
@onready var _self_discard_label: Label = %SelfDiscardLabel

@onready var _opponent_player_number_label: Label = %OpponentPlayerNumberLabel
@onready var _opponent_id_label: Label = %OpponentIdLabel
@onready var _opponent_currency_label: Label = %OpponentCurrencyLabel
@onready var _opponent_hand_label: Label = %OpponentHandLabel
@onready var _opponent_deck_label: Label = %OpponentDeckLabel
@onready var _opponent_discard_label: Label = %OpponentDiscardLabel


func _ready() -> void:
	Loggit.p("GameOverlayUI ready", "GameOverlayUI")
	SignalBus.turn_number_synced.connect(_on_turn_number_synced)
	SignalBus.turn_order_synced.connect(_on_turn_order_synced)
	SignalBus.active_player_synced.connect(_on_active_player_synced)
	SignalBus.action_points_synced.connect(_on_action_points_synced)
	SignalBus.currency_synced.connect(_on_currency_synced)
	SignalBus.player_hand_synced.connect(_on_player_hand_synced)
	SignalBus.player_deck_synced.connect(_on_player_deck_synced)
	SignalBus.player_discard_synced.connect(_on_player_discard_synced)


func _exit_tree() -> void:
	SignalBus.turn_number_synced.disconnect(_on_turn_number_synced)
	SignalBus.turn_order_synced.disconnect(_on_turn_order_synced)
	SignalBus.active_player_synced.disconnect(_on_active_player_synced)
	SignalBus.action_points_synced.disconnect(_on_action_points_synced)
	SignalBus.currency_synced.disconnect(_on_currency_synced)
	SignalBus.player_hand_synced.disconnect(_on_player_hand_synced)
	SignalBus.player_deck_synced.disconnect(_on_player_deck_synced)
	SignalBus.player_discard_synced.disconnect(_on_player_discard_synced)


func _on_turn_number_synced(turn: int) -> void:
	Loggit.p("Received turn number synced signal. Turn is now: %d" % turn, "GameOverlayUI")
	_turn_label.text = "Turn: %d" % turn


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


func _on_currency_synced(_player_id: int, currency: int) -> void:
	if _player_id == multiplayer.get_unique_id():
		Loggit.p("Received currency synced signal. Player 1 currency is now: %d" % currency, "GameOverlayUI")
		_self_currency_label.text = "Currency: %d" % currency
	else:
		Loggit.p("Received currency synced signal. Player 2 currency is now: %d" % currency, "GameOverlayUI")
		_opponent_currency_label.text = "Currency: %d" % currency


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
