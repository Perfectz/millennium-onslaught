# Event Catalog

> **Purpose:** Complete listing of all EventBus signals. Name, payload, who emits, who listens. Updated every MVP.

**Last Updated:** 2026-03-01 (MVP 0 — Initial catalog)

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
| `combat_hit_landed` | `attacker: Node, target: Node, damage: float, hit_position: Vector3` | Combat system | VFX, Audio, Camera, HUD |
| `combat_kill` | `attacker: Node, target: Node, kill_position: Vector3` | Combat system | VFX, Audio, Score, Drops |
| `combat_combo_step` | `player: Node, step: int` | Combo system | HUD, Audio |
| `combat_combo_dropped` | `player: Node` | Combo system | HUD |
| `combat_dodge` | `player: Node` | Player controller | Audio, VFX |
| `combat_block` | `player: Node` | Player controller | Audio, VFX |
| `combat_parry` | `player: Node, attacker: Node` | Combat system | Audio, VFX, Camera |
| `combat_technique_used` | `player: Node, technique_name: StringName, cost: float` | Technique system | HUD, Audio, VFX |

## Juggle Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `combat_juggle_launched` | `target: Node, launcher: Node` | Combat system | VFX, Audio |
| `combat_juggle_hit` | `target: Node, hit_count: int` | Combat system | HUD |
| `combat_juggle_limit_reached` | `target: Node` | Combat system | VFX |

## Player Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `player_health_changed` | `player_index: int, new_hp: float, max_hp: float` | Health component | HUD |
| `player_tp_changed` | `player_index: int, new_tp: float, max_tp: float` | TP component | HUD |
| `player_died` | `player_index: int` | Health component | GameManager, Co-op |
| `player_revived` | `player_index: int` | Revive system | HUD, VFX |

## Enemy Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `enemy_spawned` | `enemy: Node, enemy_type: StringName` | Wave system | AI, HUD |
| `enemy_died` | `enemy: Node, enemy_type: StringName, position: Vector3` | Health component | Wave system, Drops, Score |
| `enemy_wave_cleared` | *none* | Wave system | Camera, Dungeon |

## Dungeon Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `dungeon_entered` | `dungeon_id: StringName` | GameManager | Dungeon manager, Music |
| `dungeon_room_entered` | `room_index: int` | Dungeon manager | Camera, Wave system |
| `dungeon_room_cleared` | `room_index: int` | Wave system | Dungeon manager |
| `dungeon_boss_phase_changed` | `boss: Node, phase: int` | Boss AI | Music, VFX, Camera |
| `dungeon_completed` | `dungeon_id: StringName` | Dungeon manager | GameState, GameManager |
| `dungeon_failed` | *none* | GameManager | GameState, UI |

## Overworld Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `overworld_node_selected` | `node_id: StringName` | Overworld input | UI |
| `overworld_node_entered` | `node_id: StringName` | Overworld controller | GameManager |
| `overworld_node_unlocked` | `node_id: StringName` | Story flag system | Overworld map |

## Town Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `town_entered` | `town_id: StringName` | GameManager | Town UI |
| `town_shop_purchase` | `item_id: StringName, cost: int` | Shop system | GameState, Audio |
| `town_shop_sell` | `item_id: StringName, price: int` | Shop system | GameState, Audio |
| `town_inn_used` | `cost: int` | Inn system | GameState, Audio |
| `town_exited` | *none* | Town UI | GameManager |

## RPG Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `rpg_xp_gained` | `player_index: int, amount: int` | Kill handler | HUD, Level system |
| `rpg_level_up` | `player_index: int, new_level: int` | Level system | HUD, VFX, Audio |
| `rpg_stat_allocated` | `player_index: int, stat_name: StringName, new_value: int` | Stat UI | GameState |
| `rpg_equipment_changed` | `player_index: int, slot: StringName, item_id: StringName` | Equipment UI | GameState, Combat |
| `rpg_gold_changed` | `new_total: int` | GameState | HUD |
| `rpg_skill_unlocked` | `player_index: int, skill_id: StringName` | Skill tree UI | GameState |

## Save/Load Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `save_completed` | `slot: int` | SaveManager | UI |
| `save_failed` | `slot: int, error: String` | SaveManager | UI |
| `load_completed` | `slot: int` | SaveManager | UI, GameManager |
| `load_failed` | `slot: int, error: String` | SaveManager | UI |

## Scene Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `scene_transition_started` | `target_scene: String` | GameManager | UI (fade) |
| `scene_transition_completed` | `target_scene: String` | GameManager | All systems |

## Audio Events

| Signal | Payload | Emitter | Listeners |
|--------|---------|---------|-----------|
| `audio_sfx_requested` | `sfx_name: StringName` | Any system | AudioManager |
| `audio_music_requested` | `music_name: StringName, crossfade: bool` | GameManager | AudioManager |
| `audio_mute_toggled` | `muted: bool` | InputManager / UI | AudioManager, HUD |

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
