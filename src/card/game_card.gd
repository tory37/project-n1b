class_name GameCard
extends Resource

@export var uuid: String = ""
@export var revealed: bool = false
@export var data: CardData = null


func _init() -> void:
	uuid = UUID.v7()


static func to_dict(card: GameCard) -> Dictionary:
	var dict: Dictionary = { }

	if card != null:
		dict["uuid"] = card.uuid
		dict["revealed"] = card.revealed
		if card.data != null:
			dict["unique_id"] = card.data.unique_id

	return dict


static func from_dict(dict: Dictionary) -> GameCard:
	Loggit.p("Deserializing GameCard from dict with keys: %s" % str(dict.keys()), "DeckDebug")
	var uuid: String = dict.get("uuid", "")
	var revealed: bool = dict.get("revealed", false)
	var unique_id: String = dict.get("unique_id", "")

	var card = GameCard.new()
	card.uuid = uuid
	card.revealed = revealed

	if unique_id != "":
		var data = CardRegistry.get_card(unique_id)
		card.data = data

	return card


func mask_card() -> void:
	if not revealed:
		data = null
