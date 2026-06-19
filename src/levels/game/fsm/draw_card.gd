class_name GamePhaseDrawCard
extends GamePhaseState

@export var next_phase: GameManager.GamePhase


func enter(_payload: Variant) -> void:
	if not multiplayer.is_server():
		return

	var active_player_id: int = _game_manager.active_player.value

	var player = _game_manager.get_player(active_player_id)
	var deck: GameCardCollectionComponent = player.deck

	if (deck.value.size() > 0):
		_game_manager.draw_cards(active_player_id, 1)
	else:
		# TODO: Send the game over signal / active player lost
		push_error("Player %d cannot draw a card. Skipping draw phase." % active_player_id)


	_game_manager.transition_to_phase(next_phase)
