@tool
class_name ResolvingCardPhase
extends GamePhase

@export var on_complete_phase: FiniteState

var _card: GameCard = null
var _card_fsm: FiniteStateMachine = null


func _on_enter() -> void:
	Loggit.p("Entering ResolvingCardPhase with card", "DrawDebug")
	_card = _context.get_var(&"card_to_resolve") as GameCard

	if not _card:
		push_error("No card to resolve in ResolvingCardPhase.")
		return

	if not _card.data:
		push_error("Card %s has no data defined." % _card.uuid)
		return

	if not _card.data.fsm:
		push_error("Card %s has no FSM defined." % _card.title)
		return

	_card_fsm = _card.data.fsm.instantiate()
	_card_fsm.exited.connect(_on_card_effects_done)
	var card_context := StateContext.new()
	card_context.agent = _card
	_card_fsm.start(card_context)


func _on_card_effects_done() -> void:
	if _card_fsm and _card_fsm.exited.is_connected(_on_card_effects_done):
		_card_fsm.exited.disconnect(_on_card_effects_done)
	_card_fsm = null
	_card = null
	_context.clear_var(&"card_to_resolve")

	# SignalBus.card_finished_resolving.emit(_card)
