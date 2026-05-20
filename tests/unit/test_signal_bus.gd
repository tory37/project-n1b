extends GutTest

func test_signal_bus_has_player_switched_signal() -> void:
	assert_has_signal(SignalBus, "player_switched")

func test_signal_bus_has_ap_tracker_moved_signal() -> void:
	assert_has_signal(SignalBus, "ap_tracker_moved")

func test_player_switched_fires_with_correct_argument() -> void:
	watch_signals(SignalBus)
	SignalBus.player_switched.emit(1)
	assert_signal_emitted_with_parameters(SignalBus, "player_switched", [1])

func test_ap_tracker_moved_fires_with_correct_argument() -> void:
	watch_signals(SignalBus)
	SignalBus.ap_tracker_moved.emit(5.5)
	assert_signal_emitted_with_parameters(SignalBus, "ap_tracker_moved", [5.5])