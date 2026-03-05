# INDEX.md - Millennium Onslaught - Master System Index

> Purpose: authoritative implementation snapshot for systems, files, and test coverage.

Current Snapshot Date: 2026-03-04
Current MVP: MVP 6 "Together" (in progress — save hardening, settings, remapping, Android)
Roadmap Phase: Month 1 "Foundation Hardening" — COMPLETE
Runtime Main Scene: `res://scenes/ui/main_menu.tscn`
Dev Test Scene: `res://scenes/dungeon/rooms/test_arena.tscn`

---

## Known-Issue Freeze List

> **Purpose:** No unresolved risk is silently buried. All known issues are tracked here with severity and target resolution.

| ID | Severity | Description | File(s) | Target |
|----|----------|-------------|---------|--------|
| KI-01 | P0 | Dust particles not pooled — unbounded node leak on Android | player_controller.gd:300 | Month 2 |
| KI-02 | P0 | HealthComponent replacement leaks old signal closures (kill-heal lost after char switch) | player_controller.gd:547 | Month 2 |
| KI-03 | P0 | Spell state `await physics_frame` can desync state machine | player_state_spell.gd:165 | Month 2 |
| KI-04 | P0 | DamageNumberSpawner parents pooled Label3D under current_scene (freed on transition) | damage_number_spawner.gd:63 | Month 2 |
| KI-05 | P1 | VFX finished signal leak on pooled particles returned early | vfx_system.gd:67 | Month 2 |
| KI-06 | P1 | Zoom punch FOV drift from overlapping calls | juice_manager.gd:159 | Month 2 |
| KI-07 | P1 | EnemyController.configure() calls set_initial_state without exiting old state | enemy_controller.gd:418 | Month 2 |
| KI-08 | P1 | Per-frame O(N^2) group query in enemy_state_chase flanking | enemy_state_chase.gd:66 | Month 3 |
| KI-09 | P1 | Missing is_instance_valid(target) in 6+ enemy states | multiple enemy states | Month 2 |
| KI-10 | P1 | Missing bounds clamping in retreat, hurt, stagger, attack, shoot, boss_phase_check states | multiple enemy states | Month 2 |
| KI-11 | P2 | 30+ hardcoded gameplay values across states | various | Month 4 |
| KI-12 | P2 | Resource definitions have no validate() methods | various resource defs | Month 4 |
| KI-13 | P1 | Pause menu bypasses GameManager for scene transition | pause_menu.gd:208 | Month 2 |
| KI-14 | P2 | Legacy emit_signal("pressed") pattern across 9 UI files | various UI scripts | Month 3 |

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
| InputManager | `autoloads/input_manager.gd` | Input context, device mapping, keyboard/joypad remapping, mobile helpers |
| JuiceManager | `autoloads/juice_manager.gd` | Screen shake, flash, slow-mo, vignette effects |
| ToastSystem | `autoloads/toast_system.gd` | Queued notification popups (gold, level up, etc.) |
| DamageNumberSpawner | `autoloads/damage_number_spawner.gd` | Pooled floating damage numbers |

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
| AttackLauncher | `scripts/core/player_states/player_state_attack_launcher.gd` |
| Technique | `scripts/core/player_states/player_state_technique.gd` |

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
| BossPhaseCheck | `scripts/ai/enemy_states/enemy_state_boss_phase_check.gd` | Boss phase transition |

## Systems

| System | File | Purpose |
|---|---|---|
| CombatSystem | `scripts/systems/combat_system.gd` | Applies hit results and combat events |
| CameraFollow | `scripts/systems/camera_follow.gd` | Spring-damped follow camera: dead zones (X+Y), velocity look-ahead, enemy centroid threat bias, dynamic FOV zoom, arena lock (X+Z), trauma shake (real-time), breathing, director cue system, photo mode |
| HitstopSystem | `scripts/systems/hitstop_system.gd` | Temporary time-scale freeze |
| VFXSystem | `scripts/systems/vfx_system.gd` | Hit/kill VFX spawning |
| EnemyProjectile | `scripts/systems/enemy_projectile.gd` | Enemy projectile behavior |
| PlayerProjectile | `scripts/systems/player_projectile.gd` | Player technique projectile |
| EncounterRoller | `scripts/systems/encounter_roller.gd` | Pure encounter randomization logic |
| WaveSystem | `scripts/systems/wave_system.gd` | Spawns and tracks encounter waves |
| DungeonManager | `scripts/dungeon/dungeon_manager.gd` | Room progression and dungeon completion/failure |
| SceneTransitioner | `scripts/systems/scene_transitioner.gd` | Multi-wipe scene transitions (fade, diamond, slash, pixelate) |
| StageRunner | `scripts/dungeon/stage_runner.gd` | Continuous stage orchestrator: loads chunks, places encounter triggers, manages forward bounds |
| EncounterTrigger | `scripts/systems/encounter_trigger.gd` | Area3D trigger zone that activates encounters when player enters |
| ThrowableObject | `scripts/systems/throwable_object.gd` | Environmental throwable object with projectile conversion |
| HazardZone | `scripts/systems/hazard_zone.gd` | Environmental hazard area (DoT, instant, knockback) |
| StageValidator | `scripts/tools/stage_validator.gd` | StageDef validation tool |
| TouchControls | `scripts/ui/touch_controls.gd` | Virtual joystick + action buttons for Android |

