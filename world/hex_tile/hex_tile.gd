extends StaticBody3D

@export var axial_coord: Vector2i = Vector2i.ZERO

signal tile_clicked(axial: Vector2i)
signal tile_hovered(axial: Vector2i)
signal tile_unhovered(axial: Vector2i)

var _default_material: StandardMaterial3D
var _hovered_material: StandardMaterial3D
var _mesh_instance: MeshInstance3D


func _ready() -> void:
	_mesh_instance = $MeshInstance3D
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


func _input_event(camera: Node, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tile_clicked.emit(axial_coord)


func _on_mouse_enter() -> void:
	tile_hovered.emit(axial_coord)
	set_highlighted(true)


func _on_mouse_exit() -> void:
	tile_unhovered.emit(axial_coord)
	set_highlighted(false)
