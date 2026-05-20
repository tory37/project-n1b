extends MarginContainer
## UI component to display AP and Currency for the active player.

@onready var ap_label = $VBoxContainer/APLabel
@onready var currency_label = $VBoxContainer/CurrencyLabel
@onready var player_label = $VBoxContainer/PlayerLabel


func _ready() -> void:
	SignalBus.game_state_initialized.connect(_on_game_state_initialized)
	SignalBus.player_game_state_initialized.connect(_on_player_game_state_initialized)
	SignalBus.player_switched.connect(_on_update_player_label)


func _on_game_state_initialized(active_player: int, ap_tracker: int) -> void:
	_on_update_player_label(active_player)
	_on_update_ap_label(ap_tracker)


func _on_player_game_state_initialized(player_game_state: PlayerGameState) -> void:
	_on_update_currency_label(player_game_state.currency)


func _on_update_player_label(player: int):
	player_label.text = "Player: " + ("1" if player == 0 else "2")


func _on_update_ap_label(ap: int):
	ap_label.text = "AP: " + str(ap)


func _on_update_currency_label(currency: int):
	currency_label.text = "Currency: " + str(currency)
