# Game State Overview

## GameState

```gdscript
* var turn: int
* current_phase: Phase
* active_player_id: int
* ap: int
* player_id_turn_order: Array[int]
* player_states: Dictionary[int, PlayerState]
```

## Player State

```gdscript
* player_number: int = 0
* currency: int = 0
* hand: GameCardCollection
* deck: GameCardCollection
* discard: GameCardCollection
```
