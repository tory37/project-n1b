class_name CardData
extends Resource

@export var unique_id: String = ""
@export var title: String = "Default Card Title"
@export var ap_cost: int = 1
@export var card_type: CardType = CardType.ONE_SHOT
@export var fsm: FiniteStateMachineResource

enum CardType {
	LAND,
	EQUIPMENT,
	ONE_SHOT,
	BUILDING
}
