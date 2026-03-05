# Month 1 Baseline Audit Report

**Date:** 2026-03-04
**Auditor:** Claude Code (Opus 4.6)
**Scope:** All autoloads, core scripts, player/enemy states, UI scripts, resource definitions

---

## Summary

| Severity | Count | Description |
|----------|-------|-------------|
| **P0** | 12 | Crash, deadlock, memory leak |
| **P1** | 36 | Gameplay-breaking, data loss, wrong behavior |
| **P2** | 67 | Quality, tech debt, convention violations |
| **Total** | **115** | |

---

## P0 — Crash / Deadlock (12)

### P0-01: Dust particles not pooled — unbounded node leak
- **File:** `scripts/core/player_controller.gd:300-335`
- **Description:** `spawn_dust()` creates 5 new GPU objects per call (GPUParticles3D, materials, mesh). Called every 0.15s while running. OOM risk on Android.
- **Fix:** Pool via ObjectPool or use a single persistent particle system.

### P0-02: WaveSystem enemy_died counter desync between overlapping encounters
- **File:** `scripts/systems/wave_system.gd:123-129`
- **Description:** Global `enemy_died` listener decrements counter without verifying the dying enemy belongs to the current encounter.
- **Fix:** Track spawned enemy instance IDs; only decrement for matched enemies. **FIXED IN MONTH 1.**

### P0-03: StateMachine.transition_to() crashes if _current_state is null
- **File:** `scripts/core/state_machine.gd:49`
- **Description:** No null check before `_current_state.exit()`.
- **Fix:** Add null guard. **FIXED IN MONTH 1.**

### P0-04: HealthComponent replacement leaks old signals
- **File:** `scripts/core/player_controller.gd:547-555`
- **Description:** New HealthComponent created without disconnecting old signal connections.
- **Fix:** Reset health in-place or disconnect old signals before replacing.

### P0-05: Spell state await desync in physics_process
- **File:** `scripts/core/player_states/player_state_spell.gd:165`
- **Description:** `await physics_frame` in `_cast_aoe_burst()` suspends mid-frame; state may transition before resume.
- **Fix:** Use single-frame overlap check or deferred callback.

### P0-06: entity.get_tree().root.add_child() without tree check
- **File:** `scripts/core/player_states/player_state_technique.gd:99`
- **Description:** `get_tree()` returns null if entity removed from tree. Also affects spell state.
- **Fix:** Add `if entity.is_inside_tree():` guard.

### P0-07: Death state tween on potentially freed entity
- **File:** `scripts/core/player_states/player_state_dead.gd:17-20`
- **Description:** Tween references entity during scene transitions.
- **Fix:** Check `is_instance_valid` in tween callbacks.

### P0-08: Enemy death tween callback on freed entity
- **File:** `scripts/ai/enemy_states/enemy_state_dead.gd:29-39`
- **Description:** Dissolve callback captures entity and mesh; crash if freed during scene change.
- **Fix:** Guard callback with `is_instance_valid`.

### P0-09: Title screen fires disabled button press
- **File:** `scripts/ui/title_screen.gd:338`
- **Description:** Missing `not focused.disabled` check before `emit_signal("pressed")`.
- **Fix:** Add disabled check. **FIXED IN MONTH 1.**

### P0-10: Level-up screen missing elif causes double-fire
- **File:** `scripts/ui/level_up_screen.gd:219-226`
- **Description:** Cancel and accept can both fire on same input event.
- **Fix:** Change second `if` to `elif`. **FIXED IN MONTH 1.**

### P0-11: DamageNumberSpawner parents pooled nodes under current_scene
- **File:** `autoloads/damage_number_spawner.gd:62-66`
- **Description:** Scene change frees pooled labels; ObjectPool holds freed references.
- **Fix:** Parent under ObjectPool autoload or persistent layer.

### P0-12: Technique null access on tp_tracker
- **File:** `scripts/core/player_states/player_state_technique.gd:30`
- **Description:** `player.tp_tracker.get_current_tp()` has no null guard.
- **Fix:** Add null check.

---

## P1 — Gameplay-Breaking (36)

*(Summary — see full agent audit transcripts for details)*

- **Stale health closure after character switch** (player_controller.gd:478)
- **VFX signal leak on pool return** (vfx_system.gd:67-71)
- **AudioManager mute recursion risk** (audio_manager.gd:276-280)
- **Zoom punch FOV drift** (juice_manager.gd:159-168)
- **EnemyController.configure() re-enters state** (enemy_controller.gd:418)
- **StageRunner global wave_cleared listener** (stage_runner.gd:68)
- **CameraFollow bypasses InputManager** (camera_follow.gd:306-311)
- **Photo mode uses raw Input.is_key_pressed** (camera_follow.gd:384-413)
- **13x hardcoded values in player/enemy states** (various)
- **Per-frame group query in enemy_state_chase** (enemy_state_chase.gd:66-79)
- **Missing is_instance_valid on enemy.target** (multiple enemy states)
- **Missing bounds clamping** in retreat, hurt, stagger, attack, shoot, boss_phase_check states
- **Victory screen hardcoded rank scoring** (victory_screen.gd:122-139)
- **Pause menu bypasses GameManager** (pause_menu.gd:208)
- **Town controller null-unsafe TownDef cast** (town_controller.gd:98)
- **Touch button opacity not restored** (touch_controls.gd:145)

---

## P2 — Quality / Tech Debt (67)

*(Categories)*

- **Hardcoded values (30):** Timing, damage, colors, positions across states and systems
- **Missing type hints (8):** Overworld controller, shop screen, various
- **Per-frame/hot-path allocations (10):** Dictionary creation, material creation, group queries
- **Convention violations (7):** emit_signal vs .emit(), private method access, debug prints
- **Missing validation (5):** Resource defs (CharacterDef, EnemyDef, etc.) have no validate()
- **Code duplication (4):** Modal overlay boilerplate, XP formula, splash timing
- **Missing defensive checks (3):** is_instance_valid, null guards, default match arms

---

## Fixes Applied in Month 1

| Issue | Fix Description | File(s) Changed |
|-------|----------------|-----------------|
| P0-02 | WaveSystem tracks spawned enemy IDs | wave_system.gd |
| P0-03 | StateMachine null guard in transition_to | state_machine.gd |
| P0-09 | Title screen disabled button check | title_screen.gd |
| P0-10 | Level-up screen elif fix | level_up_screen.gd |
| P1-CameraFollow | is_instance_valid target check | camera_follow.gd |
| P2-ObjectPool | Constants for deactivate position | object_pool.gd, constants.gd |
| P2-HazardZone | Cached AttackDef | hazard_zone.gd |
| P2-WaveSystem | Hardcoded pad to Constants | wave_system.gd, constants.gd |

---

## Deferred to Month 2+

- P0-01 (dust particle pooling) — Requires VFX system rework
- P0-04 (health component signal leak) — Requires PlayerController refactor
- P0-05 (spell state await) — Requires state pattern change
- P1 hardcoded values — Will be addressed in Month 4 (data layer)
- P2 resource validation — Month 4 deliverable
- P2 code duplication — Ongoing cleanup
