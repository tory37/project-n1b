class_name FiniteStateMachine

var current_state: FiniteState = null


func change_state(next: FiniteState) -> void:
	if current_state:
		current_state.exit()

	current_state = next
	current_state.enter()
