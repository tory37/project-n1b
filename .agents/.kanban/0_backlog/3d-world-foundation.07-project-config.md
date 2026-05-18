---
epic: 3d-world-foundation
ticket: project-config
created: 2026-05-17
priority: high
---

# 3D World Foundation: Update Project Configuration

**Step 7 of 7** — Set the main scene in `project.godot`.

## Change

Update `project.godot`:

```ini
[application]
config/main_scene = "res://world/main/main.tscn"
```

This makes `world/main/main.tscn` the scene that runs when the project launches.

## Verification

- [ ] `project.godot` updated with correct scene path
- [ ] Project runs from editor (F5 or play button)
- [ ] Main scene loads without errors
- [ ] Camera and board visible in viewport
- [ ] No import errors or missing asset warnings
