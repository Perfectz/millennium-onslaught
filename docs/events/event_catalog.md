# Event Catalog

> **Purpose:** Complete listing of EventBus signals, payloads, typical emitters, and typical listeners.

**Last Verified Against:** `autoloads/event_bus.gd` on 2026-03-03 (MVP 6 Together)

---

## Lifecycle Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `game_phase_changed` | `new_phase: StringName, old_phase: StringName` | GameManager | All systems (context switch) |
| `game_paused` | *none* | GameManager | UI, AudioManager |
| `game_resumed` | *none* | GameManager | UI, AudioManager |
| `game_restarted` | *none* | GameManager | All systems (reset state) |

## Combat Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `combat_hit_landed` | `attacker: Node, target: Node, damage: float, hit_position: Vector3` | Combat system | VFX, Audio, Camera, HUD, JuiceManager, DamageNumberSpawner |
| `combat_kill` | `attacker: Node, target: Node, kill_position: Vector3` | Combat system | VFX, Audio, Score, Drops, JuiceManager |
| `combat_combo_step` | `player: Node, step: int` | PlayerController (bridged from ComboTracker) | HUD, Audio |
| `combat_combo_dropped` | `player: Node` | PlayerController (bridged from ComboTracker) | HUD |
| `combat_dodge` | `player: Node` | Player controller | Audio, VFX |
| `combat_block` | `player: Node` | Player controller | Audio, VFX |
| `combat_parry` | `player: Node, attacker: Node` | Combat system | Audio, VFX, Camera |
| `combat_technique_used` | `player: Node, technique_name: StringName, cost: float` | Technique system | HUD, Audio, VFX |
| `combat_attack_started` | `attacker: Node, attack_type: StringName` | Player attack states | CombatAudio (whiff SFX) |

## Juggle Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `combat_juggle_launched` | `target: Node, launcher: Node` | Combat system | VFX, Audio |
| `combat_juggle_hit` | `target: Node, hit_count: int` | Combat system | HUD |
| `combat_juggle_limit_reached` | `target: Node` | Combat system | VFX |

## Player Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `player_health_changed` | `player_index: int, new_hp: float, max_hp: float` | PlayerController (bridged from HealthComponent) | HUD, JuiceManager |
| `player_tp_changed` | `player_index: int, new_tp: float, max_tp: float` | TP component | HUD |
| `player_died` | `player_index: int` | PlayerController (bridged from HealthComponent) | GameManager, Co-op |
| `player_revived` | `player_index: int` | Revive system | HUD, VFX |

## Enemy Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `enemy_spawned` | `enemy: Node, enemy_type: StringName` | Wave system | AI, HUD |
| `enemy_died` | `enemy: Node, enemy_type: StringName, position: Vector3` | Health component | Wave system, Drops, Score |
| `enemy_wave_cleared` | *none* | Wave system | Camera, Dungeon |

## Encounter Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|----------|
| `encounter_arena_locked` | `min_x: float, max_x: float, min_z: float, max_z: float` | WaveSystem | CameraFollow |
| `encounter_arena_unlocked` | *none* | WaveSystem | CameraFollow |

## Camera Director Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|----------|
| `camera_director_cue` | `target_position: Vector3, hold_time: float` | Boss AI, set-pieces | CameraFollow |
| `camera_director_return` | *none* | Boss AI, set-pieces | CameraFollow |

## Dungeon Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `dungeon_entered` | `dungeon_id: StringName` | GameManager | Dungeon manager, Music |
| `dungeon_room_entered` | `room_index: int` | Dungeon manager | Camera, Wave system |
| `dungeon_room_cleared` | `room_index: int` | Wave system | Dungeon manager, ToastSystem |
| `dungeon_boss_phase_changed` | `boss: Node, phase: int` | Boss AI | Music, VFX, Camera |
| `dungeon_completed` | `dungeon_id: StringName` | Dungeon manager | GameState, GameManager |
| `dungeon_failed` | *none* | GameManager | GameState, UI |

## Overworld Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `overworld_node_selected` | `node_id: StringName` | Overworld input | UI |
| `overworld_node_entered` | `node_id: StringName` | OverworldController | GameManager |
| `overworld_node_unlocked` | `node_id: StringName` | Story flag system | Overworld map |

