## Typed event payload contracts for EventBus signals.
## Replaces loose parameters with structured, validated data objects.
class_name EventContracts
extends RefCounted


## Base contract that all events inherit from.
class BaseEvent extends RefCounted:
	## Timestamp when the event was created.
	var timestamp: int = 0

	func _init() -> void:
		timestamp = Time.get_ticks_msec()

	## Validate that all required fields are set. Override in subclass.
	func is_valid() -> bool:
		return true

	## Convert to dictionary for logging.
	func to_dict() -> Dictionary:
		return {"timestamp": timestamp}


## Hit landed event — emitted when an attack connects.
class HitEvent extends BaseEvent:
	var attacker: Node = null
	var target: Node = null
	var damage: float = 0.0
	var hit_position: Vector3 = Vector3.ZERO
	var is_critical: bool = false
	var element: StringName = &"physical"

	func is_valid() -> bool:
		return attacker != null and target != null and damage > 0.0

	func to_dict() -> Dictionary:
		var d: Dictionary = super.to_dict()
		d["damage"] = damage
		d["is_critical"] = is_critical
		d["element"] = element
		return d


## Kill event — emitted when a target dies from damage.
class KillEvent extends BaseEvent:
	var attacker: Node = null
	var target: Node = null
	var kill_position: Vector3 = Vector3.ZERO
	var target_type: StringName = &""
	var xp_value: int = 0

	func is_valid() -> bool:
		return attacker != null and target != null

	func to_dict() -> Dictionary:
		var d: Dictionary = super.to_dict()
		d["target_type"] = target_type
		d["xp_value"] = xp_value
		return d


## Spawn event — emitted when an enemy spawns.
class SpawnEvent extends BaseEvent:
	var enemy: Node = null
	var enemy_type: StringName = &""
	var spawn_position: Vector3 = Vector3.ZERO
	var wave_index: int = 0

	func is_valid() -> bool:
		return enemy != null and enemy_type != &""

	func to_dict() -> Dictionary:
		var d: Dictionary = super.to_dict()
		d["enemy_type"] = enemy_type
		d["wave_index"] = wave_index
		return d


## Damage event — internal damage calculation result.
class DamageEvent extends BaseEvent:
	var base_damage: float = 0.0
	var final_damage: float = 0.0
	var attacker_strength: int = 0
	var target_defense: int = 0
	var element: StringName = &"physical"
	var is_critical: bool = false
	var critical_multiplier: float = 1.5

	func is_valid() -> bool:
		return base_damage > 0.0 and final_damage >= 0.0

	func to_dict() -> Dictionary:
		var d: Dictionary = super.to_dict()
		d["base_damage"] = base_damage
		d["final_damage"] = final_damage
		d["element"] = element
		d["is_critical"] = is_critical
		return d


## Phase change event — emitted on game phase transitions.
class PhaseChangeEvent extends BaseEvent:
	var new_phase: StringName = &""
	var old_phase: StringName = &""

	func is_valid() -> bool:
		return new_phase != &""

	func to_dict() -> Dictionary:
		var d: Dictionary = super.to_dict()
		d["new_phase"] = new_phase
		d["old_phase"] = old_phase
		return d


## Combo event — emitted on combo step changes.
class ComboEvent extends BaseEvent:
	var player: Node = null
	var step: int = 0
	var is_finisher: bool = false

	func is_valid() -> bool:
		return player != null and step > 0

	func to_dict() -> Dictionary:
		var d: Dictionary = super.to_dict()
		d["step"] = step
		d["is_finisher"] = is_finisher
		return d


## Health change event — emitted when HP changes.
class HealthChangeEvent extends BaseEvent:
	var player_index: int = 0
	var new_hp: float = 0.0
	var max_hp: float = 0.0
	var change_amount: float = 0.0
	var source: StringName = &""  # "damage", "heal", "revive"

	func is_valid() -> bool:
		return max_hp > 0.0

	func to_dict() -> Dictionary:
		var d: Dictionary = super.to_dict()
		d["player_index"] = player_index
		d["new_hp"] = new_hp
		d["max_hp"] = max_hp
		d["source"] = source
		return d


## Wave event — emitted on wave state changes.
class WaveEvent extends BaseEvent:
	var wave_index: int = 0
	var enemy_count: int = 0
	var is_final_wave: bool = false

	func is_valid() -> bool:
		return wave_index >= 0

	func to_dict() -> Dictionary:
		var d: Dictionary = super.to_dict()
		d["wave_index"] = wave_index
		d["enemy_count"] = enemy_count
		d["is_final_wave"] = is_final_wave
		return d


## Save/Load event.
class SaveEvent extends BaseEvent:
	var slot: int = 0
	var success: bool = false
	var error_message: String = ""

	func is_valid() -> bool:
		return slot >= 0

	func to_dict() -> Dictionary:
		var d: Dictionary = super.to_dict()
		d["slot"] = slot
		d["success"] = success
		if error_message != "":
			d["error"] = error_message
		return d


## Gold change event.
class GoldEvent extends BaseEvent:
	var new_total: int = 0
	var change_amount: int = 0
	var source: StringName = &""  # "enemy_drop", "shop_sell", "shop_buy"

	func is_valid() -> bool:
		return true

	func to_dict() -> Dictionary:
		var d: Dictionary = super.to_dict()
		d["new_total"] = new_total
		d["change_amount"] = change_amount
		d["source"] = source
		return d


## XP gain event.
class XPEvent extends BaseEvent:
	var player_index: int = 0
	var amount: int = 0
	var source_type: StringName = &""

	func is_valid() -> bool:
		return amount > 0

	func to_dict() -> Dictionary:
		var d: Dictionary = super.to_dict()
		d["player_index"] = player_index
		d["amount"] = amount
		d["source_type"] = source_type
		return d
