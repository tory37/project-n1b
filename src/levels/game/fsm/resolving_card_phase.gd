class_name ResolvingCardPhase
extends GamePhase

@export var on_complete_phase: GamePhase

var _card: CardData = null
var _fsm: FiniteStateMachineResource = null


func enter(card_to_resolve: Variant) -> void:
	Loggit.p("Entering ResolvingCardPhase with card", "DrawDebug")
	_card = card_to_resolve as CardData

	notify_card_resolution_started.rpc(_card.unique_id)

	if not _card.fsm:
		push_error("Card %s has no FSM defined." % _card.title)
		return

	_fsm = _card.fsm.instantiate()
	_fsm.start()

func _on_card_effects_done() -> void:
	Loggit.p("All effects for card %s have been executed." % _card.title, "DrawDebug")
	# SignalBus.card_finished_resolving.emit(_card)
	

@rpc("any_peer", "call_remote", "reliable")
func notify_card_resolution_started(card_unique_id: String) -> void:
	var card_data := CardRegistry.get_card(card_unique_id)
	# SignalBus.card_started_resolving.emit(card_data)
