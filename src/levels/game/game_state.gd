class_name GameState
extends RefCounted

enum Phase { START, DRAW_CARD, MAIN }

var turn: int = 0
var current_phase: Phase = Phase.START
var active_player_id: int = 0
var ap: int = 0
var player_id_turn_order: Array[int] = []
var player_states: Dictionary[int, PlayerState] = {}

func print_debug_state() -> void:
	Loggit.p("GameState Debug Info:", "Debug")
	Loggit.p("  Turn: %d" % turn, "Debug")
	Loggit.p("  Active Player: %d" % active_player_id, "Debug")
	Loggit.p("  AP Tracker: %d" % ap, "Debug")
	Loggit.p("  Current Phase: %s" % str(current_phase), "Debug")
	Loggit.p("  Player States:", "Debug")
	for player_id: int in player_states.keys():
		var player_state: PlayerState = player_states[player_id]
		Loggit.p("  Player %d State:" % player_id, "Debug")
		Loggit.p("    Currency: %d" % player_state.currency, "Debug")
		for card: GameCard in player_state.hand.cards:
			if card is GameCard:
				Loggit.p("      Hand Card: %s" % card.data.title, "Debug")
			else:
				Loggit.p("      Hand Card: Hidden", "Debug") 
		for card: GameCard in player_state.deck.cards:
			if card is GameCard:
				Loggit.p("      Deck Card: %s" % card.data.title, "Debug")
			else:
				Loggit.p("      Deck Card: Hidden", "Debug")
		for card: GameCard in player_state.discard.cards:
			if card is GameCard:
				Loggit.p("      Discard Card: %s" % card.data.title, "Debug")
			else:
				Loggit.p("      Discard Card: Hidden", "Debug") 
