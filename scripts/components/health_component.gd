## Pure logic HP management. No scene tree dependency — fully testable.
## Manages current/max HP, emits signals on change and death.
class_name HealthComponent
extends RefCounted


signal health_changed(new_hp: float, max_hp: float)
signal died()

var _max_hp: float
var _current_hp: float
var _is_dead: bool = false


func _init(max_hp: float = 100.0) -> void:
	_max_hp = max_hp
	_current_hp = max_hp


## Apply damage. Clamps to zero. Emits health_changed and died if appropriate.
func take_damage(amount: float) -> void:
	if _is_dead:
		return
	if amount <= 0.0:
		return
	_current_hp = maxf(_current_hp - amount, 0.0)
	health_changed.emit(_current_hp, _max_hp)
	if _current_hp <= 0.0:
		_is_dead = true
		died.emit()


## Heal by amount. Cannot exceed max HP.
func heal(amount: float) -> void:
	if _is_dead:
		return
	if amount <= 0.0:
		return
	_current_hp = minf(_current_hp + amount, _max_hp)
	health_changed.emit(_current_hp, _max_hp)


## Check if this entity is dead (HP reached zero).
func is_dead() -> bool:
	return _is_dead


## Get current HP.
func get_current_hp() -> float:
	return _current_hp


## Get max HP.
func get_max_hp() -> float:
	return _max_hp


## Set max HP (useful for leveling). Clamps current HP if it exceeds new max.
func set_max_hp(new_max: float) -> void:
	if new_max <= 0.0:
		push_warning("HealthComponent: set_max_hp called with non-positive value.")
		return
	_max_hp = new_max
	if _current_hp > _max_hp:
		_current_hp = _max_hp
		health_changed.emit(_current_hp, _max_hp)


## Reset to full health (for respawning / arena restart).
func reset(max_hp: float = -1.0) -> void:
	if max_hp > 0.0:
		_max_hp = max_hp
	_current_hp = _max_hp
	_is_dead = false
	health_changed.emit(_current_hp, _max_hp)