## Juice & Polish Systems

| System | File | Purpose |
|---|---|---|
| DissolveEffect | `scripts/utils/dissolve_effect.gd` | Dissolve/materialize shader helper for meshes |
| Dissolve Shader | `assets/shaders/dissolve.gdshader` | Noise-based dissolve with glowing edge |
| UIStyle | `scripts/ui/ui_style.gd` | Shared glass-morphism UI: style_button, create_panel_style, create_glow_orb, apply_screen_effects, button sounds, stagger animations |
| SplashScreen | `scripts/ui/splash_screen.gd` | Studio splash before title screen |
| SettingsMenu | `scripts/ui/settings_menu.gd` | Unified settings screen (Audio/Display/Controls tabs) |
| ControllerSettings | `scripts/ui/controller_settings.gd` | Dual keyboard + joypad remapping screen |

## Pure Components (Unit Tested)

| Component | File | Tests |
|---|---|---|
| HealthComponent | `scripts/components/health_component.gd` | 17 |
| ComboTracker | `scripts/components/combo_tracker.gd` | 11 |
| DamageCalculator | `scripts/components/damage_calculator.gd` | 11 |
| ComboCancelChecker | `scripts/components/combo_cancel_checker.gd` | 10 |
| JuggleTracker | `scripts/components/juggle_tracker.gd` | 15 |
| ScoreTracker | `scripts/components/score_tracker.gd` | 14 |
| TPTracker | `scripts/components/tp_tracker.gd` | 14 |
| StoryFlagManager | `scripts/components/story_flag_manager.gd` | 13 |
| ShopTransaction | `scripts/components/shop_transaction.gd` | 12 |
| GoldTracker | `scripts/components/gold_tracker.gd` | 13 |
| InputIntentBuffer | `scripts/components/input_intent_buffer.gd` | 21 |
| XPTracker | `scripts/components/xp_tracker.gd` | 13 |
| StatCalculator | `scripts/components/stat_calculator.gd` | 10 |
| EquipmentManager | `scripts/components/equipment_manager.gd` | 15 |
| SkillTreeManager | `scripts/components/skill_tree_manager.gd` | 12 |
| ElementCalculator | `scripts/components/element_calculator.gd` | 11 |
| StatusEffectTracker | `scripts/components/status_effect_tracker.gd` | 13 |
| DropRoller | `scripts/components/drop_roller.gd` | 6 |

## Resources

| Resource Type | File |
|---|---|
| AttackDef | `resources/attacks/attack_def.gd` |
| EnemyDef | `resources/enemies/enemy_def.gd` |
| SpawnEntry | `resources/encounters/spawn_entry.gd` |
| WaveDef | `resources/encounters/wave_def.gd` |
| EncounterDef | `resources/encounters/encounter_def.gd` |
| DungeonDef | `resources/dungeons/dungeon_def.gd` |
| EquipmentDef | `resources/equipment/equipment_def.gd` |
| OverworldNodeDef | `resources/story/overworld_node_def.gd` |
| TownDef | `resources/towns/town_def.gd` |
| CharacterDef | `resources/characters/character_def.gd` |
| TechniqueDef | `resources/techniques/technique_def.gd` |
| SkillNodeDef | `resources/skills/skill_node_def.gd` |
| SkillTreeDef | `resources/skills/skill_tree_def.gd` |
| StageDef | `resources/stages/stage_def.gd` |
| StageEncounterEntry | `resources/stages/stage_encounter_entry.gd` |

### Current Data Assets

