extends Node

@export var card_ui_scene: PackedScene
@export var card_draw_animation_speed: float = 1.0

@onready var _card_container: Node = %CardContainer
@onready var _play_card_button: Button = %PlayCardButton

var _player_registry: PlayerRegistry
var _selected_card: GameCardUI = null

var _can_play_card: bool = false


func _ready() -> void:
	if multiplayer.is_server():
		return

	ClientSignalBus.card_play_enabled.connect(_on_play_card_enabled)
	ClientSignalBus.card_play_disabled.connect(_on_play_card_disabled)

	_play_card_button.pressed.connect(_on_play_card_button_pressed)
	_play_card_button.hide()

	_player_registry = get_tree().get_first_node_in_group(
		"player_registry",
	) as PlayerRegistry

	_player_registry.player_added.connect(_on_player_added)

	_play_card_button.hide()


func _exit_tree() -> void:
	if multiplayer.is_server():
		return

	if ClientSignalBus.card_play_enabled.is_connected(_on_play_card_enabled):
		ClientSignalBus.card_play_enabled.disconnect(_on_play_card_enabled)
	if ClientSignalBus.card_play_disabled.is_connected(_on_play_card_disabled):
		ClientSignalBus.card_play_disabled.disconnect(_on_play_card_disabled)

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
		if not card.data:
			Loggit.p("Card data not found for card with UUID: " + card.uuid, "HandDebug")
		else:
			Loggit.p("Adding card to hand overlay: " + card.data.title, "HandDebug")
		var card_ui_instance = card_ui_scene.instantiate() as GameCardUI
		_card_container.add_child(card_ui_instance)
		card_ui_instance.card = card
		card_ui_instance.setup()
		card_ui_instance.hide_selected()
		card_ui_instance.clicked.connect(_on_card_ui_clicked)
		await get_tree().create_timer(card_draw_animation_speed).timeout


func _on_cards_removed(uuids: Array[String]) -> void:
	for child in _card_container.get_children():
		var card_ui = child as GameCardUI
		if card_ui.card and card_ui.card.uuid in uuids:
			child.queue_free()

func _on_card_ui_clicked(card_ui: GameCardUI) -> void:
	if _selected_card == card_ui:
		_selected_card.hide_selected()
		_selected_card = null
		_play_card_button.hide()
		return

	_selected_card = card_ui
	
	for child in _card_container.get_children():
		var other_card_ui = child as GameCardUI
		if other_card_ui != card_ui:
			other_card_ui.hide_selected()

	_selected_card.show_selected()

	if (_can_play_card):
		_play_card_button.show()


func _on_play_card_button_pressed() -> void:
	Loggit.p("Play card button pressed for card: " + _selected_card.card.data.title, "PlayDebug")
	if _selected_card and _selected_card.card:
		ClientSignalBus.card_play_requested.emit(_selected_card.card.uuid)


func _on_play_card_enabled() -> void:
	_can_play_card = true

func _on_play_card_disabled() -> void:
	_can_play_card = false
	_play_card_button.hide()
