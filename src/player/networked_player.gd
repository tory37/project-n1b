class_name NetworkedPlayer
extends Node

@onready var _peer_id: int = multiplayer.get_unique_id()
@onready var _seat: SeatComponent = $SeatComponent
@onready var _spirit_points: SpiritPointsComponent = $SpiritPointsComponent
@onready var _hand: GameCardCollectionComponent = $HandComponent
@onready var _deck: GameCardCollectionComponent = $DeckComponent
@onready var _discard: GameCardCollectionComponent = $DiscardComponent

var peer_id: int:
	get:
		return _peer_id

var seat: SeatComponent:
	get:
		return _seat

var spirit_points: SpiritPointsComponent:
	get:
		return _spirit_points

var hand: GameCardCollectionComponent:
	get:
		return _hand

var deck: GameCardCollectionComponent:
	get:
		return _deck

var discard: GameCardCollectionComponent:
	get:
		return _discard


func set_peer_id(new_peer_id: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can set peer_id directly")
		return

	_peer_id = new_peer_id

