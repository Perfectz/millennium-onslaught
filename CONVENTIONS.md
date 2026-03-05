# Code Conventions — Millennium Onslaught

> **Purpose:** Enforced conventions for all code in this project. AI agents and human developers must follow these without exception.

**Created:** 2026-03-01
**Last Updated:** 2026-03-05

---

## File Organization

### One Class Per File
Every `.gd` file contains exactly one class. The file name matches the class purpose in snake_case.

### File Header
Every script starts with a single-line `##` doc comment describing the class purpose.

```gdscript
## Manages player health, damage intake, and death detection.
class_name HealthComponent
extends Node
```

### Section Order Within a File
1. Doc comment
2. `class_name` declaration
3. `extends` declaration
4. Signal declarations
5. Enums
6. Constants
7. `@export` variables
8. `@onready` variables
9. Public member variables
10. Private member variables (prefix `_`)
11. `_ready()`, `_process()`, `_physics_process()`, `_input()`
12. Public methods
13. Private methods (prefix `_`)

---

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Files/folders | snake_case | `health_component.gd` |
| Classes | PascalCase | `HealthComponent` |
| Resources | PascalCase (class), snake_case (file) | `CharacterDef` / `chaz_character.tres` |
| Variables | snake_case | `player_speed` |
| Private variables | _snake_case | `_current_hp` |
| Functions | snake_case | `calculate_damage()` |
| Private functions | _snake_case | `_apply_knockback()` |
| Constants | UPPER_SNAKE_CASE | `MAX_JUGGLE_COUNT` |
| Signals | snake_case with domain prefix | `combat_hit_landed` |
| Enums | PascalCase type, UPPER_SNAKE_CASE values | `enum Phase { MAIN_MENU, DUNGEON }` |

---

## Type Hints

**Required on all:**
- Function parameters
- Function return types
- Member variables (public and private)
- Local variables where type isn't obvious from assignment

```gdscript
# Good
var _current_hp: float = 100.0
func take_damage(amount: float) -> float:
    var actual: float = maxf(0.0, amount - _defense)
    return actual

# Bad — missing type hints
var _current_hp = 100.0
func take_damage(amount):
    var actual = max(0, amount - _defense)
```

---

## Constants Usage

**Zero hardcoded gameplay values.** Every tunable number lives in `Constants`.

```gdscript
# Good
velocity.y = Constants.PLAYER_JUMP_VELOCITY

# Bad — hardcoded
velocity.y = 14.0
```

New constants go in the appropriate section of `autoloads/constants.gd` with a descriptive name.

---

## Event Bus Usage

**All cross-system communication goes through EventBus.** No system directly references another system.

```gdscript
# Good — emit through event bus
EventBus.combat_hit_landed.emit(self, target, damage, position)

# Bad — direct reference
combat_system.apply_damage(target, damage)
```

### Signal Connection in _ready()
```gdscript
func _ready() -> void:
    EventBus.combat_hit_landed.connect(_on_hit_landed)
```

---

## State Management

**GameState is the single source of truth.** No system maintains its own authoritative copy of game state.

```gdscript
# Good
GameState.gold += gold_amount
EventBus.rpg_gold_changed.emit(GameState.gold)

# Bad — local state diverges from truth
_local_gold += gold_amount
```

---

## Object Pooling

**All frequently spawned objects use ObjectPool.** No direct `instantiate()` for enemies, projectiles, VFX, or damage numbers in production code.

```gdscript
# Good
var enemy: Node = ObjectPool.get_instance(&"rusher")

# Bad — direct instantiation in gameplay
var enemy := rusher_scene.instantiate()
add_child(enemy)
```

---

## Inheritance Limits

**Maximum 2 levels deep.** Beyond that, use composition.

```
# Acceptable
Node → CharacterBody3D → PlayerController
Node → EnemyBase → RusherEnemy

# Too deep — refactor to composition
Node → Entity → Enemy → RangedEnemy → MagicRangedEnemy
```

---

## Performance Rules

### No Per-Frame Allocation
Pre-allocate working variables as class members instead of creating new objects every frame.

```gdscript
# Good — pre-allocated
var _velocity_work: Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
    _velocity_work.x = direction * Constants.PLAYER_RUN_SPEED

# Bad — allocates every frame
func _physics_process(delta: float) -> void:
    var vel := Vector3(direction * speed, 0, 0)  # New Vector3 every frame
```

### Delta Time Cap
Always cap delta to prevent physics explosions on lag spikes.

```gdscript
func _physics_process(delta: float) -> void:
    var capped_delta: float = minf(delta, Constants.DELTA_CAP)
```

---

## Documentation

### Public API Comments
Every public class and public method gets a one-line `##` doc comment.

```gdscript
## Take damage and return actual damage dealt after defense.
func take_damage(amount: float) -> float:
```

### No Excessive Comments
Don't comment obvious code. Comment why, not what.

```gdscript
# Good — explains why
## Cap at zero to prevent negative health display.
_current_hp = maxf(0.0, _current_hp - actual)

# Bad — explains what (obvious)
# Subtract actual from current hp
_current_hp = _current_hp - actual
```

---

## Error Handling

### push_error for Irrecoverable States
```gdscript
if pool_key == &"":
    push_error("ObjectPool: instance missing pool_key meta")
    return
```

### push_warning for Recoverable Issues
```gdscript
if not FileAccess.file_exists(path):
    push_warning("Config file not found, using defaults: " + path)
```

---

## Testing Conventions

### Test File Naming
Tests mirror the source file path: `scripts/components/health_component.gd` → `tests/unit/test_health_component.gd`

### Test Method Naming
```gdscript
func test_take_damage_reduces_hp() -> void:
func test_take_damage_at_zero_triggers_death() -> void:
func test_heal_does_not_exceed_max() -> void:
```

### TDD Workflow
1. Write failing test
2. Write minimum code to pass
3. Refactor while tests stay green
4. Commit

---

## Git Conventions

### Commit Messages
- Imperative mood: "Add health component" not "Added health component"
- Concise first line (50 chars max ideal)
- Reference backlog item when applicable
- Body for non-obvious changes

### Branch Naming
- `feature/<descriptive-name>` for new features
- `fix/<descriptive-name>` for bug fixes
- `refactor/<descriptive-name>` for refactoring

---

## Anti-Patterns (Do Not)

1. **Don't** import one system from another — use EventBus
2. **Don't** hardcode numbers — use Constants
3. **Don't** instantiate poolable objects directly — use ObjectPool
4. **Don't** mutate GameState from multiple sources without events
5. **Don't** create deep inheritance hierarchies — compose
6. **Don't** allocate in _process or _physics_process
7. **Don't** skip type hints
8. **Don't** write tests after code (TDD: test first)
9. **Don't** leave dead code — delete it
10. **Don't** add features beyond what was requested

---

## Version Tagging (Added Month 8)

- `v0.X.Y` — MVP X, patch Y
- Tags created on main branch only after MVP completion
- CI builds triggered on tag push
