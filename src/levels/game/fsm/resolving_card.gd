class_name GamePhaseResolvingCard
extends GamePhaseState

var _card: CardData = null
var _accumulated_payload: Dictionary = {}
var _effect_index: int = 0


func enter(card_to_resolve: Variant) -> void:
	Loggit.p("Entering GamePhaseResolvingCard with card", "DrawDebug")
	_card = card_to_resolve as CardData
	_accumulated_payload = {}
	_effect_index = 0

	notify_card_resolution_started.rpc(_card)

	_resolve_next_effect()


func _resolve_next_effect() -> void:
	if not _card:
		push_error("No _card is currently being resolved.")
		return

	if _card.effects.size() == 0:
		push_error("Card %s has no effects to resolve." % _card.title)
		return

	if _card.effects.size() <= _effect_index:
		Loggit.p("Finished resolving card %s. Transitioning back to main phase." % _card.title, "DrawDebug")
		_game_manager.transition_to_phase(GameManager.GamePhase.MAIN)
		return

	var effect: Action = _card.effects[_effect_index]

	effect.completed.connect(_on_completed)
	effect.cancelled.connect(_on_completed)

	effect.execute(_accumulated_payload)


func _on_completed(new_payload: Dictionary = {}) -> void:
	var current_effect: Action = _card.effects[_effect_index]
	current_effect.completed.disconnect(_on_completed)
	current_effect.cancelled.disconnect(_on_completed)

	_effect_index += 1

	_accumulated_payload.merge(new_payload)

	_resolve_next_effect()


func _on_cancelled() -> void:
	var current_effect: Action = _card.effects[_effect_index]
	current_effect.completed.disconnect(_on_completed)
	current_effect.cancelled.disconnect(_on_cancelled)

	# TODO: Reverse the chain?


@rpc("any_peer", "call_remote", "reliable")
func notify_card_resolution_started(card) -> void:
	SignalBus.card_started_resolving.emit(card)
