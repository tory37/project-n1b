# GDScript File Layout & Organization Conventions

**Date:** 2026-05-19
**Domain:** GDScript 2.0 / Godot 4 Code Organization
**Question:** How should a GDScript file be laid out? Are public/private methods interleaved or in separate blocks?

---

## I. The Definitive Ordering (Official + Community Consensus)

The [Godot 4.4 Official Style Guide](https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_styleguide.html) and [GDQuest Guidelines](https://gdquest.gitbook.io/gdquests-guidelines/godot-gdscript-guidelines) both converge on the same structure. The ordering exists to let a reader understand a class from top to bottom: what it is → what it exposes → how it's built → how it behaves.

```
# 1. Tool/Icon annotations (only if needed)
@tool

# 2. Class declaration (class_name and extends on separate or same line)
class_name PlayerController
extends CharacterBody2D

# 3. Doc comment (## syntax)
## Handles player movement, input, and animation state.

# 4. Signals
signal health_changed(new_health: int)
signal died

# 5. Enums
enum State { IDLE, RUNNING, JUMPING, DEAD }

# 6. Constants
const MAX_SPEED: float = 400.0
const JUMP_FORCE: float = -600.0

# 7. Static variables (rare — only when shared across all instances)
static var _instance_count: int = 0

# 8. @export variables (Inspector-visible)
@export var move_speed: float = 200.0
@export var jump_height: float = 300.0
@export_group("Health")
@export var max_health: int = 100

# 9. Public variables
var current_state: State = State.IDLE
var velocity_override: Vector2 = Vector2.ZERO

# 10. Private variables (underscore prefix)
var _health: int = 100
var _is_grounded: bool = false
var _input_direction: float = 0.0

# 11. @onready variables (node references — set at runtime, so grouped last)
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _sprite: Sprite2D = $Sprite2D

# ---------- METHODS ----------

# 12. Static init (rare)
static func _static_init() -> void:
    pass

# 13. Other static methods
static func create() -> PlayerController:
    return PlayerController.new()

# 14. Built-in virtual methods (lifecycle order)
func _init() -> void:
    pass

func _enter_tree() -> void:
    pass

func _ready() -> void:
    _health = max_health
    _connect_signals()

func _process(delta: float) -> void:
    _handle_input()

func _physics_process(delta: float) -> void:
    _apply_movement()

func _exit_tree() -> void:
    pass

# 15. Signal callbacks (named _on_<source>_<signal>)
func _on_hitbox_area_entered(area: Area2D) -> void:
    take_damage(10)

# 16. Public methods
func take_damage(amount: int) -> void:
    _health -= amount
    health_changed.emit(_health)
    if _health <= 0:
        _die()

func heal(amount: int) -> void:
    _health = min(_health + amount, max_health)
    health_changed.emit(_health)

# 17. Private methods (underscore prefix)
func _handle_input() -> void:
    _input_direction = Input.get_axis("move_left", "move_right")

func _apply_movement() -> void:
    velocity.x = _input_direction * move_speed
    move_and_slide()

func _connect_signals() -> void:
    $Hitbox.area_entered.connect(_on_hitbox_area_entered)

func _die() -> void:
    current_state = State.DEAD
    died.emit()

# 18. Inner classes (last, rarely used)
class AttackData:
    var damage: int
    var knockback: float
```

---

## II. The Public/Private Method Question — Direct Answer

**They are separated into distinct blocks, NOT interleaved.**

| Approach | Practice |
|---|---|
| Group all public methods together | YES — official recommendation |
| Group all private methods together | YES — after public |
| Interleave related public+private pairs | NOT recommended by official docs or major community guides |

**Why separation wins:**
- A reader skimming the API of a class finds the public interface in one contiguous block
- Private implementation details are de-emphasized by placement — lower in the file, after the "contract"
- The `_` prefix already signals private; the block placement reinforces it visually
- Consistency with how GDScript's IDE doc generation works (`_` methods are excluded from built-in docs)

**The one common exception:** Signal callbacks (`_on_*`) are typically placed as their own group *between* lifecycle virtuals and public methods, since they're technically private but have a distinct functional role.

---

## III. The Mental Model — "Newspaper Article"

Think of a GDScript file like a newspaper article: the most important/public information is at the top, supporting details come after.

```
TOP (what is this class?)
  → class_name, extends, doc comment

THEN (what does it expose?)
  → signals, enums, constants, @export vars

THEN (internal state)
  → public vars, private vars, @onready

THEN (lifecycle/engine interface)
  → _init, _ready, _process, _physics_process

THEN (class public contract)
  → public methods

THEN (implementation guts)
  → private methods

BOTTOM (rare extras)
  → inner classes
```

---

## IV. Sections Within Variables — The Subtle Rule

Variables are NOT just dumped in one block. There are meaningful sub-groups:

```gdscript
# @export comes first (Inspector-visible — part of the "public face")
@export var speed: float = 200.0

# Public vars (readable/writable by other nodes, no underscore)
var current_speed: float = 0.0

# Private vars (underscore — internal implementation)
var _last_position: Vector2 = Vector2.ZERO

# @onready LAST (because they resolve at runtime, depend on tree being ready)
@onready var _label: Label = $Label
```

The `@onready` vars go last because they depend on the scene tree being initialized — placing them last signals "these aren't available until `_ready()` runs."

---

## V. Naming Cheatsheet (Applied to This Project)

| Thing | Convention | Example |
|---|---|---|
| Public variable | `snake_case` | `current_phase` |
| Private variable | `_snake_case` | `_draw_pile` |
| @export variable | `snake_case` (no underscore) | `starting_hand_size` |
| @onready variable | `_snake_case` (private) | `@onready var _deck: DeckNode` |
| Public method | `snake_case` | `draw_card()` |
| Private method | `_snake_case` | `_shuffle_deck()` |
| Signal callback | `_on_<node>_<signal>` | `_on_draw_button_pressed()` |
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_HAND_SIZE` |
| Enum values | `SCREAMING_SNAKE_CASE` | `TurnPhase.DRAW_CARD` |

---

## VI. Sources & Bibliography

- [GDScript Style Guide — Godot 4.4 Official Docs](https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [GDQuest GDScript Guidelines](https://gdquest.gitbook.io/gdquests-guidelines/godot-gdscript-guidelines)
- [GDScript Code Ordering — DEV.to (Official Godot)](https://dev.to/godot/gdscript-code-ordering-5d9f)
- [GDScript Code Ordering — Medium (Godot Community)](https://medium.com/@godotcommunity/gdscript-code-ordering-best-practices-for-arranging-your-code-elements-2bfd56355b93)
- [Godot Code Style & Project Structure — Simon Dalvai](https://simondalvai.org/blog/godot-best-practices/)
- [GDScript Best Practices — SyntaxCache](https://www.syntaxcache.com/gdscript/best-practices)
