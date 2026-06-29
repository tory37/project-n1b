class_name GameManager
extends Node

## Exports
@export var fsm: FiniteStateMachine

# TODO: Make these a resource
@export var starting_action_points: int = 0
@export var starting_spirit_points: int = 0
@export var pass_turn_starting_ap: int = 3

# TODO: Remove - Test data
@export var test_deck: DeckData

## Public Variables 
var _run_fsm: FiniteStateMachine = null


## @onready Variables 
@onready var player_registry: PlayerRegistry = $PlayerRegistry

# Players
@onready var player_1: NetworkedPlayer = $PlayerRegistry/Player1
@onready var player_2: NetworkedPlayer = $PlayerRegistry/Player2

# Sub Managers
@onready var card_manager: CardManager = $SubManagers/CardManager
@onready var notification_manager: NotificationManager = $SubManagers/NotificationManager

# State Components
@onready var round_number: RoundNumberComponent = $State/RoundNumberComponent
@onready var active_player: ActivePlayerComponent = $State/ActivePlayerComponent
@onready var turn_order: TurnOrderComponent = $State/TurnOrderComponent
@onready var action_points: ActionPointsComponent = $State/ActionPointsComponent

## ---- Lifecycle -----------------------------------------------------
func _ready() -> void:
	if not multiplayer.is_server():
		return

	card_manager.setup(self)
	notification_manager.setup(self)

	# transition_to_phase(entry_phase)
	_run_fsm = fsm.instantiate()
	var context := StateContext.new()
	context.agent = self
	_run_fsm.start(context)

## ---- Public Methods ------------------------------------------------
func get_player(peer_id: int) -> NetworkedPlayer:
	return player_registry.get_player(peer_id)








