# Deck & Card Logic

## The Loadout
Players enter the game with a pre-built selection:
- **Main Deck:** A collection of `[Value: 40]` cards.
- **Army Box:** A specific set of character entities ready for deployment.

## Card Types
1. **Terrain:** Hexagonal tiles used to build the map.
2. **Overlays:** Things like bridges or roads that sit on top of existing terrain.
3. **Upgrades:** Weapons, armor, or spells applied to characters (could be tokens).
4. **Global Tiles:** Off-board cards that control systems like "Weather" (e.g., Blizzard boosts Ice magic). Each new Global card overrides the previous one.
5. **Traps:** Cards placed face down that activate under specific conditions.

## Deck Composition

- **Main Deck Size:** `[Value: 40]` cards.
- **Copy Limit:** Up to `[Value: 3]` copies of the same card per deck.

## Effect Stack

Following Magic: The Gathering conventions:

- When an effect triggers, it is added to the **Effect Stack**.
- Other effects can "respond" to a triggered effect by adding themselves to the stack.
- Once no player chooses to respond, effects resolve in **LIFO (Last In, First Out) order**.
- Example: Card A triggers an effect. Card B can respond. If Card B's effect triggers Card C, Card C resolves first, then Card B, then Card A.

## Trap Cards

- **Placement:** Traps are placed **face down** on the board, taking up a hex.
- **Activation:** Traps activate when a specific condition is met (e.g., enemy unit moves adjacent, spell cast, turn begins).
- **Resolution:** Upon activation, the trap card is revealed and its effect is added to the Effect Stack.
