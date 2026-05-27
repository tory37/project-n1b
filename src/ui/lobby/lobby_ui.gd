extends Control

@export var game_scene: PackedScene


@onready var _host_button: Button = $CenterContainer/VBoxContainer/Buttons/HostButton
@onready var _join_button: Button = $CenterContainer/VBoxContainer/Buttons/JoinButton
@onready var _address_input: LineEdit = $CenterContainer/VBoxContainer/AddressInput
@onready var _player_list: ItemList = $CenterContainer/VBoxContainer/PlayerList
@onready var _start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var _status_label: Label = $CenterContainer/VBoxContainer/StatusLabel


func _ready() -> void:
	_host_button.pressed.connect(_on_host)
	_join_button.pressed.connect(_on_join)
	_start_button.pressed.connect(_on_start)

	NetworkManager.player_connected.connect(_on_player_list_changed)
	NetworkManager.player_disconnected.connect(_on_player_list_changed)
	NetworkManager.connection_established.connect(_on_connected)
	NetworkManager.connection_failed.connect(_on_connection_failed)

	_start_button.visible = false
	_status_label.text = ""


func _on_host() -> void:
	var error := NetworkManager.host_game()
	if error == OK:
		_host_button.disabled = true
		_join_button.disabled = true
		_start_button.visible = true
		_start_button.disabled = true
		_status_label.text = "Hosting — waiting for opponent..."
		_refresh_player_list(0)
	else:
		_status_label.text = "Failed to host: %s" % error_string(error)


func _on_join() -> void:
	var address := _address_input.text.strip_edges()
	if address.is_empty():
		address = "127.0.0.1"
	var error := NetworkManager.join_game(address)
	if error == OK:
		_host_button.disabled = true
		_join_button.disabled = true
		_status_label.text = "Connecting to %s..." % address
	else:
		_status_label.text = "Failed to connect: %s" % error_string(error)


func _on_connected() -> void:
	_status_label.text = "Connected! Waiting for host to start..."
	_refresh_player_list(0)


func _on_connection_failed() -> void:
	_host_button.disabled = false
	_join_button.disabled = false
	_status_label.text = "Connection failed. Try again."


func _on_player_list_changed(_id: int) -> void:
	_refresh_player_list(_id)
	_update_start_button()


func _refresh_player_list(_id: int) -> void:
	_player_list.clear()
	for peer_id in NetworkManager.connected_players:
		var info: PlayerInfo = NetworkManager.connected_players[peer_id]
		_player_list.add_item("%s (ID: %d)" % [info.player_name, info.peer_id])


func _update_start_button() -> void:
	if not NetworkManager.is_server:
		return
	var lobby_full := NetworkManager.connected_players.size() >= NetworkManager.MAX_PLAYERS
	_start_button.disabled = not lobby_full
	if lobby_full:
		_status_label.text = "All players connected — ready to start!"
	else:
		_status_label.text = "Hosting — waiting for opponent..."


func _on_start() -> void:
	if not NetworkManager.is_server:
		return
	_start_game.rpc()


@rpc("authority", "call_local", "reliable")
func _start_game() -> void:
	get_tree().change_scene_to_packed(game_scene)
