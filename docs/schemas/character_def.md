# CharacterDef Schema

> **Purpose:** Defines a playable character's base stats, combo chain, and techniques.

## Fields

| Field | Type | Required | Range | Description |
|-------|------|----------|-------|-------------|
| `id` | StringName | Yes | min 1 char | Unique character identifier |
| `display_name` | String | Yes | min 1 char | Name shown in UI |
| `base_hp` | float | Yes | 1.0 – 9999.0 | Starting maximum HP |
| `base_strength` | int | Yes | 1 – 99 | Base strength stat |
| `base_defense` | int | Yes | 1 – 99 | Base defense stat |
| `base_agility` | int | Yes | 1 – 99 | Base agility stat |
| `base_magic` | int | Yes | 1 – 99 | Base magic stat |
| `combo_chain` | Array[StringName] | Yes | — | Ordered list of AttackDef IDs for light combo |
| `techniques` | Array[StringName] | Yes | — | List of learnable technique IDs |

## Example

```json
{
  "id": "chaz",
  "display_name": "Chaz",
  "base_hp": 120.0,
  "base_strength": 8,
  "base_defense": 6,
  "base_agility": 7,
  "base_magic": 5,
  "combo_chain": ["light_1", "light_2", "light_3"],
  "techniques": ["fireslash", "crosscut"]
}
```
