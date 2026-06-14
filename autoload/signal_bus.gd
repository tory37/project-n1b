extends Node

# Notications
signal notification_fired(message: String)

# Game State
signal round_number_synced(new_value: int)

# Tiles
signal tile_clicked(axial: Vector2i)

# Deck
signal deck_clicked(deck_owner_id: int)

# Request Signals
signal add_ap_requested(amount: int)

# Game State
signal active_player_synced(player_id: int)

signal spend_action_points_requested(amount: int)
signal spend_action_points_requested_failed()
signal gain_action_points_requested(amount: int)
signal gain_action_points_requested_failed()
signal action_points_synced(ap: int)

signal turn_order_synced(turn_order: Array[int])


# Cards
signal card_started_resolving(card_data: CardData)
signal card_finished_resolving(card_data: CardData)
signal play_card_requested(card_uuid: String)
signal card_played(card_uuid: String, player_id: int)
signal card_play_failed(card_uuid: String, reason: String)

