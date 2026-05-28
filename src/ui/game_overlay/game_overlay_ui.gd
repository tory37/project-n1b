extends Node
## UI component to display AP and Currency for the active player.

@onready var _you_are_label: Label = %YouAreLabel
@onready var _turn_label: Label = %TurnLabel
@onready var _active_player_label: Label = %ActivePlayerLabel
@onready var _ap_label: Label = %ApLabel
@onready var _p1_currency_label: Label = %P1CurrencyLabel
@onready var _p2_currency_label: Label = %P2CurrencyLabel
@onready var _p1_hand_label: Label = %P1HandLabel
@onready var _p2_hand_label: Label = %P2HandLabel
@onready var _p1_deck_label: Label = %P1DeckLabel
@onready var _p2_deck_label: Label = %P2DeckLabel
@onready var _p1_discard_label: Label = %P1DiscardLabel
@onready var _p2_discard_label: Label = %P2DiscardLabel


func _ready() -> void:
	SignalBus.player_number_synced.connect(_on_player_number_synced)
	SignalBus.active_player_synced.connect(_on_active_player_synced)
	SignalBus.action_points_synced.connect(_on_action_points_synced)
	SignalBus.currency_synced.connect(_on_currency_synced)
	SignalBus.player_hand_synced.connect(_on_player_hand_synced)
	SignalBus.player_deck_synced.connect(_on_player_deck_synced)
	SignalBus.player_discard_synced.connect(_on_player_discard_synced)


func _exit_tree() -> void:
	SignalBus.player_number_synced.disconnect(_on_player_number_synced)
	SignalBus.active_player_synced.disconnect(_on_active_player_synced)
	SignalBus.action_points_synced.disconnect(_on_action_points_synced)
	SignalBus.currency_synced.disconnect(_on_currency_synced)
	SignalBus.player_hand_synced.disconnect(_on_player_hand_synced)
	SignalBus.player_deck_synced.disconnect(_on_player_deck_synced)
	SignalBus.player_discard_synced.disconnect(_on_player_discard_synced)


func _on_player_number_synced(player_number: int) -> void:
	Loggit.p("Received player number synced signal. Player number is now: %d" % player_number, "GameOverlayUI")
	_you_are_label.text = "You are Player %d" % player_number


func _on_active_player_synced(player_id: int) -> void:
	Loggit.p("Received active player synced signal. Active player is now: %d" % player_id, "GameOverlayUI")
	_active_player_label.text = "Active Player: %d" % player_id


func _on_action_points_synced(ap: int) -> void:
	Loggit.p("Received AP synced signal. AP is now: %d" % ap, "GameOverlayUI")
	_ap_label.text = "AP: %d" % ap


func _on_currency_synced(_player_id: int, player_number: int, currency: int) -> void:
	if player_number == 1:
		Loggit.p("Received currency synced signal. Player 1 currency is now: %d" % currency, "GameOverlayUI")
		_p1_currency_label.text = "Currency: %d" % currency
	elif player_number == 2:
		Loggit.p("Received currency synced signal. Player 2 currency is now: %d" % currency, "GameOverlayUI")
		_p2_currency_label.text = "Currency: %d" % currency
	else:
		Loggit.p("Received currency synced signal for unknown player number: %d" % player_number, "GameOverlayUI")


func _on_player_hand_synced(_player_id: int, player_number: int, hand: GameCardCollection) -> void:
	if player_number == 1:
		Loggit.p("Received hand synced signal. Player 1 hand count is now: %d" % hand.cards.size(), "GameOverlayUI")
		_p1_hand_label.text = "Hand: %s" % hand.cards.size()
	elif player_number == 2:
		Loggit.p("Received hand synced signal. Player 2 hand count is now: %d" % hand.cards.size(), "GameOverlayUI")
		_p2_hand_label.text = "Hand: %s" % hand.cards.size()
	else:
		Loggit.p("Received hand synced signal for unknown player number: %d" % player_number, "GameOverlayUI")


func _on_player_deck_synced(_player_id: int, player_number: int, deck: GameCardCollection) -> void:
	if player_number == 1:
		Loggit.p("Received deck synced signal. Player 1 deck count is now: %d" % deck.cards.size(), "GameOverlayUI")
		_p1_deck_label.text = "Deck: %s" % deck.cards.size()
	elif player_number == 2:
		Loggit.p("Received deck synced signal. Player 2 deck count is now: %d" % deck.cards.size(), "GameOverlayUI")
		_p2_deck_label.text = "Deck: %s" % deck.cards.size()
	else:
		Loggit.p("Received deck synced signal for unknown player number: %d" % player_number, "GameOverlayUI")


func _on_player_discard_synced(
		_player_id: int,
		player_number: int,
		discard: GameCardCollection,
) -> void:
	if player_number == 1:
		Loggit.p("Received discard synced signal. Player 1 discard count is now: %d" % discard.cards.size(), "GameOverlayUI")
		_p1_discard_label.text = "Discard: %s" % discard.cards.size()
	elif player_number == 2:
		Loggit.p("Received discard synced signal. Player 2 discard count is now: %d" % discard.cards.size(), "GameOverlayUI")
		_p2_discard_label.text = "Discard: %s" % discard.cards.size()
	else:
		Loggit.p("Received discard synced signal for unknown player number: %d" % player_number, "GameOverlayUI")
