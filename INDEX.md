# INDEX.md - Millennium Onslaught - Master System Index

> Purpose: authoritative implementation snapshot for systems, files, and test coverage.

Current Snapshot Date: 2026-03-01
Runtime Main Scene: `res://scenes/dungeon/rooms/test_arena.tscn`

---

## Autoloads (Singletons)

| System | File | Purpose |
|---|---|---|
| Constants | `autoloads/constants.gd` | Centralized gameplay tuning values |
| EventBus | `autoloads/event_bus.gd` | Global signal hub + event ring buffer |
| GameState | `autoloads/game_state.gd` | Runtime and persistent game data |
| GameManager | `autoloads/game_manager.gd` | Phase changes, pause/resume, scene transitions |
| ObjectPool | `autoloads/object_pool.gd` | Reusable instance pooling |
| AudioManager | `autoloads/audio_manager.gd` | SFX/music routing and mute state |
| SaveManager | `autoloads/save_manager.gd` | Save/load using `GameState` serialization |
| InputManager | `autoloads/input_manager.gd` | Input context and device connection events |

## Core Gameplay

| System | File | Purpose |
|---|---|---|
| State | `scripts/core/state.gd` | Base state contract |
| StateMachine | `scripts/core/state_machine.gd` | Generic finite state machine |
| Hitbox | `scripts/core/hitbox.gd` | Attack overlap detection |
| Hurtbox | `scripts/core/hurtbox.gd` | Receives hits and emits hit events |
| PlayerController | `scripts/core/player_controller.gd` | Player movement, combat, state machine wiring |
| CharacterModel | `scripts/core/character_model.gd` | 3D model loading, skinning, animation, flash effects |
| EnemyController | `scripts/ai/enemy_controller.gd` | Enemy behavior, combat, state machine wiring |

## Player States

| State | File |
|---|---|
| Idle | `scripts/core/player_states/player_state_idle.gd` |
| Run | `scripts/core/player_states/player_state_run.gd` |
| Jump | `scripts/core/player_states/player_state_jump.gd` |
| Fall | `scripts/core/player_states/player_state_fall.gd` |
| Land | `scripts/core/player_states/player_state_land.gd` |
| AttackLight | `scripts/core/player_states/player_state_attack_light.gd` |
| AttackHeavy | `scripts/core/player_states/player_state_attack_heavy.gd` |
| Dodge | `scripts/core/player_states/player_state_dodge.gd` |
| Hurt | `scripts/core/player_states/player_state_hurt.gd` |
| Dead | `scripts/core/player_states/player_state_dead.gd` |

## Enemy States

| State | File | Notes |
|---|---|---|
| Idle | `scripts/ai/enemy_states/enemy_state_idle.gd` | Idle/perception |
| Chase | `scripts/ai/enemy_states/enemy_state_chase.gd` | Approach player |
| Attack | `scripts/ai/enemy_states/enemy_state_attack.gd` | Melee attack sequence |
| Hurt | `scripts/ai/enemy_states/enemy_state_hurt.gd` | Hit reaction |
| Dead | `scripts/ai/enemy_states/enemy_state_dead.gd` | Death cleanup |
| Retreat | `scripts/ai/enemy_states/enemy_state_retreat.gd` | Ranged spacing behavior |
| Shoot | `scripts/ai/enemy_states/enemy_state_shoot.gd` | Projectile fire behavior |
| Block | `scripts/ai/enemy_states/enemy_state_block.gd` | Shield advance/block |
| Stagger | `scripts/ai/enemy_states/enemy_state_stagger.gd` | Guard-break vulnerability |

## Systems

