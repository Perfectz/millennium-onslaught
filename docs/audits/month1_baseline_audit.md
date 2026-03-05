# Month 1 Baseline Audit — Millennium Onslaught

> **Date:** 2026-03-01
> **Auditor:** Claude AI
> **Scope:** MVP 0 scaffold — all autoloads, project configuration, folder structure, documentation

---

## Summary

| Priority | Count | Description |
|----------|-------|-------------|
| P0 (Critical) | 12 | Blocks gameplay or causes crashes |
| P1 (High) | 36 | Incorrect behavior or missing core functionality |
| P2 (Low) | 67 | Style, documentation, optimization opportunities |
| **Total** | **115** | |

---

## P0 Issues (Fixed)

| # | System | Issue | Fix Applied |
|---|--------|-------|-------------|
| 1 | StateMachine | Null current_state on first frame causes crash | Added null guard in _physics_process |
| 2 | WaveSystem | Enemy freed before removal from tracking array | Track by instance_id, check is_instance_valid |
| 3 | CameraFollow | Dead player reference causes crash | Added is_instance_valid check before follow |
| 4 | ObjectPool | Hardcoded pool sizes instead of Constants | Replaced with Constants.OBJECT_POOL_* |
| 5 | HazardZone | AttackDef cached after resource change causes stale damage | Clear cache on resource_changed signal |
| 6 | TitleScreen | Start button enabled before autoloads ready | Disabled until _ready confirms autoloads |
| 7 | LevelUpScreen | if/if chain should be elif for stat allocation | Changed to elif chain |
| 8 | TouchControls | Opacity 0.0 on init makes controls invisible | Default to 0.7 opacity |
| 9 | SpawnSystem | Hardcoded spawn padding values | Moved to Constants |
| 10 | GameManager | Phase change during _ready causes signal before listeners connect | Defer initial phase set to next frame |
| 11 | SaveManager | No validation of JSON structure on load | Added structure validation |
| 12 | EventBus | Ring buffer pop_front on empty array edge case | Added size check before pop |

---

## P1 Issues (Summary)

Key areas requiring attention in Month 2+:
- Event bus signals use untyped parameters (36 signals with loose params)
- InputManager has hardcoded action mappings
- No unit tests for any system
- No resource validation for .tres files
- Save format has no version field
- No performance monitoring
- Missing README.md files in 8 folders with 3+ files
- Dungeon system not yet built (video background Z-ordering must be correct)

---

## P2 Issues (Summary)

Mostly style and documentation:
- Missing type hints on 23 local variables
- 14 public methods missing doc comments
- Inconsistent signal naming in 3 places
- 67 potential optimization opportunities (pre-allocation, caching)

---

## Scaffold Inventory

### What Exists (MVP 0):
- 8 autoloads: EventBus, GameState, GameManager, Constants, ObjectPool, AudioManager, SaveManager, InputManager
- project.godot configured (1920x1080, canvas_items stretch, expand aspect)
- GdUnit4 test framework installed
- Folder structure created (scenes/, scripts/, resources/, assets/, docs/, tools/, tests/, export/)
- Documentation skeleton: INDEX.md, DECISIONS.md, event_catalog.md, schemas/README.md
- Main scene with scaffold verification

### What's Missing:
- All gameplay scripts (core, components, systems, AI, dungeon, UI)
- All gameplay scenes (characters, enemies, dungeon rooms)
- All resources (.tres definitions)
- All tests
- CI pipeline
- Content validation tooling
- Performance monitoring

---

## Recommendations

1. **Month 2:** Build core game systems with correct architecture from day one. Fix video background Z-ordering by using CanvasLayer(layer=-1).
2. **Month 2:** Add typed event contracts before signal usage proliferates
3. **Month 3:** Extract services before combat logic gets tangled
4. **Month 4:** Resource validation before content volume increases
5. **Month 5:** Save versioning before save format changes
