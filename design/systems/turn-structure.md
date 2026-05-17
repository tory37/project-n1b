# Turn Structure & Economy

## Start of Game

1. **Determine Initiative:** The first player is chosen by a coin flip.
2. **Shuffle:** Both players shuffle their **Main Decks**.
3. **Initial State:**
    - First player starts with `[Value: 1]` Action Point (AP).
    - Both players start with `[Value: 0]` Currency.
    - The **Merchant** is populated with `[Value: 3]` random items.

## The Tug-of-War System

Instead of a fixed action count, the turn economy is a dynamic balance managed by **The AP Tracker**.

- **The AP Tracker:** A shared counter starting at 0. Increases when AP is gained, decreases when AP is spent.
- **Turn Switching:**
  - During a player's turn, they spend AP (reducing the tracker) or gain AP from effects (increasing the tracker).
  - When the AP Tracker passes 0 (goes negative) AND all effects have resolved, the turn immediately switches to the opponent.
  - The opponent takes over with whatever AP value remains on the tracker.
  - **Manual End:** A player can end their turn early by choosing to pass.

## Actions

Every action taken on the board or from the hand consumes **Action Points (AP)**.

- **Play Card:** `[Value: X]` AP (Variable by card)
- **Deploy Entity:** `[Value: X]` AP (Variable by entity)
- **Move Entity:** `[Value: 1]` AP per hex.
- **Initiate Combat:** `[Value: 1]` AP.

## Currency & Income

Currency is used to interact with the **Merchant**.

- **Base Income:** Gain `[Value: 2]` currency at the start of each turn.
- **Variable Income:** Potential for `[Value: Round Number]` or card-based modifiers to increase income.
- **Banking:** Currency persists between turns.
