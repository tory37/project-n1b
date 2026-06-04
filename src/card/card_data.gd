class_name CardData
extends Resource

@export var title: String = "Default Card Title"
@export var ap_cost: int = 1


static func to_dict(card_data: CardData) -> Dictionary:
	var dict: Dictionary = { }
	dict["title"] = card_data.title
	dict["ap_cost"] = card_data.ap_cost
	return dict


static func from_dict(dict: Dictionary) -> CardData:
	var card_data: CardData = CardData.new()
	card_data.title = dict.get("title", "Default Card Title")
	card_data.ap_cost = dict.get("ap_cost", 1)
	return card_data
