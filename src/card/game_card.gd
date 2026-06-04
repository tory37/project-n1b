class_name GameCard
extends Resource

@export var revealed: bool = false
@export var data: CardData = null

static func to_dict(card: GameCard) -> Dictionary:
	var dict: Dictionary = {}

	if card != null:
		dict["revealed"] = card.revealed
		dict["data"] = CardData.to_dict(card.data)
	
	return dict

static func from_dict(dict: Dictionary) -> GameCard:
	var revealed: bool = dict.get("revealed", false)
	var data_dict: Dictionary = dict.get("data", {})
	var data = CardData.from_dict(data_dict)

	var card = GameCard.new()
	card.revealed = revealed
	card.data = data

	return card
