extends Node

@export var card_ui_scene: PackedScene
@export var card_draw_animation_speed: float = 1.0

@onready var _card_container: Node = %CardContainer

var _player_registry: PlayerRegistry


func _ready() -> void:
	if multiplayer.is_server():
		return

	_player_registry = get_tree().get_first_node_in_group(
		"player_registry",
	) as PlayerRegistry

	_player_registry.player_added.connect(_on_player_added)


func _exit_tree() -> void:
	if multiplayer.is_server():
		return

	if _player_registry:
		_player_registry.player_added.disconnect(_on_player_added)
		_disconnect_all()


func _on_player_added(peer_id: int, player: NetworkedPlayer) -> void:
	if peer_id == multiplayer.get_unique_id():
		player.hand.set_synced.connect(_on_hand_synced)
		player.hand.cards_added_synced.connect(_on_cards_added)
		player.hand.cards_removed_synced.connect(_on_cards_removed)


func _disconnect_all() -> void:
	for player in _player_registry.get_all_players():
		if player.peer_id == multiplayer.get_unique_id():
			player.hand.set_synced.disconnect(_on_hand_synced)


func _on_hand_synced(hand: GameCardCollection) -> void:
	for child in _card_container.get_children():
		child.queue_free()

	_on_cards_added(hand)


func _on_cards_added(added_cards: GameCardCollection) -> void:
	for card: GameCard in added_cards.cards:
		var card_ui_instance = card_ui_scene.instantiate() as GameCardUI
		_card_container.add_child(card_ui_instance)
		card_ui_instance.card = card
		card_ui_instance.setup()
		await get_tree().create_timer(card_draw_animation_speed).timeout


func _on_cards_removed(uuids: Array[String]) -> void:
	for child in _card_container.get_children():
		var card_ui = child as GameCardUI
		if card_ui.card and card_ui.card.uuid in uuids:
			child.queue_free()
