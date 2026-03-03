## Gold currency tracker. Manages gold balance with add/spend operations.
class_name GoldTracker
extends RefCounted


signal gold_changed(new_total: int)

var _gold: int = 0


## Get current gold balance.
func get_gold() -> int:
	return _gold


## Add gold. Ignores non-positive values.
func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	_gold += amount
	gold_changed.emit(_gold)


## Spend gold. Returns true if successful, false if insufficient.
func spend_gold(amount: int) -> bool:
	if amount <= 0 or _gold < amount:
		return false
	_gold -= amount
	gold_changed.emit(_gold)
	return true


## Check if player can afford a cost.
func can_afford(cost: int) -> bool:
	return _gold >= cost


## Set gold to a specific value (for loading save data).
func set_gold(amount: int) -> void:
	_gold = amount
	gold_changed.emit(_gold)
