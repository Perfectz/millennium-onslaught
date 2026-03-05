# AttackDef Schema

> **Purpose:** Defines an attack's damage, knockback, element, and timing properties.

## Fields

| Field | Type | Required | Range | Description |
|-------|------|----------|-------|-------------|
| `id` | StringName | Yes | min 1 char | Unique attack identifier |
| `base_damage` | float | Yes | >= 0.0 | Raw damage before modifiers |
| `knockback` | float | Yes | >= 0.0 | Base knockback force |
| `element` | StringName | No | physical, fire, ice, lightning, dark | Damage element (default: physical) |
| `hitstop_duration` | float | No | 0.0 – 1.0 | Override hitstop duration |

## Example

```json
{
  "id": "light_1",
  "base_damage": 10.0,
  "knockback": 3.0,
  "element": "physical",
  "hitstop_duration": 0.05
}
```
