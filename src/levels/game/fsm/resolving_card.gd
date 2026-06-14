class_name GamePhaseResolvingCard
extends GamePhaseState

var card_being_resolved: CardData = null
var current_effect_chain: Array[Effect] = []
var current_effect_chain_index: int = 0

func enter(card_to_resolve: Variant) -> void:
	card_being_resolved = card_to_resolve
	_on_server_enter()
	_on_client_enter()


func exit() -> void:
	_on_server_exit()
	_on_client_exit()


func _on_server_enter() -> void:
	if not multiplayer.is_server():
		return


func _on_client_enter() -> void:
	if multiplayer.is_server():
		return

	Loggit.p("Entering Resolving Card phase for card: %s" % card_being_resolved.title, "PlayDebug")
	SignalBus.card_started_resolving.emit(card_being_resolved)
		

func _on_server_exit() -> void:
	if not multiplayer.is_server():
		return


func _on_client_exit() -> void:
	if multiplayer.is_server():
		return
