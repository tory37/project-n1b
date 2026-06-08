class_name GameCardUI
extends Node

signal clicked(card: GameCard)

@export var card: GameCard

@onready var _name_label: Label = %TitleLabel
@onready var _action_points_label: Label = %ActionPointsLabel
@onready var _selected_label: Label = %SelectedLabel


func setup() -> void:
	if (card && card.data):
		_name_label.text = card.data.title
		_action_points_label.text = "AP Cost: " + str(card.data.ap_cost)
	else:
		_name_label.text = ""
		_action_points_label.text = ""
		_selected_label.visible = false

	_selected_label.visible = true


func show_selected() -> void:
	_selected_label.visible = true


func hide_selected() -> void:
	_selected_label.visible = false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			clicked.emit(self)
