@tool
class_name FiniteStateMachine
extends Resource

signal exited()

@export var entry_state: FiniteState

var _current_state: FiniteState = null


## Returns an isolated, ready-to-run copy of this machine: a fresh FSM whose
## entire state graph is deep-cloned (see FiniteState.clone_graph).
##
## Run the COPY, never the shared definition — start()/change_state() mutate
## _current_state and connect signals, so concurrent executions (an MTG-style
## stack of cards in flight) must each own their own instance.
func instantiate() -> FiniteStateMachine:
	var copy: FiniteStateMachine = duplicate(false)
	if entry_state != null:
		copy.entry_state = entry_state.clone_graph()
	return copy


func start(payload: Variant = null) -> void:
	if entry_state:
		change_state(entry_state, payload)
	else:
		push_error("No entry state defined for FiniteStateMachine.")


func change_state(next: FiniteState, payload: Variant = null) -> void:
	if _current_state:
		_current_state.exit()
		_current_state.state_change_requested.disconnect(change_state)

	if not next:
		exited.emit()
		return

	_current_state = next
	_current_state.state_change_requested.connect(change_state)
	_current_state.enter(payload)


func tick(delta: float) -> void:
	if _current_state:
		_current_state.tick(delta)
