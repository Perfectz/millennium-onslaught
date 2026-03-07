# Combat Event Contracts

> **Purpose:** Canonical typed payload contracts for combat events that cross multiple systems.

**Scope:** `combat_hit_event`, `combat_kill_event`  
**Source Files:** `scripts/contracts/combat_hit_event.gd`, `scripts/contracts/combat_kill_event.gd`

---

## Migration Rule

- New listeners should prefer the typed signals in `EventBus`.
- Legacy positional signals remain available for backward compatibility.
- New combat metadata should be added to the typed payloads first.

---

## `combat_hit_event`

**Signal:** `EventBus.combat_hit_event(event: CombatHitEvent)`

| Field | Type | Value |
|---|---|---|
| `schema_version` | `int` | `1` |
| `attacker` | `Node` | Hit source |
| `target` | `Node` | Hit target |
| `damage` | `float` | Resolved damage applied to health |
| `hit_position` | `Vector3` | Impact position used by VFX/HUD |
| `attack_data` | `AttackDef` | Attack definition used to resolve the hit |

---

## `combat_kill_event`

**Signal:** `EventBus.combat_kill_event(event: CombatKillEvent)`

| Field | Type | Value |
|---|---|---|
| `schema_version` | `int` | `1` |
| `attacker` | `Node` | Killing source |
| `target` | `Node` | Entity that died |
| `kill_position` | `Vector3` | Position used for death VFX/juice |
| `damage` | `float` | Final hit damage that caused the kill |
| `attack_data` | `AttackDef` | Attack definition that caused the kill |

---

## Notes

- These payloads are `RefCounted`, not `Resource`, because they are runtime-only contracts.
- Schema version is embedded in the payload so future migrations can stay additive.
- `combat_hit_landed` and `combat_kill` still exist, but they are compatibility signals now.
