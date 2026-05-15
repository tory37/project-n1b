extends GutTest

func test_signal_bus_has_player_switched_signal() -> void:
	assert_has_signal(SignalBus, "player_switched")

func test_signal_bus_has_marker_moved_signal() -> void:
	assert_has_signal(SignalBus, "marker_moved")

func test_signal_bus_has_resources_updated_signal() -> void:
	assert_has_signal(SignalBus, "resources_updated")

func test_player_switched_fires_with_correct_argument() -> void:
	watch_signals(SignalBus)
	SignalBus.player_switched.emit(1)
	assert_signal_emitted_with_parameters(SignalBus, "player_switched", [1])

func test_marker_moved_fires_with_correct_argument() -> void:
	watch_signals(SignalBus)
	SignalBus.marker_moved.emit(5.5)
	assert_signal_emitted_with_parameters(SignalBus, "marker_moved", [5.5])

func test_resources_updated_fires_with_correct_arguments() -> void:
	watch_signals(SignalBus)
	SignalBus.resources_updated.emit(0, 10, 50)
	assert_signal_emitted_with_parameters(SignalBus, "resources_updated", [0, 10, 50])
