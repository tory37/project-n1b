extends Node3D

class_name HexBoard

@export var hex_size: float = 1.0
## TODO: Handle having matching sides.  We need to use odd number width and heights, and force it
@export var board_width_radius: int = 5
@export var board_height_radius: int = 3
@export var orientation: HexOrientation.Type = HexOrientation.POINTY_TOP
@export var hex_tile_scene: PackedScene

const FLAT_TOP_ROTATION: Vector3 = deg_to_rad(30) * Vector3(0, 1, 0)

var _tiles: Dictionary = { }


func _ready() -> void:
	if hex_tile_scene == null:
		push_error("HexBoard: hex_tile_scene not assigned")
		return
	generate()


func generate() -> void:
	_tiles.clear()
	for x in range(-board_width_radius, board_width_radius + 1):
		for y in range(-board_height_radius, board_height_radius + 1):
			_spawn_tile(x, y)


func get_tile(axial: Vector2i) -> Node:
	return _tiles.get(axial, null)


func _spawn_tile(x: int, y: int) -> void:
	var tile: Node = hex_tile_scene.instantiate()

	var axial_coord: Vector2i
	if orientation == HexOrientation.POINTY_TOP:
		axial_coord = HexUtils.evenr_to_axial(x, y)
	else:
		axial_coord = HexUtils.oddq_to_axial(x, y)

	var q = axial_coord.x
	var r = axial_coord.y
	var world_pos: Vector3 = HexUtils.axial_to_world(q, r, hex_size, orientation)
	tile.position = world_pos

	if orientation == HexOrientation.FLAT_TOP:
		tile.rotation = FLAT_TOP_ROTATION

	tile.axial_coord = Vector2i(q, r)
	add_child(tile)
	_tiles[Vector2i(q, r)] = tile