- `resources/attacks/light_attack_1.tres`
- `resources/attacks/light_attack_2.tres`
- `resources/attacks/light_attack_3.tres`
- `resources/attacks/heavy_attack.tres`
- `resources/attacks/enemy_rusher_attack.tres`
- `resources/attacks/enemy_ranged_attack.tres`
- `resources/attacks/enemy_shield_attack.tres`
- `resources/attacks/launcher_attack.tres`
- `resources/attacks/projectile_attack.tres`
- `resources/attacks/boss_attack_1.tres`
- `resources/attacks/boss_attack_2.tres`
- `resources/enemies/rusher_def.tres` (gold_reward=5)
- `resources/enemies/ranged_def.tres` (gold_reward=8)
- `resources/enemies/shield_def.tres` (gold_reward=10)
- `resources/enemies/boss_def.tres` (gold_reward=50)
- `resources/encounters/encounter_room1.tres`
- `resources/encounters/encounter_room2.tres`
- `resources/encounters/encounter_room3.tres`
- `resources/encounters/encounter_boss.tres`
- `resources/dungeons/dungeon_1.tres`
- `resources/equipment/iron_sword.tres`
- `resources/equipment/steel_sword.tres`
- `resources/equipment/leather_armor.tres`
- `resources/equipment/chain_mail.tres`
- `resources/equipment/power_ring.tres`
- `resources/equipment/healing_herb.tres`
- `resources/towns/piata.tres` (shop: 6 items, inn, 3 NPCs)
- `resources/story/node_piata.tres` (town, start)
- `resources/story/node_dungeon_1.tres` (dungeon)
- `resources/story/node_birth_valley.tres` (dungeon, locked: dungeon_1_complete)
- `resources/story/node_zema.tres` (town, locked: dungeon_1_complete)
- `resources/characters/alys.tres` (Hunter, high agility)
- `resources/characters/chaz.tres` (Warrior, high strength)
- `resources/characters/rune.tres` (Mage, high magic)
- `resources/characters/wren.tres` (Android, high defense)
- `resources/techniques/vortex.tres` (Alys, fire)
- `resources/techniques/shadow_blade.tres` (Alys, dark)
- `resources/techniques/rayblade.tres` (Chaz, lightning)
- `resources/techniques/astral.tres` (Chaz, ice)
- `resources/techniques/flaeli.tres` (Rune, fire AoE)
- `resources/techniques/hewn.tres` (Rune, ice)
- `resources/techniques/tandle.tres` (Rune, lightning)
- `resources/techniques/burst_rocket.tres` (Wren, fire AoE)
- `resources/techniques/spark.tres` (Wren, lightning)
- `resources/equipment/silver_sword.tres` (weapon, +5str, 250g)
- `resources/equipment/platinum_armor.tres` (armor, +4def, 300g)
- `resources/equipment/speed_boots.tres` (accessory, +3agi, 350g)
- `resources/equipment/flame_ring.tres` (accessory, +2mag, crit, 400g)
- `resources/equipment/frost_blade.tres` (weapon, +4str/+2mag, 400g)
- `resources/stages/piata_basement.tres` (first continuous stage definition)

### Model Assets

- `assets/models/characters/alys/` — Alys character model (Mixamo FBX animations)
- `assets/models/characters/kenney/` — Kenney Animated Characters 2 (legacy reference)

## Scenes

