extends Node

# Signals are declared here for external emission and subscription — unused-signal is expected.
@warning_ignore("unused_signal")
signal player_switched(new_player_index: int)
@warning_ignore("unused_signal")
signal marker_moved(new_value: float)
@warning_ignore("unused_signal")
signal resources_updated(player_index: int, ap: int, currency: int)
