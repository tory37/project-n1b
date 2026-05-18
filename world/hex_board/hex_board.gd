extends Node3D

class_name HexBoard

@export var hex_size: float = 1.0
@export var board_radius: int = 3
@export var orientation: HexUtils.HexOrientation = HexUtils.HexOrientation.POINTY_TOP
@export var hex_tile_scene: PackedScene

var _tiles: Dictionary = { }


func _ready() -> void:
	if hex_tile_scene == null:
		push_error("HexBoard: hex_tile_scene not assigned")
		return
	generate()


func generate() -> void:
	_tiles.clear()
	for q in range(-board_radius, board_radius + 1):
		for r in range(
			max(-board_radius, -q - board_radius), 
			min(board_radius, -q + board_radius) + 1
		):
			_spawn_tile(q, r)


func get_tile(axial: Vector2i) -> Node:
	return _tiles.get(axial, null)


func _spawn_tile(q: int, r: int) -> void:
	var tile: Node = hex_tile_scene.instantiate()
	var world_pos: Vector3 = HexUtils.axial_to_world(q, r, hex_size, orientation)
	tile.position = world_pos
	tile.axial_coord = Vector2i(q, r)
	add_child(tile)
	_tiles[Vector2i(q, r)] = tile
