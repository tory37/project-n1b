extends Node

# Board Interaction
signal tile_clicked(axial: Vector2i)
signal deck_clicked(deck_owner_id: int)

# Request Signals
signal add_ap_requested(amount: int)

# Game State
signal increment_turn_requested()
signal increment_turn_requested_failed()
signal turn_number_synced(turn: int)

signal active_player_synced(player_id: int)

signal spend_action_points_requested(amount: int)
signal spend_action_points_requested_failed()
signal gain_action_points_requested(amount: int)
signal gain_action_points_requested_failed()
signal action_points_synced(ap: int)

signal turn_order_synced(turn_order: Array[int])

signal currency_synced(player_id: int, currency: int)

signal player_hand_synced(player_id: int, hand: GameCardCollection)
signal player_deck_synced(player_id: int, deck: GameCardCollection)
signal player_discard_synced(player_id: int, discard: GameCardCollection)