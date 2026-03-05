## Orchestrates the full damage pipeline: hit detection → calc → apply → VFX → audio → HUD.
## Event-driven — each step emits events for downstream systems.
class_name DamageFlow
extends Node


func _ready() -> void:
	pass


## Process a hit from hitbox to hurtbox through the full pipeline.
func process_hit(hitbox: HitboxComponent, hurtbox: HurtboxComponent) -> void:
	if hurtbox.is_invincible():
		return
	# Step 1: Get attacker and target stats.
	var attacker: Node = hitbox.get_owner_node()
	var target: Node = hurtbox.get_owner_node()
	if attacker == null or target == null:
		return
	var base_damage: float = hitbox.get_damage()
	var attacker_str: int = _get_stat(attacker, &"strength")
	var target_def: int = _get_stat(target, &"defense")
	var attacker_agi: int = _get_stat(attacker, &"agility")
	var element: StringName = _get_element(hitbox)
	var target_element: StringName = _get_element_weakness(target)
	# Step 2: Calculate damage.
	var is_crit: bool = CombatService.roll_critical(attacker_agi)
	var final_damage: float = CombatService.calculate_damage(
		base_damage, attacker_str, target_def, element, target_element, is_crit
	)
	# Step 3: Create damage event contract.
	var dmg_event := EventContracts.DamageEvent.new()
	dmg_event.base_damage = base_damage
	dmg_event.final_damage = final_damage
	dmg_event.attacker_strength = attacker_str
	dmg_event.target_defense = target_def
	dmg_event.element = element
	dmg_event.is_critical = is_crit
	# Step 4: Apply damage to target.
	var applied: bool = hurtbox.receive_hit(hitbox)
	if not applied:
		return
	# Step 5: Create and emit hit event.
	var hit_event := EventContracts.HitEvent.new()
	hit_event.attacker = attacker
	hit_event.target = target
	hit_event.damage = final_damage
	hit_event.hit_position = hurtbox.global_position
	hit_event.is_critical = is_crit
	hit_event.element = element
	# Step 6: Emit through EventBus for VFX, audio, HUD.
	EventBus.combat_hit_landed.emit(
		attacker, target, final_damage, hurtbox.global_position
	)
	EventBus.log_event(&"damage_flow_complete", dmg_event.to_dict())
	# Step 7: Spawn damage number.
	_spawn_damage_number(final_damage, hurtbox.global_position, is_crit)
	# Step 8: Request hit SFX.
	EventBus.audio_sfx_requested.emit(&"hit_impact")


## Process a kill through the pipeline.
func process_kill(attacker: Node, target: Node, position: Vector3) -> void:
	var kill_event := EventContracts.KillEvent.new()
	kill_event.attacker = attacker
	kill_event.target = target
	kill_event.kill_position = position
	EventBus.combat_kill.emit(attacker, target, position)
	EventBus.audio_sfx_requested.emit(&"enemy_death")
	EventBus.log_event(&"kill_processed", kill_event.to_dict())


func _get_stat(entity: Node, stat_name: StringName) -> int:
	# Try to read stat from character data via GameState.
	if entity.has_meta(&"character_id"):
		var char_id: StringName = entity.get_meta(&"character_id")
		if char_id in GameState.character_data:
			var stats: Dictionary = GameState.character_data[char_id].get("stats", {})
			return stats.get(stat_name, 5)
	# Default stat value.
	return 5


func _get_element(node: Node) -> StringName:
	if node.has_meta(&"element"):
		return node.get_meta(&"element")
	return &"physical"


func _get_element_weakness(node: Node) -> StringName:
	if node.has_meta(&"element_weakness"):
		return node.get_meta(&"element_weakness")
	return &""


func _spawn_damage_number(damage: float, position: Vector3, is_crit: bool) -> void:
	var dmg_num: Node = ObjectPool.get_instance(&"damage_number")
	if dmg_num == null:
		return
	if dmg_num is DamageNumber:
		(dmg_num as DamageNumber).activate(damage, position)
