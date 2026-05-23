extends Control

@onready var host_button: Button = $CenterContainer/VBoxContainer/Buttons/HostButton
@onready var join_button: Button = $CenterContainer/VBoxContainer/Buttons/JoinButton
@onready var address_input: LineEdit = $CenterContainer/VBoxContainer/AddressInput
@onready var player_list: ItemList = $CenterContainer/VBoxContainer/PlayerList
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel


func _ready() -> void:
	host_button.pressed.connect(_on_host)
	join_button.pressed.connect(_on_join)
	start_button.pressed.connect(_on_start)

	NetworkManager.player_connected.connect(_on_player_list_changed)
	NetworkManager.player_disconnected.connect(_on_player_list_changed)
	NetworkManager.connection_established.connect(_on_connected)
	NetworkManager.connection_failed.connect(_on_connection_failed)

	start_button.visible = false
	status_label.text = ""


func _on_host() -> void:
	var error := NetworkManager.host_game()
	if error == OK:
		host_button.disabled = true
		join_button.disabled = true
		start_button.visible = true
		start_button.disabled = true
		status_label.text = "Hosting — waiting for opponent..."
		_refresh_player_list(0)
	else:
		status_label.text = "Failed to host: %s" % error_string(error)


func _on_join() -> void:
	var address := address_input.text.strip_edges()
	if address.is_empty():
		address = "127.0.0.1"
	var error := NetworkManager.join_game(address)
	if error == OK:
		host_button.disabled = true
		join_button.disabled = true
		status_label.text = "Connecting to %s..." % address
	else:
		status_label.text = "Failed to connect: %s" % error_string(error)


func _on_connected() -> void:
	status_label.text = "Connected! Waiting for host to start..."
	_refresh_player_list(0)


func _on_connection_failed() -> void:
	host_button.disabled = false
	join_button.disabled = false
	status_label.text = "Connection failed. Try again."


func _on_player_list_changed(_id: int) -> void:
	_refresh_player_list(_id)
	_update_start_button()


func _refresh_player_list(_id: int) -> void:
	player_list.clear()
	for peer_id in NetworkManager.connected_players:
		var info: PlayerInfo = NetworkManager.connected_players[peer_id]
		player_list.add_item("%s (ID: %d)" % [info.player_name, info.peer_id])


func _update_start_button() -> void:
	if not NetworkManager.is_server:
		return
	var lobby_full := NetworkManager.connected_players.size() >= NetworkManager.MAX_PLAYERS
	start_button.disabled = not lobby_full
	if lobby_full:
		status_label.text = "All players connected — ready to start!"
	else:
		status_label.text = "Hosting — waiting for opponent..."


func _on_start() -> void:
	if not NetworkManager.is_server:
		return
	_start_game.rpc()


@rpc("authority", "call_local", "reliable")
func _start_game() -> void:
	get_tree().change_scene_to_file("res://src/levels/game/game.tscn")
