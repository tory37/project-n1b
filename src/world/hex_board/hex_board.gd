class_name HexBoard
extends Node3D

const FLAT_TOP_ROTATION: Vector3 = deg_to_rad(30) * Vector3(0, 1, 0)

@export var hex_size: float = 1.0
@export var board_width_radius: int = 5
@export var board_height_radius: int = 3
@export var orientation: HexOrientation.Type = HexOrientation.POINTY_TOP
@export var hex_tile_scene: PackedScene


var _tiles: Dictionary[Vector2i, HexTile] = { }


func _ready() -> void:
	if hex_tile_scene == null:
		push_error("HexBoard: hex_tile_scene not assigned")
		return
	generate()


## TODO: Pointy top does not generate a perfectly symmetric board because
##   of the way the hexes are staggered.
func generate() -> void:
	_tiles.clear()
	for col in range(-board_width_radius, board_width_radius + 1):
		var row_start: int = -board_height_radius - 1
		for row in range(row_start, board_height_radius + 1):
			if orientation == HexOrientation.FLAT_TOP and row == row_start and col % 2 != 0:
				continue
			_spawn_tile(col, row)


func get_tile(axial: Vector2i) -> Node:
	return _tiles.get(axial, null)


func _spawn_tile(col: int, row: int) -> void:
	var tile: Node = hex_tile_scene.instantiate()

	var axial: Vector2i
	if orientation == HexOrientation.POINTY_TOP:
		axial = HexUtils.evenr_to_axial(col, row)
	else:
		axial = HexUtils.evenq_to_axial(col, row)

	var q: int = axial.x
	var r: int = axial.y
	var offset: Vector3
	if orientation == HexOrientation.POINTY_TOP:
		offset = Vector3(0, 0, hex_size) # circumradius (center-to-vertex)
	else:
		offset = Vector3(0, 0, HexUtils.get_apothem_from_size(hex_size)) # inradius (center-to-edge)
	var world_pos: Vector3 = HexUtils.axial_to_world(q, r, hex_size, orientation, offset)
	tile.position = world_pos

	if orientation == HexOrientation.FLAT_TOP:
		tile.rotation = FLAT_TOP_ROTATION

	tile.axial_coord = axial
	add_child(tile)
	_tiles[axial] = tile
