class_name GameCard
extends RefCounted

var revealed: bool = false
var data: CardData = null

func _init(card_data: CardData) -> void:
	data = card_data