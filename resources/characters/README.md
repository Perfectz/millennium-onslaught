# resources/characters/

## Purpose
CharacterDef resources defining playable characters — identity, base stats, combo chains, techniques, skill trees, and model references.

## Schema
See `docs/schemas/character_def.md` for full field documentation.

## Current Contents

| File | ID | Role | Description |
|------|----|------|-------------|
| `character_def.gd` | — | — | CharacterDef class definition |
| `alys.tres` | alys | Hunter | Balanced, fast slashing combo, fire/dark techniques, high agility |
| `chaz.tres` | chaz | Warrior | Heavy sword strikes, lightning/ice techniques, high strength |
| `rune.tres` | rune | Mage | Staff swipes, fire AoE/ice/lightning techniques, high magic |
| `wren.tres` | wren | Android | Mechanical punches, fire/lightning techniques, high defense |

## Design Notes
- Each character references AttackDefs for their combo chain (3 light + heavy + launcher).
- Each character references TechniqueDefs for their special moves (2-3 per character).
- `skill_tree_id` links to a SkillTreeDef in `resources/skills/`.
- `Constants.CHARACTER_DEFS` maps character_id → resource path for runtime loading.
- `GameState.init_character()` uses base_stats from CharacterDef when available.

## AI Coding Guidance
- Keep files data-centric; runtime behavior belongs in `scripts/`.
- Use stable IDs/paths because systems load these resources by reference.
- When adding a new character: create .tres, add to Constants.CHARACTER_DEFS, add attack .tres files, add technique .tres files.

## Maintenance
- Update this README when adding or removing characters.
