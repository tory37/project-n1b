class_name DrawPhase
extends GamePhase

@export var on_completion_phase: GamePhase


func enter(_payload: Variant) -> void:
	if not _game_manager.multiplayer.is_server():
		return

	var active_player_id: int = _game_manager.active_player.value

	var player = _game_manager.get_player(active_player_id)
	var deck: GameCardCollectionComponent = player.deck

	if (deck.value.size() > 0):
		_game_manager.draw_cards(active_player_id, 1)
	else:
		# TODO: Send the game over signal / active player lost
		push_error("Player %d cannot draw a card. Skipping draw phase." % active_player_id)


	_game_manager.transition_to_phase(on_completion_phase)
