# Scene Setup Guide: lobby_ui.tscn

**Script:** `src/ui/lobby/lobby_ui.gd`
**Save scene to:** `src/ui/lobby/lobby_ui.tscn`

---

## Node Hierarchy

Build this tree in the Godot Editor (Scene panel > right-click to add children):

```
LobbyUI                (Control)
  └─ CenterContainer   (CenterContainer)
      └─ VBoxContainer (VBoxContainer)
          ├─ Title          (Label)
          ├─ HSeparator     (HSeparator)
          ├─ AddressInput   (LineEdit)
          ├─ Buttons        (HBoxContainer)
          │   ├─ HostButton (Button)
          │   └─ JoinButton (Button)
          ├─ PlayerList     (ItemList)
          ├─ StatusLabel    (Label)
          └─ StartButton    (Button)
```

---

## Step-by-Step

### 1. Root Node — LobbyUI
- Add a **Control** node, rename it `LobbyUI`.
- In the Inspector, set **Layout > Anchors Preset** to **Full Rect** (the icon that fills the parent).
- Attach `src/ui/lobby/lobby_ui.gd` as its script (Inspector > Script > drag or browse).

### 2. CenterContainer
- Add a **CenterContainer** child of `LobbyUI`, rename it `CenterContainer`.
- Set **Layout > Anchors Preset** to **Full Rect**.

### 3. VBoxContainer
- Add a **VBoxContainer** child of `CenterContainer`, rename it `VBoxContainer`.
- Inspector > **Theme Overrides > Constants > Separation**: `12`.

### 4. Title Label
- Add a **Label** child of `VBoxContainer`, rename it `Title`.
- Inspector > **Text**: `Project N1B`.
- Inspector > **Horizontal Alignment**: `Center`.

### 5. HSeparator
- Add an **HSeparator** child of `VBoxContainer`. No rename needed.

### 6. AddressInput
- Add a **LineEdit** child of `VBoxContainer`, rename it `AddressInput`.
- Inspector > **Placeholder Text**: `Host IP (leave blank for localhost)`.
- Inspector > **Custom Minimum Size**: `x = 300`.

### 7. Buttons HBoxContainer
- Add an **HBoxContainer** child of `VBoxContainer`, rename it `Buttons`.
- Inspector > **Theme Overrides > Constants > Separation**: `8`.
- Add a **Button** child, rename it `HostButton`, **Text**: `Host Game`.
- Add a **Button** child, rename it `JoinButton`, **Text**: `Join Game`.
- On both buttons, Inspector > **Size Flags > Horizontal**: enable **Expand**.

### 8. PlayerList
- Add an **ItemList** child of `VBoxContainer`, rename it `PlayerList`.
- Inspector > **Custom Minimum Size**: `x = 300, y = 120`.

### 9. StatusLabel
- Add a **Label** child of `VBoxContainer`, rename it `StatusLabel`.
- Inspector > **Text**: *(leave empty)*.
- Inspector > **Horizontal Alignment**: `Center`.

### 10. StartButton
- Add a **Button** child of `VBoxContainer`, rename it `StartButton`.
- Inspector > **Text**: `Start Game`.
- Inspector > **Disabled**: ✅ checked (starts disabled; script enables it when lobby is full).

---

## No Signal Connections Needed in Editor

All signal connections are made in code (`lobby_ui.gd`). You do not need to wire anything in the Node panel.

---

## Verify the @onready Paths

The script uses these exact node names. Double-check each node is named correctly:

| @onready var       | Expected node name  |
|--------------------|---------------------|
| `host_button`      | `HostButton`        |
| `join_button`      | `JoinButton`        |
| `address_input`    | `AddressInput`      |
| `player_list`      | `PlayerList`        |
| `start_button`     | `StartButton`       |
| `status_label`     | `StatusLabel`       |
