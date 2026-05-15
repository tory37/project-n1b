# Blue Theta Seven (Working Title)

A Turn-Based Deckbuilder / Tabletop Skirmish Hybrid built with Godot 4.

## 🌟 Vision & Pillars

* **System-First Design:** Mechanics are fun and functional without a theme.
* **Tactical Construction:** Players build the map, creating a unique battlefield every game.
* **The "North Star":** A hybrid feel of a TCG and Warhammer—pre-game preparation meets mid-game tactical execution.

## 🛠 Tech Stack

* **Engine:** Godot 4.6 (Forward+ Renderer)
* **Language:** GDScript 2.0
* **Architecture:** Feature-Based (Entity-System)

## 🌐 Networking Architecture

This project is built with a **networking seam** from day one. All state mutations in Autoload singletons follow a `request_*` / `_apply_*` split so that Godot 4 `@rpc` decorators can be added later without touching game logic.

See the **Networking Architecture** section in [AGENTS.md](./AGENTS.md) for the full mandate.

## 📁 Project Structure (Modern Godot Standard)

We follow a **Feature-Based** organization, keeping related scenes, scripts, and local assets together.

```text
res://
├── assets/              # Global/Shared assets (fonts, themes, music)
├── common/              # Reusable components (HealthComponent, Hitbox)
├── entities/            # Game objects (Player, Enemies, Cards)
│   └── card/            # card.tscn, card.gd, card_sprite.png
├── systems/             # Core logic (TurnManager, CombatLog, GridSystem)
├── ui/                  # User Interface (Menus, HUD)
└── levels/              # Level scenes
```

## 📜 Development Guidelines

See [AGENTS.md](./AGENTS.md) for detailed architectural rules and coding standards.

---

### Research & References

* [Official Godot Organization Guidelines](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)
* [Feature-Based vs Type-Based Structure](https://www.reddit.com/r/godot/comments/1665rvy/project_organization_featurebased_vs_typebased/)
* [Godot 4 Entity-Component Pattern](https://github.com/nathanhoad/godot_component_system)
