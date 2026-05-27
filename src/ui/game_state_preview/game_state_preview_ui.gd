extends Node
## UI component to display AP and Currency for the active player.

func _ready() -> void:
	SignalBus.active_player_synced.connect(_on_active_player_synced)
	SignalBus.ap_synced.connect(_on_ap_synced)
	SignalBus.currency_synced.connect(_on_currency_synced)
	SignalBus.turn_synced.connect(_on_turn_synced)
	SignalBus.player_hand_synced.connect(_on_player_hand_synced)
	SignalBus.player_deck_synced.connect(_on_player_deck_synced)
	SignalBus.player_discard_synced.connect(_on_player_discard_synced)


func _exit_tree() -> void:
	SignalBus.active_player_synced.disconnect(_on_active_player_synced)
	SignalBus.ap_synced.disconnect(_on_ap_synced)
	SignalBus.currency_synced.disconnect(_on_currency_synced)
	SignalBus.turn_synced.disconnect(_on_turn_synced)
	SignalBus.player_hand_synced.disconnect(_on_player_hand_synced)
	SignalBus.player_deck_synced.disconnect(_on_player_deck_synced)
	SignalBus.player_discard_synced.disconnect(_on_player_discard_synced)


func _on_active_player_synced(player_id: int) -> void:
	Loggit.p("Received active player synced signal. Active player is now: %d" % player_id, "Flow")


func _on_ap_synced(ap: int) -> void:
	Loggit.p("Received AP synced signal. AP is now: %d" % ap, "Flow")


func _on_currency_synced(player_id: int, currency: int) -> void:
	Loggit.p(
		"Received currency synced signal. Player %d currency is now: %d" % [player_id, currency],
		"Flow",
	)


func _on_turn_synced(turn: int) -> void:
	Loggit.p("Received turn synced signal. Turn is now: %d" % turn, "Flow")


func _on_player_hand_synced(player_id: int, hand: GameCardCollection) -> void:
	var card_titles: String = ""
	for card in hand.cards:
		if card is GameCard:
			card_titles += card.data.title + ", "
		else: 
			card_titles += "Hidden" + ", "
	Loggit.p("Player %d hand is: %s" % [player_id, card_titles], "Flow")


func _on_player_deck_synced(player_id: int, deck: GameCardCollection) -> void:
	var card_titles: String = ""
	for card in deck.cards:
		if card is GameCard:
			card_titles += card.data.title + ", "
		else:
			card_titles += "Hidden" + ", "
	Loggit.p("Player %d deck is: %s" % [player_id, card_titles], "Flow")


func _on_player_discard_synced(player_id: int, discard: GameCardCollection) -> void:
	var card_titles: String = ""
	for card in discard.cards:
		if card is GameCard:
			card_titles += card.data.title + ", "
		else:
			card_titles += "Hidden" + ", "
	Loggit.p("Player %d discard is: %s" % [player_id, card_titles], "Flow")
