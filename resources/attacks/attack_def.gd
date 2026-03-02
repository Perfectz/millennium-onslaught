class_name AttackDef
extends Resource


@export var attack_name: StringName = &""
@export var base_damage: float = 10.0
@export var damage_multiplier: float = 1.0
@export var knockback_force: float = 3.0
@export var knockback_direction: Vector3 = Vector3(1, 0.2, 0)
@export var hitstop_duration: float = 0.05
@export var windup_time: float = 0.0
@export var active_time: float = 0.1
@export var recovery_time: float = 0.2

## Cancel windows — defines when during this attack other actions can be input.
## cancel_window_start/end are relative to total attack duration (windup + active + recovery).
## 0.0 = start of attack, 1.0 = end of attack.
@export var cancel_window_start: float = 0.5
@export var cancel_window_end: float = 0.9

## What actions can cancel this attack during the cancel window.
## Valid values: "light", "heavy", "dodge", "technique", "jump"
@export var cancel_into: Array[StringName] = [&"dodge"]

## Whether this attack can launch enemies airborne.
@export var is_launcher: bool = false
@export var launch_velocity: float = 0.0
