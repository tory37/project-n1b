extends MarginContainer

## UI component to display AP and Coins for the active player.

@onready var ap_label = $VBoxContainer/APLabel
@onready var coin_label = $VBoxContainer/CoinLabel
@onready var player_label = $VBoxContainer/PlayerLabel

func _ready() -> void:
	SignalBus.resources_updated.connect(_on_resources_updated)
	SignalBus.player_switched.connect(_on_player_switched)

	var ap: int = GameState.player_resources[GameState.active_player]["ap"]
	var coins: int = GameState.player_resources[GameState.active_player]["coins"]
	_update_display(GameState.active_player, ap, coins)

func _on_resources_updated(player_index: int, ap: int, coins: int) -> void:
	if player_index == GameState.active_player:
		_update_display(player_index, ap, coins)

func _on_player_switched(new_player_index: int) -> void:
	var ap: int = GameState.player_resources[new_player_index]["ap"]
	var coins: int = GameState.player_resources[new_player_index]["coins"]
	_update_display(new_player_index, ap, coins)

func _update_display(player: int, ap: int, coins: int):
	player_label.text = "Player: " + ("1" if player == 0 else "2")
	ap_label.text = "AP: " + str(ap)
	coin_label.text = "Coins: " + str(coins)
