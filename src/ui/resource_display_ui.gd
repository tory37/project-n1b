extends Node
## UI component to display AP and Currency for the active player.


func _ready() -> void:
	SignalBus.active_player_synced.connect(_on_active_player_synced)
	SignalBus.ap_synced.connect(_on_ap_synced)	
	SignalBus.currency_synced.connect(_on_currency_synced)
	SignalBus.player_hand_synced.connect(_on_player_hand_synced)
	SignalBus.player_deck_synced.connect(_on_player_deck_synced)


func _on_active_player_synced(player_id: int) -> void:
	Loggit.p("Game State Update: Active player is now: %d" % player_id, "Flow")


func _on_ap_synced(ap: int) -> void:
	Loggit.p("Game State Update: AP is now: %d" % ap, "Flow")


func _on_currency_synced(player_id: int, currency: int) -> void:
	Loggit.p("Game State Update: Player %d currency is now: %d" % [player_id, currency], "Flow")


func _on_player_hand_synced(player_id: int, hand: Array[GameCard]) -> void:
	var card_names: String = ""
	for card in hand:
		card_names += card.name + ", "
	Loggit.p("Game State Update: Player %d hand is: %s" % [player_id, card_names], "Flow")


func _on_player_deck_synced(player_id: int, deck: Array[GameCard]) -> void:
	var card_names: String = ""
	for card in deck:
		if card is GameCard:
			card_names += card.name + ", "
		else:
			card_names += "Hidden" + ", "
	Loggit.p("Game State Update: Player %d deck is: %s" % [player_id, card_names], "Flow")


func _on_player_discard_synced(player_id: int, discard: Array[GameCard]) -> void:
	var card_names: String = ""
	for card in discard:
		card_names += card.name + ", "
	Loggit.p("Game State Update: Player %d discard is: %s" % [player_id, card_names], "Flow")