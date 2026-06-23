class_name InitPhase
extends GamePhase

@export var on_complete_phase: GamePhase


func enter(_payload: Variant) -> void:
	if not multiplayer.is_server():
		return

	_initialize_game_state()
	_initialize_players()
	_game_manager.transition_to_phase.call_deferred(on_complete_phase)


func _initialize_game_state() -> void:
	if not multiplayer.is_server():
		return

	for peer_id: int in multiplayer.get_peers():
		_game_manager.turn_order.push_value(peer_id)


func _initialize_players() -> void:
	if not multiplayer.is_server():
		return

	var seat = 1
	for peer_id: int in multiplayer.get_peers():
		var player: NetworkedPlayer

		if seat == 1:
			player = _game_manager.player_1
		elif seat == 2:
			player = _game_manager.player_2
		else:
			push_error("Unsupported seat number %d for peer_id %d" % [seat, peer_id])
			continue

		_game_manager.player_registry.add_player(peer_id, player)

		player.set_peer_id(peer_id)
		player.seat.set_value(seat)
		player.spirit_points.set_value(_game_manager.starting_spirit_points)
		player.hand.setup(peer_id, GameCardCollection.new())
		player.deck.setup(
			peer_id,
			GameCardCollection.from_card_data_array(
				_game_manager.test_deck.cards.duplicate(),
			),
		)
		player.discard.setup(peer_id, GameCardCollection.new())

		seat += 1
