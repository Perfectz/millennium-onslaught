# EnemyDef Schema

> **Purpose:** Defines an enemy type's stats, behavior, and rewards.

## Fields

| Field | Type | Required | Range | Description |
|-------|------|----------|-------|-------------|
| `id` | StringName | Yes | min 1 char | Unique enemy identifier |
| `display_name` | String | Yes | min 1 char | Name shown in UI |
| `hp` | float | Yes | 1.0 – 99999.0 | Maximum HP |
| `damage` | float | Yes | >= 0.0 | Base contact/attack damage |
| `speed` | float | Yes | >= 0.0 | Movement speed |
| `xp_reward` | int | Yes | >= 0 | XP granted on kill |
| `ai_type` | StringName | Yes | min 1 char | AI behavior class (rusher, ranger, shielder, boss) |

## Example

```json
{
  "id": "rusher",
  "display_name": "Rusher",
  "hp": 50.0,
  "damage": 10.0,
  "speed": 4.0,
  "xp_reward": 10,
  "ai_type": "rusher"
}
```
