# CONVENTIONS.md — Enforced Code Conventions

> **Purpose:** Single source of truth for naming, layout, signal conventions, and style rules.
> All contributors (human and AI) must follow these conventions. Violations should be caught in code review.

---

## File Layout (per .gd file)

```gdscript
## One-line doc comment describing the class purpose.
class_name ClassName
extends BaseClass


# --- Signals (domain-prefixed) ---
signal combat_hit_landed(target: Node, damage: float)


# --- Enums ---
enum State { IDLE, ACTIVE, DEAD }


# --- Constants (UPPER_SNAKE_CASE) ---
const MAX_RETRIES: int = 3


# --- Exported variables ---
@export var speed: float = 0.0


# --- @onready node references ---
@onready var _sprite: Sprite3D = $Sprite3D


# --- Public member variables (snake_case) ---
var health: float = 100.0


# --- Private member variables (underscore prefix) ---
var _timer: float = 0.0


# --- Lifecycle methods ---
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	pass


# --- Public methods ---
func take_damage(amount: float) -> void:
	pass


# --- Private methods ---
func _apply_knockback(force: Vector3) -> void:
	pass
```

---

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Files/folders | `snake_case` | `health_component.gd`, `player_states/` |
| Classes/resources | `PascalCase` | `CharacterDef`, `EnemyController` |
| Variables/functions | `snake_case` | `player_speed`, `calculate_damage()` |
| Private members | `_underscore_prefix` | `_timer`, `_is_active` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_JUGGLE_COUNT`, `BASE_GRAVITY` |
| Signals | `snake_case` with domain prefix | `combat_hit_landed`, `rpg_level_up` |
| Enums | `PascalCase` type, `UPPER_SNAKE_CASE` values | `enum Mode { FOLLOW, DIRECTOR }` |
| Resource files (.tres) | `snake_case` | `alys.tres`, `light_attack_1.tres` |
| Scene files (.tscn) | `snake_case` | `player.tscn`, `academy_b1_entry.tscn` |

---

## Signal Naming

### Domain Prefixes

| Domain | Prefix | Example |
|--------|--------|---------|
| Combat | `combat_` | `combat_hit_landed`, `combat_combo_milestone` |
| Enemy | `enemy_` | `enemy_died`, `enemy_wave_cleared` |
| Player | `player_` | `player_health_changed`, `player_died` |
| RPG | `rpg_` | `rpg_level_up`, `rpg_xp_gained` |
| Dungeon | `dungeon_` | `dungeon_room_entered`, `dungeon_completed` |
| Encounter | `encounter_` | `encounter_arena_locked`, `encounter_arena_unlocked` |
| Stage | `stage_` | `stage_bounds_updated`, `stage_encounter_activated` |
| UI | `ui_` | `ui_pause_requested`, `ui_settings_changed` |
| Camera | `camera_` | `camera_director_cue`, `camera_director_return` |
| Audio | `audio_` | `audio_mute_toggled`, `audio_volume_changed` |
| Input | `input_` | `input_device_changed`, `input_touch_visibility_changed` |

### Signal Payload Rules

1. Use typed parameters, not dictionaries
2. Include the emitting entity reference when relevant (e.g., `enemy: Node`)
3. Keep payloads minimal — only data the listener needs
4. Document each signal's emitter and listeners in the event catalog

---

## Type Hints

**Required on all:**
- Function parameters: `func take_damage(amount: float) -> void:`
- Function return types: `func get_health() -> float:`
- Member variables: `var _timer: float = 0.0`
- Local variables where type is ambiguous: `var enemy: EnemyController = node as EnemyController`

**Optional on:**
- Loop variables with obvious type: `for child in get_children():`
- Inline lambdas

---

## Doc Comments

- One-line `##` doc comment on every public class (below `class_name`)
- One-line `##` doc comment on every public method
- No doc comments needed on private methods (use regular `#` if complex)
- No doc comments on obvious getters/setters

```gdscript
## Tracks player health and emits signals on change.
class_name HealthComponent
extends RefCounted

## Deal damage and clamp to zero. Returns actual damage dealt.
func take_damage(amount: float) -> float:
```

---

## Hard Rules (Non-Negotiable)

1. **Zero hardcoded gameplay values** — All numbers go in `Constants` singleton
2. **EventBus for cross-system communication** — No system imports another system
3. **GameState is single source of truth** — No local authoritative state copies
4. **ObjectPool for frequently spawned objects** — No `instantiate()` in hot paths
5. **Atomic save writes** — Write to temp file, then rename
6. **Max 2 levels inheritance** — Use composition beyond that
7. **No per-frame allocation** — Pre-allocate working variables as class members
8. **Delta time cap** — `Constants.DELTA_CAP` applied in StateMachine, not per-state
9. **`is_instance_valid()` before accessing freed-risk nodes** — Especially targets, entities, pooled objects
10. **One class per file** — No inner classes except small data containers

---

## Anti-Patterns to Avoid

| Don't | Do Instead |
|-------|-----------|
| `Input.is_action_just_pressed()` in states | `intent_buffer.consume(&"action")` |
| `get_tree().change_scene_to_file()` | `GameManager.go_to_*()` |
| `instantiate()` for VFX/projectiles | `ObjectPool.get_instance()` |
| `emit_signal("name")` (string-based) | `signal_name.emit()` (typed) |
| Ad-hoc `Dictionary` for attack data | `AttackDef` resource |
| `entity.target != null` for freed check | `is_instance_valid(entity.target)` |
| Hardcoded `Vector3(9999, 9999, 9999)` | `Constants.POOL_DEACTIVATE_POSITION` |
| Direct `Input.is_key_pressed()` | Godot input actions via `InputMap` |