## Town Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `town_entered` | `town_id: StringName` | TownController | Audio |
| `town_shop_purchase` | `item_id: StringName, cost: int` | TownController (shop) | Audio |
| `town_shop_sell` | `item_id: StringName, price: int` | TownController (shop) | Audio |
| `town_inn_used` | `cost: int` | TownController (inn) | Audio |
| `town_exited` | *none* | TownController | SaveManager (auto-save) |

## RPG Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `rpg_xp_gained` | `player_index: int, amount: int` | DungeonManager | HUD, Level system |
| `rpg_level_up` | `player_index: int, new_level: int` | XPTracker (via PlayerController) | HUD, VFX, Audio, ToastSystem |
| `rpg_stat_allocated` | `player_index: int, stat_name: StringName, new_value: int` | Stat allocation UI | GameState |
| `rpg_stat_points_available` | `player_index: int, points: int` | XPTracker (via PlayerController) | Stat allocation UI |
| `rpg_equipment_changed` | `player_index: int, slot: StringName, item_id: StringName` | EquipmentManager (via UI) | GameState, Combat |
| `rpg_gold_changed` | `new_total: int` | DungeonManager, TownController | HUD (gold label), ToastSystem |
| `rpg_skill_unlocked` | `player_index: int, skill_id: StringName` | SkillTreeManager (via UI) | GameState |
| `rpg_technique_learned` | `player_index: int, technique_id: StringName` | Level system | HUD, ToastSystem |
| `rpg_character_switched` | `old_character: StringName, new_character: StringName` | DungeonRun | HUD, Audio |
| `rpg_status_effect_applied` | `target: Node, effect_type: StringName, duration: float` | CombatSystem | VFX, HUD (status icons) |
| `rpg_status_effect_expired` | `target: Node, effect_type: StringName` | StatusEffectTracker (via PlayerController/EnemyController) | VFX, HUD |
| `rpg_item_dropped` | `position: Vector3, item_id: StringName` | DungeonManager (via DropRoller) | VFX, Pickup system |
| `rpg_item_picked_up` | `item_id: StringName` | Pickup system | HUD, ToastSystem |

## Stage Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `stage_encounter_triggered` | `encounter_index: int` | EncounterTrigger | StageRunner, WaveSystem |
| `stage_encounter_cleared` | `encounter_index: int` | WaveSystem | StageRunner |
| `stage_completed` | `stage_id: StringName` | StageRunner | GameManager, GameState |
| `stage_bounds_updated` | `min_x: float, max_x: float` | StageRunner | CameraFollow, PlayerController |

## Save/Load Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `save_completed` | `slot: int` | SaveManager | UI, ToastSystem |
| `save_failed` | `slot: int, error: String` | SaveManager | UI |
| `load_completed` | `slot: int` | SaveManager | UI, GameManager |
| `load_failed` | `slot: int, error: String` | SaveManager | UI |

## Scene Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `scene_transition_started` | `target_scene: String` | SceneTransitioner | UI (fade) |
| `scene_transition_completed` | `target_scene: String` | SceneTransitioner | All systems |

## Audio Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `audio_sfx_requested` | `sfx_name: StringName` | Any system | AudioManager |
| `audio_music_requested` | `music_name: StringName, crossfade: bool` | GameManager | AudioManager |
| `audio_mute_toggled` | `muted: bool` | InputManager / UI | AudioManager, HUD |
| `audio_track_changed` | `track_id: StringName, display_name: String` | AudioManager | HUD (toast display) |

## UI Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `ui_hud_update_requested` | *none* | Any system | HUD |
| `ui_menu_opened` | `menu_name: StringName` | UI system | InputManager |
| `ui_menu_closed` | `menu_name: StringName` | UI system | InputManager |

## Input Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `input_device_connected` | `device_id: int` | InputManager | UI |
| `input_device_disconnected` | `device_id: int` | InputManager | UI |
| `input_context_changed` | `new_context: StringName` | InputManager | All input consumers |
| `input_touch_visibility_changed` | `should_show: bool` | InputManager | TouchControls |

## Settings Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `settings_display_changed` | `setting: StringName, value: Variant` | SettingsMenu | GameState, HUD |
| `settings_controls_remapped` | `action: StringName, input_type: StringName` | ControllerSettings | UI |

