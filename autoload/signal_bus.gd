extends Node

# Game State
signal game_start_requested()
signal game_state_initialized(
		active_player: int,
		ap_tracker: int,
)
signal player_game_state_initialized(player_game_state: PlayerGameState)

# Player
signal player_switched(new_player_index: int)

# Turn
signal switch_turn_requested()
signal pass_turn_requested()

# Action Points
signal add_ap_requested(amount: int)
signal spend_ap_requested(player_index: int, amount: int)
signal ap_tracker_moved(new_value: float)

# Currency
signal add_currency_requested(player_index: int, amount: int)
signal player_currency_updated(player_index: int, currency: int)

# Board Interaction
signal tile_clicked(axial: Vector2i)

# Cards
signal deck_clicked(owner_player_id: int)
signal draw_card_requested()
signal card_draw_animation_complete()

# Errors
signal ap_spend_failed(player_index: int)

# Debug
signal print_players_hands_requested()
