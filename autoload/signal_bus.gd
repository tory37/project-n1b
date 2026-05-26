extends Node

# Request Signals
signal add_ap_requested(amount: int)

# Synchronization Signals
signal active_player_synced(player_id: int)
signal ap_synced(ap: int)
signal currency_synced(player_id: int, currency: int)
signal player_hand_synced(player_id: int, hand: Array[GameCard])
signal player_deck_synced(player_id: int, deck: Array[GameCard])
signal player_discard_synced(player_id: int, discard: Array[GameCard])
