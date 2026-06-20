extends GutTest

# Minimal state that tracks enter/exit calls without emitting signals
class TrackedState extends FiniteState:
	var entered: bool = false
	var exited: bool = false

	func _init(fsm: FiniteStateMachineNode) -> void:
		super(fsm)

	func enter() -> void:
		entered = true

	func exit() -> void:
		exited = true


var _fsm: FiniteStateMachineNode


func before_each() -> void:
	_fsm = FiniteStateMachineNode.new()


func after_each() -> void:
	# Break the FSM↔State circular ref so both RefCounted objects are freed
	if _fsm:
		_fsm._current_state = null
	_fsm = null


# --- change_state() ---

func test_change_state_calls_enter_on_new_state() -> void:
	var state := TrackedState.new(_fsm)
	_fsm.change_state(state)
	assert_true(state.entered)

func test_change_state_calls_exit_on_previous_state() -> void:
	var first := TrackedState.new(_fsm)
	var second := TrackedState.new(_fsm)
	_fsm.change_state(first)
	_fsm.change_state(second)
	assert_true(first.exited)

func test_change_state_with_no_prior_state_does_not_crash() -> void:
	var state := TrackedState.new(_fsm)
	_fsm.change_state(state)  # _current_state starts null
	assert_true(state.entered)

func test_change_state_does_not_enter_previous_state_again() -> void:
	var first := TrackedState.new(_fsm)
	var second := TrackedState.new(_fsm)
	_fsm.change_state(first)
	first.entered = false  # reset
	_fsm.change_state(second)
	assert_false(first.entered)

func test_change_state_sets_current_state() -> void:
	var state := TrackedState.new(_fsm)
	_fsm.change_state(state)
	assert_eq(_fsm._current_state, state)
