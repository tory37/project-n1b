class_name HexTile
extends StaticBody3D

signal tile_hovered(axial: Vector2i)
signal tile_unhovered(axial: Vector2i)


@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D


@export var axial_coord: Vector2i = Vector2i.ZERO

var _default_material: StandardMaterial3D
var _hovered_material: StandardMaterial3D


func _ready() -> void:
	_default_material = StandardMaterial3D.new()
	_default_material.albedo_color = Color.GRAY
	_hovered_material = StandardMaterial3D.new()
	_hovered_material.albedo_color = Color.YELLOW
	_mesh_instance.material_override = _default_material

	## TODO: This is debug
	if axial_coord.x % 2 == 0:
		_default_material.albedo_color = Color.BLUE

	## TODO: This is debug
	if axial_coord == Vector2i.ZERO:
		_default_material.albedo_color = Color.RED

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
		SignalBus.tile_clicked.emit(axial_coord)


func _on_mouse_enter() -> void:
	tile_hovered.emit(axial_coord)
	set_highlighted(true)


func _on_mouse_exit() -> void:
	tile_unhovered.emit(axial_coord)
	set_highlighted(false)
