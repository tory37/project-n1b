@tool
class_name MainPhase
extends GamePhase

@export var on_card_played_phase: FiniteState


func _on_enter() -> void:
	if not _game_manager.multiplayer.is_server():
		return

	ServerSignalBus.card_play_validated.connect(_on_card_play_validated)

	var current_player_id: int = _game_manager.active_player.value
	ServerSignalBus.card_play_enabled.emit(current_player_id)


func _on_exit() -> void:
	if not _game_manager.multiplayer.is_server():
		return

	var current_player_id: int = _game_manager.active_player.value
	ServerSignalBus.card_play_disabled.emit(current_player_id)


func _on_card_play_validated(card: GameCard) -> void:
	if not _game_manager.multiplayer.is_server():
		return

	ServerSignalBus.card_play_validated.disconnect(_on_card_play_validated)
	_context.set_var(&"card_to_resolve", card)
	state_change_requested.emit(on_card_played_phase)
