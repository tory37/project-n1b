extends Node

# Cards
signal card_play_enabled()
signal card_play_disabled()
signal card_play_requested(card_uuid: String)
signal card_play_request_succeeded(card_uuid: String, player_id: int)
signal card_play_request_failed(card_uuid: String, reason: String)
signal card_resolution_started(card_data: CardData)
signal card_resolution_completed(card_data: CardData)