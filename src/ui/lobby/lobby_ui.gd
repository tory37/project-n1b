extends Control

@export var game_scene: PackedScene

@onready var _player_list: ItemList = $CenterContainer/VBoxContainer/PlayerList
@onready var _status_label: Label = $CenterContainer/VBoxContainer/StatusLabel


func _ready() -> void:
	NetworkManager.player_connected.connect(_on_player_list_changed)
	NetworkManager.player_disconnected.connect(_on_player_list_changed)
	NetworkManager.connection_established.connect(_on_connected)
	NetworkManager.connection_failed.connect(_on_connection_failed)

	_status_label.text = ""

	if "--server" in OS.get_cmdline_args():
		auto_host()
	else:
		auto_join()


func auto_host() -> void:
	var error := NetworkManager.host_game()

	if error == OK:
		Loggit.p("Hosting — waiting for opponent...")
	else:
		Loggit.p("Failed to host: %s" % error_string(error))

	
func auto_join() -> void:
	var address: String = "127.0.0.1"
	var error: int = NetworkManager.join_game(address)
	if error == OK:
		Loggit.p("Joining game at %s..." % address, "LobbyUI")
		_status_label.text = "Connecting to %s..." % address
	else:
		Loggit.p("Failed to join game: %s" % error_string(error), "LobbyUI")
		_status_label.text = "Failed to connect: %s" % error_string(error)

	

func _check_auto_start() -> void:
	if NetworkManager.connected_players.size() >= NetworkManager.MAX_PLAYERS:
		Loggit.p("Max players reached, starting game automatically...", "LobbyUI")
		_start_game.rpc()


func _on_connected() -> void:
	_status_label.text = "Connected! Waiting for game to start…"
	_refresh_player_list(0)


func _on_connection_failed() -> void:
	_status_label.text = "Connection failed. Try again."


func _on_player_list_changed(_id: int) -> void:
	if multiplayer.is_server():
		_check_auto_start()

	_refresh_player_list(_id)


func _refresh_player_list(_id: int) -> void:
	_player_list.clear()
	for peer_id in NetworkManager.connected_players:
		var info: PlayerInfo = NetworkManager.connected_players[peer_id]
		_player_list.add_item("%s (ID: %d)" % [info.player_name, info.peer_id])


@rpc("authority", "call_local", "reliable")
func _start_game() -> void:
	get_tree().change_scene_to_packed(game_scene)
