extends StaticBody3D

signal hovered()
signal unhovered()

@export var owner_player_id: PlayerSeat.Type = PlayerSeat.PLAYER_ONE
@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D

var _default_material: StandardMaterial3D
var _hovered_material: StandardMaterial3D


func _ready() -> void:
	_default_material = StandardMaterial3D.new()
	_default_material.albedo_color = Color.GRAY
	_hovered_material = StandardMaterial3D.new()
	_hovered_material.albedo_color = Color.YELLOW
	_mesh_instance.material_override = _default_material

	mouse_entered.connect(_on_mouse_enter)
	mouse_exited.connect(_on_mouse_exit)


func set_highlighted(on: bool) -> void:
	if on:
		_mesh_instance.material_override = _hovered_material
	else:
		_mesh_instance.material_override = _default_material


func _input_event(
		_camera: Node,
		event: InputEvent,
		_position: Vector3,
		_normal: Vector3,
		_shape_idx: int,
) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		SignalBus.deck_clicked.emit(owner_player_id)


func _on_mouse_enter() -> void:
	hovered.emit()
	set_highlighted(true)


func _on_mouse_exit() -> void:
	unhovered.emit()
	set_highlighted(false)
