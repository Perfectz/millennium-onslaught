# resources/techniques/

## Purpose
TechniqueDef resources defining character special moves — TP cost, elemental damage, status effects, projectile behavior, and visual properties.

## Schema
See `docs/schemas/technique_def.md` for full field documentation.

## Current Contents

| File | ID | Character | Element | TP Cost | Damage |
|------|----|-----------|---------|---------|--------|
| `technique_def.gd` | — | — | — | — | — |
| `vortex.tres` | vortex | Alys | fire | 25 | 22 |
| `shadow_blade.tres` | shadow_blade | Alys | dark | 30 | 25 |
| `rayblade.tres` | rayblade | Chaz | lightning | 25 | 20 |
| `astral.tres` | astral | Chaz | ice | 30 | 24 |
| `flaeli.tres` | flaeli | Rune | fire (AoE) | 35 | 28 |
| `hewn.tres` | hewn | Rune | ice | 25 | 22 |
| `tandle.tres` | tandle | Rune | lightning | 30 | 26 |
| `burst_rocket.tres` | burst_rocket | Wren | fire | 20 | 18 |
| `spark.tres` | spark | Wren | lightning | 25 | 20 |

## Element → Status Effect Mapping
- **fire** → Burn (DOT)
- **ice** → Freeze (speed reduction)
- **lightning** → Shock (reserved)
- **dark** → Bleed (increased damage taken)

## Design Notes
- Techniques are referenced by CharacterDef.techniques arrays.
- `player_state_technique.gd` builds an AttackDef from TechniqueDef fields at runtime.
- Players cycle through learned techniques with Tab/Y input.
- `scales_with_magic` determines whether magic or strength stat applies.

## AI Coding Guidance
- Keep files data-centric; runtime behavior belongs in `scripts/`.
- When adding a technique: create .tres, add to the character's CharacterDef.techniques array.
- Ensure `element_type` matches a valid ElementCalculator element.

## Maintenance
- Update this README when adding or removing techniques.
