# CharacterDef Schema

> Defines a playable character: identity, base stats, combo chain, techniques, skill tree, and model info.

**Class:** `CharacterDef` (extends `Resource`)
**Source:** `resources/characters/character_def.gd`
**Location:** `resources/characters/*.tres`

---

## Fields

| Field | Type | Default | Constraints | Description |
|-------|------|---------|-------------|-------------|
| `character_id` | `StringName` | `&""` | Unique per character | Identifier used in GameState and Constants |
| `display_name` | `String` | `""` | — | Name shown in UI |
| `role` | `String` | `""` | — | Role description (e.g., "Hunter", "Mage") |
| `base_stats` | `Dictionary` | `{str:5, mag:5, def:5, agi:5}` | All keys present | Stats at level 1. Keys: `strength`, `magic`, `defense`, `agility` |
| `combo_chain` | `Array[AttackDef]` | `[]` | Exactly 3 entries | Light attack combo sequence (hit 1, 2, 3) |
| `heavy_attack` | `AttackDef` | `null` | — | Heavy attack data. Falls back to default if null |
| `launcher_attack` | `AttackDef` | `null` | — | Launcher attack data. Falls back to default if null |
| `techniques` | `Array[TechniqueDef]` | `[]` | — | Special moves this character can learn |
| `skill_tree_id` | `StringName` | `&""` | Matches a SkillTreeDef.tree_id | Reference to character's skill tree |
| `model_base_path` | `String` | `""` | Valid .glb/.fbx path | Path to 3D model |
| `model_skin_path` | `String` | `""` | — | Path to skin/texture |
| `model_scale` | `Vector3` | `(1, 1, 1)` | > 0 per axis | Model scale override |
| `model_offset` | `Vector3` | `(0, 0, 0)` | — | Position offset for model alignment |
| `model_rotation_y` | `float` | `90.0` | Degrees | Y-axis rotation for facing correction |
| `model_animations` | `Dictionary` | `{}` | — | Animation name overrides (key: action, value: anim name) |
| `tint_color` | `Color` | `WHITE` | — | Placeholder model tint color |

---

## Example: alys.tres

```tres
character_id = &"alys"
display_name = "Alys Brangwin"
role = "Hunter"
base_stats = { "strength": 6, "magic": 4, "defense": 5, "agility": 7 }
combo_chain = [light_1_alys, light_2_alys, light_3_alys]
heavy_attack = heavy_alys
launcher_attack = launcher_alys
techniques = [vortex, shadow_blade]
skill_tree_id = &"alys_tree"
tint_color = Color(0.7, 0.5, 1.0)
```

---

## Usage

- `GameState.init_character()` loads base_stats from CharacterDef via `Constants.CHARACTER_DEFS`.
- `PlayerController.configure(def)` applies the full CharacterDef to a player.
- Attack states read `combo_chain`, `heavy_attack`, `launcher_attack` with fallbacks to default preloads.
- `player_state_technique.gd` reads `techniques` array for available special moves.
- `Constants.CHARACTER_DEFS` maps character_id → resource path for runtime loading.

## Current Data Files

| File | ID | Role | STR/MAG/DEF/AGI | Techniques |
|------|----|------|------------------|------------|
| `alys.tres` | alys | Hunter | 6/4/5/7 | Vortex (fire), Shadow Blade (dark) |
| `chaz.tres` | chaz | Warrior | 7/3/6/5 | Rayblade (lightning), Astral (ice) |
| `rune.tres` | rune | Mage | 3/8/4/5 | Flaeli (fire AoE), Hewn (ice), Tandle (lightning) |
| `wren.tres` | wren | Android | 5/2/8/4 | Burst Rocket (fire), Spark (lightning) |
