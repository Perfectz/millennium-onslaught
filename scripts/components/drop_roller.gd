## Pure drop table logic. No scene tree dependency — fully testable.
## Rolls item drops from probability-based drop tables.
class_name DropRoller
extends RefCounted


## Roll drops from a drop table. Each entry: {item_id: StringName, chance: float (0.0-1.0)}.
## Each entry is rolled independently.
static func roll_drops(drop_table: Array) -> Array[StringName]:
	var drops: Array[StringName] = []
	for entry: Dictionary in drop_table:
		var chance: float = entry.get("chance", 0.0)
		if chance <= 0.0:
			continue
		if chance >= 1.0 or randf() < chance:
			drops.append(entry["item_id"])
	return drops


## Calculate expected number of drops for a table (sum of all chances).
static func expected_drop_count(drop_table: Array) -> float:
	var total: float = 0.0
	for entry: Dictionary in drop_table:
		total += entry.get("chance", 0.0)
	return total
