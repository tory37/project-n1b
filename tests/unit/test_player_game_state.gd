extends GutTest

var _state: PlayerGameState


func before_each() -> void:
	_state = PlayerGameState.new()


# --- deck_to_hand() ---

func test_deck_to_hand_moves_card_to_hand() -> void:
	var card := CardData.new()
	_state.deck.append(card)
	_state.deck_to_hand()
	assert_eq(_state.hand.size(), 1)
	assert_eq(_state.hand[0], card)

func test_deck_to_hand_removes_card_from_deck() -> void:
	_state.deck.append(CardData.new())
	_state.deck_to_hand()
	assert_eq(_state.deck.size(), 0)

func test_deck_to_hand_draws_from_back_of_deck() -> void:
	var first := CardData.new()
	var second := CardData.new()
	_state.deck.append(first)
	_state.deck.append(second)
	_state.deck_to_hand()
	assert_eq(_state.hand[0], second)

func test_deck_to_hand_with_empty_deck_does_not_crash() -> void:
	_state.deck_to_hand()
	assert_eq(_state.hand.size(), 0)


# --- use_card_from_hand() ---

func test_use_card_removes_from_hand() -> void:
	var card := CardData.new()
	_state.hand.append(card)
	_state.use_card_from_hand(card)
	assert_eq(_state.hand.size(), 0)

func test_use_card_moves_to_discard() -> void:
	var card := CardData.new()
	_state.hand.append(card)
	_state.use_card_from_hand(card)
	assert_eq(_state.discard.size(), 1)
	assert_eq(_state.discard[0], card)

func test_use_card_not_in_hand_does_not_crash() -> void:
	_state.use_card_from_hand(CardData.new())
	assert_eq(_state.discard.size(), 0)

func test_use_card_does_not_affect_other_cards_in_hand() -> void:
	var keep := CardData.new()
	var use := CardData.new()
	_state.hand.append(keep)
	_state.hand.append(use)
	_state.use_card_from_hand(use)
	assert_eq(_state.hand.size(), 1)
	assert_eq(_state.hand[0], keep)
