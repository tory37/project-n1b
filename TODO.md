# TODO

## Next up (in priority order)

### 1. Finish the FSM editor — inspector integration  ⬅️ IMPLEMENTED, NEEDS IN-EDITOR TEST
Reworked from the hardcoded standalone scene into a real `addons/fsm_editor/`
plugin: an inspector button bound to the inspected FSM + a bottom-panel view.

- [x] Add an `EditorPlugin` + `EditorInspectorPlugin` so a **"Edit Graph"**
      button appears when inspecting a resource that holds a
      `FiniteStateMachineResource` (e.g. `CardData.fsm`), or the machine itself.
- [x] Clicking it opens the graph editor **bound to the FSM being inspected**
      (`open_fsm(fsm, host)`) — not the hardcoded test `.tres`.
- [x] A null export gets a **new embedded instance**; Save writes the **host**
      resource so each card's graph persists inline (no shared test file).
- [x] Host the editor in a **bottom panel** (`add_control_to_bottom_panel`),
      instead of a standalone scene you run with F6.
- [ ] (nice-to-have) Expand inline value editors beyond bool/int/float/String
      as real action atoms need more types.

> **Test in-editor:** enable the plugin (auto-enabled in `project.godot`),
> inspect a `CardData`, click **Edit Graph** under `fsm` → the **FSM** bottom
> panel opens. Add a starting state, wire successors, **Save FSM**, reopen to
> confirm the graph round-trips.

### 2. Migrate the game manager to use the new FSM as an export
- [ ] Replace the game manager's current phase/flow wiring with an exported
      `FiniteStateMachineResource`.
- [ ] Drive it via `instantiate()` → `start()` → `state_change_requested`,
      same pattern as `resolving_card_phase.gd`.

### 3. Author the actual game-flow machine in the editor
- [ ] Once #1 is done, build the real game-state machine in the editor instead
      of by hand.

---

## Current state (done)

- **FSM data model**
  - `FiniteStateResource` — base; introspection (`get_successor_properties` /
    `get_data_properties`) splits exports into edges vs. inline fields;
    `clone_graph()` = cycle/diamond-safe deep copy (identity map).
  - `FiniteStateMachineResource` — now a `Resource` (saveable/exportable); holds
    `entry_state`; self-running (`start` / `change_state` follow
    `state_change_requested`); `instantiate()` returns an isolated runtime copy.
- **FSM editor** — `src/editor/fsm/fsm_editor.tscn` (`@tool`): build graph, add
  states via class picker, wire pins (diamonds + cycles supported), Save/Load.
  Position-before-`add_child` fix landed (was nulling `connections_layer`).
- **Card path** — `CardData.fsm` export; `resolving_card_phase.gd` clones via
  `instantiate()`, starts the FSM, and RPCs `unique_id` (not the resource).
- **Bugs fixed** — actions now override `enter()` (not `execute`/`_enter`), so
  the chain actually runs; RPC sends `unique_id` to dodge the CardData-over-wire
  "Object to Object" error.

## Known limitations / cleanups

- [ ] Delete throwaway demo states (`sequence_state.gd`, `branch_state.gd`) once
      real action atoms exist.
- [ ] Verify a **cyclic** FSM survives Save → Load round-trip (`.tres`
      `SubResource` ids should handle it, but confirm).
- [ ] Card resolution has **no completion path** yet — `_on_card_effects_done`
      isn't wired and `on_complete_phase` is never reached (intentionally; this
      is where impl currently stops). Decide terminal convention (null-next =
      done) and wire it.
- [ ] `notification_fired` is emitted **server-side**; RPC to clients if the UI
      needs it there.
