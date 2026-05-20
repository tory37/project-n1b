extends MarginContainer

## UI component to display AP and Currency for the active player.

@onready var ap_label = $VBoxContainer/APLabel
@onready var currency_label = $VBoxContainer/CurrencyLabel
@onready var player_label = $VBoxContainer/PlayerLabel

func _ready() -> void:
	SignalBus.resources_updated.connect(_on_resources_updated)
	SignalBus.player_switched.connect(_on_player_switched)

	var ap: int = GameManager.player_game_state[GameManager.active_player]["ap"]
	var currency: int = GameManager.player_game_state[GameManager.active_player]["currency"]
	_update_display(GameManager.active_player, ap, currency)

func _on_resources_updated(player_index: int, ap: int, currency: int) -> void:
	if player_index == GameManager.active_player:
		_update_display(player_index, ap, currency)

func _on_player_switched(new_player_index: int) -> void:
	var ap: int = GameManager.player_game_state[new_player_index]["ap"]
	var currency: int = GameManager.player_game_state[new_player_index]["currency"]
	_update_display(new_player_index, ap, currency)

func _update_display(player: int, ap: int, currency: int):
	player_label.text = "Player: " + ("1" if player == 0 else "2")
	ap_label.text = "AP: " + str(ap)
	currency_label.text = "Currency: " + str(currency)
