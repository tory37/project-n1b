extends Node

# Cards
signal card_play_enabled(peer_id: int)
signal card_play_disabled(peer_id: int)
signal card_play_validated(card: GameCard)

signal card_draw_requested(player_id: int, count: int)