| Scene | File | Purpose |
|---|---|---|
| MainMenu | `scenes/ui/main_menu.tscn` | Title screen: New Game, Continue, Quit |
| SplashScreen | `scenes/ui/splash_screen.tscn` | Studio splash screen before title |
| Overworld | `scenes/overworld/overworld.tscn` | Node-based world map navigation |
| Town | `scenes/town/town.tscn` | Town hub: Shop, Inn, NPCs, Leave |
| DungeonRun | `scenes/dungeon/dungeon_run.tscn` | Main dungeon orchestrator |
| TestArena | `scenes/dungeon/rooms/test_arena.tscn` | Dev test arena |
| Room01 | `scenes/dungeon/rooms/room_01.tscn` | Dungeon room 1 |
| Room02 | `scenes/dungeon/rooms/room_02.tscn` | Dungeon room 2 |
| Room03 | `scenes/dungeon/rooms/room_03.tscn` | Dungeon room 3 |
| RoomBoss | `scenes/dungeon/rooms/room_boss.tscn` | Boss room |
| Player | `scenes/characters/player.tscn` | Player character scene |
| EnemyRusher | `scenes/enemies/enemy_rusher.tscn` | Enemy scene |
| HitParticles | `scenes/vfx/hit_particles.tscn` | Hit effect |
| DeathParticles | `scenes/vfx/death_particles.tscn` | Death effect |
| EnemyProjectile | `scenes/projectiles/enemy_projectile.tscn` | Enemy projectile |
| PlayerProjectile | `scenes/projectiles/player_projectile.tscn` | Player technique projectile |
| HUD | `scenes/ui/hud.tscn` | In-game HUD overlay (HP, TP, Gold, Combo) |
| VictoryScreen | `scenes/ui/victory_screen.tscn` | Dungeon victory screen (XP/gold rewards) |
| DefeatScreen | `scenes/ui/defeat_screen.tscn` | Dungeon defeat screen |
| PartyScreen | `scripts/ui/party_screen.gd` | Party/equipment screen (code-only CanvasLayer) |
| StageChunk_Start | `scenes/dungeon/chunks/chunk_start.tscn` | Stage start chunk |
| StageChunk_StreetA | `scenes/dungeon/chunks/chunk_street_a.tscn` | Street variant A chunk |
| StageChunk_StreetB | `scenes/dungeon/chunks/chunk_street_b.tscn` | Street variant B chunk |
| StageChunk_PlazaA | `scenes/dungeon/chunks/chunk_plaza_a.tscn` | Plaza variant A chunk |
| StageChunk_PlazaB | `scenes/dungeon/chunks/chunk_plaza_b.tscn` | Plaza variant B chunk |
| StageChunk_Boss | `scenes/dungeon/chunks/chunk_boss.tscn` | Boss arena chunk |

## Tests

| Suite | File | Count |
|---|---|---|
| TestStateMachine | `tests/unit/systems/test_state_machine.gd` | 11 |
| TestEncounterRoller | `tests/unit/systems/test_encounter_roller.gd` | 7 |
| TestSaveSerialization | `tests/unit/systems/test_save_serialization.gd` | 7 |
| TestHealthComponent | `tests/unit/components/test_health_component.gd` | 17 |
| TestComboTracker | `tests/unit/components/test_combo_tracker.gd` | 11 |
| TestDamageCalculator | `tests/unit/components/test_damage_calculator.gd` | 11 |
| TestComboCancelChecker | `tests/unit/components/test_combo_cancel_checker.gd` | 10 |
| TestJuggleTracker | `tests/unit/components/test_juggle_tracker.gd` | 15 |
| TestScoreTracker | `tests/unit/components/test_score_tracker.gd` | 14 |
| TestTPTracker | `tests/unit/components/test_tp_tracker.gd` | 14 |
| TestStoryFlagManager | `tests/unit/components/test_story_flag_manager.gd` | 13 |
| TestShopTransaction | `tests/unit/components/test_shop_transaction.gd` | 12 |
| TestGoldTracker | `tests/unit/components/test_gold_tracker.gd` | 13 |
| TestInputIntentBuffer | `tests/unit/components/test_input_intent_buffer.gd` | 21 |
| TestXPTracker | `tests/unit/components/test_xp_tracker.gd` | 13 |
| TestStatCalculator | `tests/unit/components/test_stat_calculator.gd` | 10 |
| TestEquipmentManager | `tests/unit/components/test_equipment_manager.gd` | 15 |
| TestSkillTreeManager | `tests/unit/components/test_skill_tree_manager.gd` | 12 |
| TestElementCalculator | `tests/unit/components/test_element_calculator.gd` | 11 |
| TestStatusEffectTracker | `tests/unit/components/test_status_effect_tracker.gd` | 13 |
| TestDropRoller | `tests/unit/components/test_drop_roller.gd` | 6 |
| TestSaveHardening | `tests/unit/systems/test_save_hardening.gd` | 19 |
| TestInputRemapping | `tests/unit/systems/test_input_remapping.gd` | 8 |

Total test functions: 283

## Controls

### Dungeon / Combat
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
| Q | Switch character (prev) |
| E | Switch character (next) |
| Tab | Cycle technique |

### Menus / Overworld / Town
| Input | Action |
|---|---|
| Arrow keys / D-pad | Navigate |
| A / Enter | Confirm / Enter node |
| B / ESC | Back / Leave |
| Start / ESC | Pause menu |
| Select | Save menu (overworld) |

## Game Flow

```
Main Menu → [New Game] → Overworld Map → Town (shop/inn/NPCs) or Dungeon
                                            ↑                        ↓
                                            ← ← ← ← ← ← ← ← ← ← ←
                                       (victory/defeat return to overworld)
```

- Dungeon completion sets story flags, banks gold, auto-saves
- Town exit auto-saves
- Story flags unlock new overworld nodes
