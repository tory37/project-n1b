class_name GameCardUI
extends Node

@export var card: GameCard

@onready var _name_label: Label = %TitleLabel
@onready var _action_points_label: Label = %ActionPointsLabel

func setup() -> void:
	_name_label.text = card.data.title
	_action_points_label.text = str(card.data.ap_cost)