| System | File | Purpose |
|---|---|---|
| CombatSystem | `scripts/systems/combat_system.gd` | Applies hit results and combat events |
| CameraFollow | `scripts/systems/camera_follow.gd` | Follow camera behavior |
| CameraShakeSystem | `scripts/systems/camera_shake_system.gd` | Camera shake feedback |
| HitstopSystem | `scripts/systems/hitstop_system.gd` | Temporary time-scale freeze |
| VFXSystem | `scripts/systems/vfx_system.gd` | Hit/kill VFX spawning |
| EnemyProjectile | `scripts/systems/enemy_projectile.gd` | Enemy projectile behavior |
| EncounterRoller | `scripts/systems/encounter_roller.gd` | Pure encounter randomization logic |
| WaveSystem | `scripts/systems/wave_system.gd` | Spawns and tracks encounter waves |
| DungeonManager | `scripts/dungeon/dungeon_manager.gd` | Room progression and dungeon completion/failure |

## Pure Components (Unit Tested)

| Component | File | Tests |
|---|---|---|
| HealthComponent | `scripts/components/health_component.gd` | 17 |
| ComboTracker | `scripts/components/combo_tracker.gd` | 11 |
| DamageCalculator | `scripts/components/damage_calculator.gd` | 7 |
| ComboCancelChecker | `scripts/components/combo_cancel_checker.gd` | 10 |
| JuggleTracker | `scripts/components/juggle_tracker.gd` | 15 |
| ScoreTracker | `scripts/components/score_tracker.gd` | 14 |

## Resources

| Resource Type | File |
|---|---|
| AttackDef | `resources/attacks/attack_def.gd` |
| EnemyDef | `resources/enemies/enemy_def.gd` |
| SpawnEntry | `resources/encounters/spawn_entry.gd` |
| WaveDef | `resources/encounters/wave_def.gd` |
| EncounterDef | `resources/encounters/encounter_def.gd` |
| DungeonDef | `resources/dungeons/dungeon_def.gd` |

### Current Data Assets

- `resources/attacks/light_attack_1.tres`
- `resources/attacks/light_attack_2.tres`
- `resources/attacks/light_attack_3.tres`
- `resources/attacks/heavy_attack.tres`
- `resources/attacks/enemy_rusher_attack.tres`

### Model Assets

- `assets/models/characters/kenney/idle.fbx` — Base model + idle animation (Kenney Animated Characters 2)
- `assets/models/characters/kenney/run.fbx` — Run animation
- `assets/models/characters/kenney/jump.fbx` — Jump animation
- `assets/models/characters/kenney/characterMedium.fbx` — Reference T-pose model
- `assets/models/characters/kenney/cyborgFemaleA.png` — Cyborg skin texture

## Scenes

| Scene | File | Purpose |
|---|---|---|
| Main | `scenes/main.tscn` | Original scaffold scene |
| TestArena | `scenes/dungeon/rooms/test_arena.tscn` | Current runtime scene |
| Player | `scenes/characters/player.tscn` | Player character scene |
| EnemyRusher | `scenes/enemies/enemy_rusher.tscn` | Enemy scene |
| HitParticles | `scenes/vfx/hit_particles.tscn` | Hit effect |
| DeathParticles | `scenes/vfx/death_particles.tscn` | Death effect |

## Tests

| Suite | File | Count |
|---|---|---|
| TestStateMachine | `tests/unit/systems/test_state_machine.gd` | 11 |
| TestEncounterRoller | `tests/unit/systems/test_encounter_roller.gd` | 7 |
| TestHealthComponent | `tests/unit/components/test_health_component.gd` | 17 |
| TestComboTracker | `tests/unit/components/test_combo_tracker.gd` | 11 |
| TestDamageCalculator | `tests/unit/components/test_damage_calculator.gd` | 7 |
| TestComboCancelChecker | `tests/unit/components/test_combo_cancel_checker.gd` | 10 |
| TestJuggleTracker | `tests/unit/components/test_juggle_tracker.gd` | 15 |
| TestScoreTracker | `tests/unit/components/test_score_tracker.gd` | 14 |

Total test functions: 92

## Controls

| Input | Action |
|---|---|
| A/D or Left/Right | Move left/right |
| W/S or Up/Down | Belt-depth movement |
| Space | Jump |
| J | Light attack |
| K | Heavy attack |
| L | Dodge |
| I | Block |
| U | Technique |
| R | Restart arena (`test_arena.gd`) |
| ESC | Quit |
