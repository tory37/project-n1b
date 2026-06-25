class_name FiniteStateMachineResource
extends Resource

@export var entry_state: FiniteStateResource

var _current_state: FiniteStateResource = null


## Returns an isolated, ready-to-run copy of this machine: a fresh FSM whose
## entire state graph is deep-cloned (see FiniteStateResource.clone_graph).
##
## Run the COPY, never the shared definition — start()/change_state() mutate
## _current_state and connect signals, so concurrent executions (an MTG-style
## stack of cards in flight) must each own their own instance.
func instantiate() -> FiniteStateMachineResource:
	var copy: FiniteStateMachineResource = duplicate(false)
	if entry_state != null:
		copy.entry_state = entry_state.clone_graph()
	return copy


func start(payload: Variant = null) -> void:
	if entry_state:
		change_state(entry_state, payload)
	else:
		push_error("No entry state defined for FiniteStateMachineResource.")


func change_state(next: FiniteStateResource, payload: Variant = null) -> void:
	if _current_state:
		_current_state.exit()
		_current_state.state_change_requested.disconnect(change_state)

	_current_state = next
	_current_state.state_change_requested.connect(change_state)
	_current_state.enter(payload)


func tick(delta: float) -> void:
	if _current_state:
		_current_state.tick(delta)
