# Performance Baseline — Millennium Onslaught

> **Purpose:** Baseline performance metrics for PC and Android targets. Updated after each MVP.

**Created:** 2026-03-05
**Last Updated:** 2026-03-05

---

## Targets

| Platform | Target FPS | Minimum FPS | Max Enemies | Notes |
|----------|-----------|-------------|-------------|-------|
| PC | 60 | 55 | 50+ | Primary development platform |
| Android | 30 | 25 | 20+ | Reduced particle counts, aggressive pooling |

## Frame Budget Allocation

| System | Budget (ms) | Notes |
|--------|------------|-------|
| Physics | 4.0 | Movement, collision |
| AI | 4.0 | Enemy decision-making |
| Combat | 2.0 | Damage calculation, hit registration |
| VFX | 2.0 | Particle updates |
| UI | 1.0 | HUD updates |
| Rendering | Remainder | Godot engine rendering |
| **Total** | **16.67** | **60fps target** |

## Object Pool Warm Sizes

| Pool | Count | Rationale |
|------|-------|-----------|
| Enemies | 20 | Max 8 on screen + 12 pre-warmed |
| Projectiles | 30 | Multiple enemies firing simultaneously |
| Hit VFX | 40 | Multiple hits per frame in combos |
| Damage Numbers | 20 | One per hit, short lifetime |

## Performance Rules

1. No per-frame allocations in _process or _physics_process
2. Pre-allocate working variables as class members
3. Use Object Pool for all frequently spawned objects
4. Delta time cap at 0.1s to prevent physics explosions
5. Terminal velocity cap to prevent runaway physics
6. Separate collision layers per interaction type

## Stress Test Results

_To be populated after each MVP stress test run._

| MVP | Enemies | Avg FPS (PC) | Min FPS (PC) | Avg FPS (Android) | Min FPS (Android) |
|-----|---------|-------------|-------------|-------------------|-------------------|
| 0 | N/A | N/A | N/A | N/A | N/A |
| 1 | TBD | TBD | TBD | TBD | TBD |
