extends GutTest


func before_each() -> void:
	LocalSession.local_player_id = PlayerSeat.PLAYER_ONE


func test_default_local_player_is_player_one() -> void:
	assert_eq(LocalSession.local_player_id, PlayerSeat.PLAYER_ONE)

func test_request_set_local_player_updates_to_player_two() -> void:
	LocalSession.request_set_local_player(PlayerSeat.PLAYER_TWO)
	assert_eq(LocalSession.local_player_id, PlayerSeat.PLAYER_TWO)

func test_request_set_local_player_can_set_back_to_player_one() -> void:
	LocalSession.local_player_id = PlayerSeat.PLAYER_TWO
	LocalSession.request_set_local_player(PlayerSeat.PLAYER_ONE)
	assert_eq(LocalSession.local_player_id, PlayerSeat.PLAYER_ONE)
