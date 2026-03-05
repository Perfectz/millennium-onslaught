## Manages HP, damage intake, healing, and death detection.
class_name HealthComponent
extends Node


signal health_changed(new_hp: float, max_hp: float)
signal died()

var _current_hp: float = 0.0
var _max_hp: float = 0.0
var _is_dead: bool = false


## Initialize health with a maximum value.
func setup(max_hp: float) -> void:
	_max_hp = max_hp
	_current_hp = max_hp
	_is_dead = false


## Apply damage and return actual damage dealt.
func take_damage(amount: float) -> float:
	if _is_dead:
		return 0.0
	if amount <= 0.0:
		return 0.0
	var actual: float = minf(amount, _current_hp)
	_current_hp = maxf(0.0, _current_hp - actual)
	health_changed.emit(_current_hp, _max_hp)
	if _current_hp <= 0.0:
		_is_dead = true
		died.emit()
	return actual


## Heal and return actual amount healed.
func heal(amount: float) -> float:
	if _is_dead:
		return 0.0
	if amount <= 0.0:
		return 0.0
	var space: float = _max_hp - _current_hp
	var actual: float = minf(amount, space)
	_current_hp += actual
	health_changed.emit(_current_hp, _max_hp)
	return actual


## Get current HP.
func get_current_hp() -> float:
	return _current_hp


## Get maximum HP.
func get_max_hp() -> float:
	return _max_hp


## Check if dead.
func is_dead() -> bool:
	return _is_dead


## Get HP as a 0.0-1.0 ratio.
func get_hp_ratio() -> float:
	if _max_hp <= 0.0:
		return 0.0
	return _current_hp / _max_hp


## Reset to full health (for revive).
func revive() -> void:
	_current_hp = _max_hp
	_is_dead = false
	health_changed.emit(_current_hp, _max_hp)
