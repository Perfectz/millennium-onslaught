## Battlefield (musou) run orchestrator. Builds the map from a BattlefieldDef, seeds base
## garrisons + officers, streams reinforcements, runs capture/commander/victory flow, and
## feeds KOs into the RPG layer (XP, meseta, story flags, save).
class_name BattlefieldRun
extends Node3D


const HUDScene := preload("res://scenes/ui/hud.tscn")
const DefeatScene := preload("res://scenes/ui/defeat_screen.tscn")
const OfficerScene := preload("res://scenes/enemies/enemy_rusher.tscn")
const PauseMenuScript := preload("res://scripts/ui/pause_menu.gd")
const DEFAULT_BATTLEFIELD := "res://resources/battlefield/piata_plains.tres"
const REGISTRY: Dictionary = {
	&"piata_plains": "res://resources/battlefield/piata_plains.tres",
}
const OFFICER_MODEL_SCALE: float = 1.35
const COMMANDER_MODEL_SCALE: float = 1.8
const OFFICER_LABEL_HEIGHT: float = 3.2
const OFFICER_LABEL_COLOR := Color(1.0, 0.62, 0.25)
const GARRISON_SPREAD: float = 4.5
const SQUAD_SPREAD: float = 3.0
const CAPTURE_CHECK_INTERVAL: float = 0.25
const DEFEAT_DELAY: float = 1.5
const FADE_TIME: float = 0.5

enum Phase { BATTLE, COMMANDER, ENDED }

@onready var player: PlayerController = $Player
@onready var camera: CameraFollow = $Camera3D
@onready var fade_rect: ColorRect = $FadeOverlay/FadeRect

var _def: BattlefieldDef
var _env: BattlefieldEnvironment
var _director: HordeDirector
var _pickups: PickupField
var _control := BattlefieldControl.new()
var _tally := BattleTally.new()
var _hud: Node = null
var _bf_hud: BattlefieldHUD
var _base_defs: Dictionary = {}  # base_id -> BattlefieldBaseDef
var _officers: Dictionary = {}  # instance_id -> {node, base_id, name, awake}
var _commander: EnemyController = null
var _phase: Phase = Phase.BATTLE
var _reinforce_timer: float = 0.0
var _capture_timer: float = 0.0
var _elapsed: float = 0.0
var _xp_earned: int = 0
var _pause_menu: CanvasLayer = null
var _char_switch_cooldown: float = 0.0
var _reinforce_index: int = 0


func _ready() -> void:
	InputManager.set_context(InputManager.InputContext.COMBAT)
	RuntimeState.reset_dungeon()
	RuntimeState.stage_mode = false
	fade_rect.color = Color(0, 0, 0, 1)
	_def = _resolve_def()
	var half := _def.arena_size * 0.5
	RuntimeState.set_room_bounds(-half.x, half.x, -half.y, half.y)

	_env = BattlefieldEnvironment.new()
	_env.name = "Environment"
	add_child(_env)
	_env.build(_def)

	_director = HordeDirector.new()
	_director.name = "HordeDirector"
	_director.player = player
	_director.arena = Rect2(-half.x, -half.y, _def.arena_size.x, _def.arena_size.y)
	add_child(_director)
	_director.grunt_defeated.connect(_on_grunt_defeated)

	_pickups = PickupField.new()
	_pickups.name = "PickupField"
	_pickups.player = player
	add_child(_pickups)

	var hitstop := HitstopSystem.new()
	hitstop.name = "HitstopSystem"
	add_child(hitstop)
	var vfx := VFXSystem.new()
	vfx.name = "VFXSystem"
	add_child(vfx)
	var bf_vfx := BattlefieldVFX.new()
	bf_vfx.name = "BattlefieldVFX"
	add_child(bf_vfx)

	_hud = HUDScene.instantiate()
	add_child(_hud)
	_bf_hud = BattlefieldHUD.new()
	_bf_hud.name = "BattlefieldHUD"
	add_child(_bf_hud)

	_seed_bases()
	_control.base_captured.connect(_on_base_captured)
	_control.morale_changed.connect(func(m: float) -> void: EventBus.battlefield_morale_changed.emit(m))
	_control.all_enemy_bases_captured.connect(_begin_commander_phase)
	_tally.milestone_reached.connect(func(c: int) -> void: EventBus.battlefield_ko_milestone.emit(c))
	_bf_hud.bind(self)

	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.player_died.connect(_on_player_died)
	EventBus.enemy_summon_requested.connect(_on_summon_requested)
	EventBus.rpg_level_up.connect(_on_level_up)

	_apply_musou_reach()
	player.global_position = Vector3(_def.player_spawn.x, 0.1, _def.player_spawn.y)
	player.facing_angle = PI * 0.5
	player.facing_direction = Vector3(0, 0, -1)
	player.model_pivot.rotation.y = player.facing_angle
	camera.snap_to_target()
	camera.call_deferred("snap_to_target")

	_reinforce_timer = _def.reinforcement_interval * 0.5
	EventBus.audio_music_requested.emit(_def.music_track, true)
	EventBus.battlefield_started.emit(_def.battlefield_id)
	_set_objective("Break the nest garrisons and capture every Bio-monster nest")
	_fade_in()


## Snapshot used by the minimap (called ~10x/sec by the HUD).
func get_minimap_snapshot() -> Dictionary:
	var grunts := PackedVector2Array()
	for g in _director.get_active_grunts():
		if g.is_alive():
			grunts.append(Vector2(g.position.x, g.position.z))
	var officers := PackedVector2Array()
	for entry: Dictionary in _officers.values():
		var node: Node3D = entry["node"]
		if is_instance_valid(node):
			officers.append(Vector2(node.global_position.x, node.global_position.z))
	if is_instance_valid(_commander):
		officers.append(Vector2(_commander.global_position.x, _commander.global_position.z))
	var bases: Array[Dictionary] = []
	for id: StringName in _base_defs:
		bases.append({"pos": (_base_defs[id] as BattlefieldBaseDef).position, "side": _control.get_owner(id)})
	var dir := Vector2(player.facing_direction.x, player.facing_direction.z)
	return {
		"arena": _def.arena_size,
		"bases": bases,
		"grunts": grunts,
		"officers": officers,
		"player": Vector2(player.global_position.x, player.global_position.z),
		"player_dir": dir.normalized() if dir.length_squared() > 0.0001 else Vector2(0, -1),
	}


## Base rows for the HUD: [{name, side, remaining}].
func get_base_status() -> Array:
	var rows: Array = []
	for id: StringName in _base_defs:
		rows.append({
			"name": (_base_defs[id] as BattlefieldBaseDef).display_name,
			"side": _control.get_owner(id),
			"remaining": _control.get_garrison_remaining(id),
		})
	return rows


## The active battlefield definition.
func get_def() -> BattlefieldDef:
	return _def


## Live KO tally (for tests/tools).
func get_tally() -> BattleTally:
	return _tally


func _resolve_def() -> BattlefieldDef:
	var id := GameState.pending_battlefield_id
	var path: String = REGISTRY.get(id, DEFAULT_BATTLEFIELD)
	return load(path) as BattlefieldDef


func _seed_bases() -> void:
	for base_def in _def.bases:
		_base_defs[base_def.base_id] = base_def
		var spawned := 0
		if base_def.side == BattlefieldControl.Side.ENEMY and not base_def.garrison_units.is_empty():
			for i in base_def.garrison:
				var unit: HordeUnitDef = base_def.garrison_units[i % base_def.garrison_units.size()]
				var a := TAU * float(i) / float(maxi(base_def.garrison, 1))
				var r := randf_range(1.5, GARRISON_SPREAD)
				var pos := Vector3(base_def.position.x + cos(a) * r, 0.0, base_def.position.y + sin(a) * r)
				if _director.spawn(unit, pos, base_def.base_id) != null:
					spawned += 1
		var officer_count := 0
		if base_def.side == BattlefieldControl.Side.ENEMY and base_def.officer_def != null:
			_spawn_officer(base_def.officer_def, base_def.officer_name, base_def.position + Vector2(0, 3.0), base_def.base_id, true, OFFICER_MODEL_SCALE)
			officer_count = 1
		_control.add_base(base_def.base_id, base_def.side, spawned + officer_count)


## Enlarge the player's attack hitbox so combos sweep through crowds (a copy, not the shared shape).
func _apply_musou_reach() -> void:
	var shape_node := player.hitbox.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null or not (shape_node.shape is BoxShape3D):
		return
	var box := (shape_node.shape as BoxShape3D).duplicate() as BoxShape3D
	box.size *= Constants.BATTLEFIELD_PLAYER_REACH_SCALE
	shape_node.shape = box


func _spawn_officer(def: EnemyDef, display_name: String, pos: Vector2, base_id: StringName, dormant: bool, model_scale: float) -> EnemyController:
	var officer := OfficerScene.instantiate() as EnemyController
	add_child(officer)
	officer.configure(def, player, dormant)
	officer.global_position = Vector3(pos.x, 0.1, pos.y)
	officer.model_pivot.scale = Vector3.ONE * model_scale
	var label := Label3D.new()
	label.text = display_name
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 30
	label.outline_size = 8
	label.modulate = OFFICER_LABEL_COLOR
	label.position.y = OFFICER_LABEL_HEIGHT * model_scale / OFFICER_MODEL_SCALE
	officer.add_child(label)
	_officers[officer.get_instance_id()] = {"node": officer, "base_id": base_id, "name": display_name, "awake": not dormant}
	if not dormant:
		officer.activate_for_encounter()
	EventBus.battlefield_officer_spawned.emit(officer, display_name)
	return officer


func _process(delta: float) -> void:
	if _char_switch_cooldown > 0.0:
		_char_switch_cooldown -= delta
	_handle_runtime_actions()
	if _phase == Phase.ENDED or get_tree().paused:
		return
	_elapsed += delta
	_hide_officers_near_camera()
	_wake_nearby_officers()
	_tick_reinforcements(delta)
	_capture_timer -= delta
	if _capture_timer <= 0.0:
		_capture_timer = CAPTURE_CHECK_INTERVAL
		_check_captures()


func _handle_runtime_actions() -> void:
	if get_tree().paused or _phase == Phase.ENDED:
		return
	if InputManager.is_action_just_pressed_for_player(player.player_index, &"pause"):
		_toggle_pause_menu()
		return
	if _char_switch_cooldown <= 0.0:
		var dir := 0
		if InputManager.is_action_just_pressed_for_player(player.player_index, &"character_next"):
			dir = 1
		elif InputManager.is_action_just_pressed_for_player(player.player_index, &"character_prev"):
			dir = -1
		if dir != 0 and PartySwitcher.switch_active(player, dir):
			_char_switch_cooldown = Constants.CHARACTER_SWITCH_COOLDOWN
	if InputManager.is_action_just_pressed_for_player(player.player_index, &"technique_cycle"):
		player.cycle_technique()


func _hide_officers_near_camera() -> void:
	var cam := camera.global_position
	for entry: Dictionary in _officers.values():
		var node: EnemyController = entry["node"]
		if is_instance_valid(node):
			node.model_pivot.visible = node.global_position.distance_to(cam) > Constants.BATTLEFIELD_CAMERA_HIDE_DISTANCE
	if is_instance_valid(_commander):
		_commander.model_pivot.visible = _commander.global_position.distance_to(cam) > Constants.BATTLEFIELD_CAMERA_HIDE_DISTANCE


func _wake_nearby_officers() -> void:
	var p := player.global_position
	for entry: Dictionary in _officers.values():
		if entry["awake"]:
			continue
		var node: EnemyController = entry["node"]
		if not is_instance_valid(node):
			continue
		if node.global_position.distance_to(p) <= Constants.HORDE_ENGAGE_RADIUS:
			entry["awake"] = true
			node.activate_for_encounter()
			_director.alert_base(entry["base_id"])


func _tick_reinforcements(delta: float) -> void:
	_reinforce_timer -= delta
	if _reinforce_timer > 0.0:
		return
	_reinforce_timer = _def.reinforcement_interval
	if _def.reinforcement_units.is_empty():
		return
	var room := mini(_def.max_alive - _director.get_alive_count(), _director.get_free_count())
	var count := mini(_def.reinforcement_squad_size, room)
	if count <= 0:
		return
	var origin := _reinforcement_origin()
	for i in count:
		var unit: HordeUnitDef = _def.reinforcement_units[_reinforce_index % _def.reinforcement_units.size()]
		_reinforce_index += 1
		var a := randf() * TAU
		_director.spawn(unit, Vector3(origin.x + cos(a) * SQUAD_SPREAD, 0.0, origin.y + sin(a) * SQUAD_SPREAD))


## Reinforcements pour from the enemy-held base closest to the player (or the commander's gate).
func _reinforcement_origin() -> Vector2:
	if _phase == Phase.COMMANDER:
		return _def.commander_spawn
	var p := Vector2(player.global_position.x, player.global_position.z)
	var best := _def.commander_spawn
	var best_d := INF
	for id: StringName in _base_defs:
		if _control.get_owner(id) != BattlefieldControl.Side.ENEMY:
			continue
		var pos := (_base_defs[id] as BattlefieldBaseDef).position
		var d := pos.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = pos
	return best


func _on_summon_requested(_summoner: Node, unit: Resource, count: int, origin: Vector3) -> void:
	var horde_unit := unit as HordeUnitDef
	if horde_unit == null:
		return
	for i in count:
		var a := TAU * float(i) / float(maxi(count, 1))
		_director.spawn(horde_unit, origin + Vector3(cos(a), 0.0, sin(a)) * 2.0)


func _check_captures() -> void:
	var p := Vector2(player.global_position.x, player.global_position.z)
	for id: StringName in _base_defs:
		if _control.get_owner(id) != BattlefieldControl.Side.ENEMY:
			continue
		var base_def: BattlefieldBaseDef = _base_defs[id]
		if base_def.position.distance_to(p) > Constants.BASE_CAPTURE_RADIUS:
			continue
		_control.try_capture(id)


func _on_grunt_defeated(grunt: HordeGrunt, base_id: StringName, _attacker: Node3D) -> void:
	if grunt.def and not grunt.def.drop_table.is_empty():
		for item_id in DropRoller.roll_drops(grunt.def.drop_table):
			_pickups.spawn(item_id, grunt.global_position)
	if base_id != &"":
		_control.register_garrison_ko(base_id)
	_register_ko(false, Constants.BATTLE_XP_PER_KO)


func _on_enemy_died(enemy: Node, _type: StringName, _pos: Vector3) -> void:
	if enemy == null:
		return
	if enemy == _commander:
		_register_ko(true, _commander.enemy_def.xp_reward if _commander.enemy_def else Constants.BATTLE_XP_PER_OFFICER)
		EventBus.battlefield_officer_defeated.emit(enemy, _def.commander_name)
		_commander = null
		_finish(true)
		return
	var key := enemy.get_instance_id()
	if not _officers.has(key):
		return
	var entry: Dictionary = _officers[key]
	_officers.erase(key)
	var ec := enemy as EnemyController
	_register_ko(true, ec.enemy_def.xp_reward if ec and ec.enemy_def else Constants.BATTLE_XP_PER_OFFICER)
	_drop_officer_loot(ec.global_position if ec else player.global_position)
	_control.register_officer_ko()
	if entry["base_id"] != &"":
		_control.register_garrison_ko(entry["base_id"])
	EventBus.battlefield_officer_defeated.emit(enemy, entry["name"])


func _drop_officer_loot(pos: Vector3) -> void:
	_pickups.spawn(Constants.OFFICER_DROP_ITEM, pos)
	if randf() < Constants.OFFICER_RARE_DROP_CHANCE:
		_pickups.spawn(Constants.OFFICER_RARE_DROP_ITEM, pos + Vector3(0.8, 0.0, 0.0))


func _register_ko(is_officer: bool, xp: int) -> void:
	if _phase == Phase.ENDED:
		return
	_tally.register_ko(is_officer)
	_xp_earned += xp
	player.xp_tracker.add_xp(xp)
	EventBus.battlefield_ko_count_changed.emit(_tally.get_ko_count())


func _on_base_captured(base_id: StringName) -> void:
	var base_def: BattlefieldBaseDef = _base_defs[base_id]
	var marker := _env.get_base_marker(base_id)
	if marker:
		marker.set_side(BattlefieldControl.Side.ALLY)
	_director.set_aggression(_control.get_enemy_aggression())
	EventBus.battlefield_base_captured.emit(base_id, base_def.display_name)
	var left := _control.get_enemy_base_count()
	if left > 0:
		_set_objective("Capture the remaining nests (%d left)" % left)


func _begin_commander_phase() -> void:
	if _phase != Phase.BATTLE:
		return
	_phase = Phase.COMMANDER
	_reinforce_timer = _def.reinforcement_interval
	if _def.commander_def:
		_commander = _spawn_officer(_def.commander_def, _def.commander_name, _def.commander_spawn, &"", false, COMMANDER_MODEL_SCALE)
		# The commander is tracked separately from base officers.
		_officers.erase(_commander.get_instance_id())
	if _def.commander_escort_unit:
		for i in _def.commander_escort:
			var a := TAU * float(i) / float(maxi(_def.commander_escort, 1))
			_director.spawn(_def.commander_escort_unit, Vector3(_def.commander_spawn.x + cos(a) * 4.0, 0.0, _def.commander_spawn.y + sin(a) * 4.0))
	_set_objective("Defeat %s!" % _def.commander_name)
	if _commander == null:
		_finish(true)


func _set_objective(text: String) -> void:
	EventBus.battlefield_objective_changed.emit(text)
	if _hud and _hud.has_method("update_objective"):
		_hud.update_objective(text)


func _on_level_up(_player_index: int, new_level: int) -> void:
	# No pause mid-battle: stat points are banked for the party screen.
	ToastSystem.show_toast("LEVEL UP!  Lv %d" % new_level, Color(1.0, 0.92, 0.5))


func _on_player_died(_player_index: int) -> void:
	if _phase == Phase.ENDED:
		return
	_finish(false)


func _finish(victory: bool) -> void:
	if _phase == Phase.ENDED:
		return
	_phase = Phase.ENDED
	EventBus.battlefield_completed.emit(_def.battlefield_id, victory)
	if victory:
		_bank_rewards()
		await get_tree().create_timer(DEFEAT_DELAY).timeout
		_show_results()
	else:
		await get_tree().create_timer(DEFEAT_DELAY).timeout
		get_tree().paused = true
		InputManager.set_context(InputManager.InputContext.MENU)
		var screen := DefeatScene.instantiate()
		add_child(screen)
		screen.retry_pressed.connect(func() -> void:
			get_tree().paused = false
			GameManager.go_to_battlefield(_def.battlefield_id)
		)


func _bank_rewards() -> void:
	var gold := _tally.get_gold_reward()
	GameState.gold += gold
	EventBus.emit_checked(&"rpg_gold_changed", [GameState.gold], {"new_total": GameState.gold})
	for char_id: StringName in GameState.active_party:
		if char_id in GameState.character_data:
			GameState.character_data[char_id]["xp"] = GameState.character_data[char_id].get("xp", 0) + _xp_earned
	PartyXPDistributor.apply(player, _xp_earned)
	if _def.victory_flag != &"":
		GameState.story_flags[String(_def.victory_flag)] = true
	SaveManager.save_game(GameState.active_save_slot)


func _show_results() -> void:
	get_tree().paused = true
	InputManager.set_context(InputManager.InputContext.MENU)
	var screen := BattlefieldResults.new()
	add_child(screen)
	screen.show_results(_def.display_name, _tally, _elapsed, _xp_earned, _tally.get_gold_reward())
	screen.continue_pressed.connect(func() -> void:
		get_tree().paused = false
		GameManager.go_to_overworld()
	)


func _toggle_pause_menu() -> void:
	if _pause_menu != null:
		_resume_from_pause()
		return
	_pause_menu = CanvasLayer.new()
	_pause_menu.set_script(PauseMenuScript)
	add_child(_pause_menu)
	_pause_menu.resumed.connect(_resume_from_pause)
	InputManager.set_context(InputManager.InputContext.MENU)
	get_tree().paused = true


func _resume_from_pause() -> void:
	if _pause_menu != null:
		_pause_menu.queue_free()
		_pause_menu = null
	InputManager.set_context(InputManager.InputContext.COMBAT)
	get_tree().paused = false


func _fade_in() -> void:
	await get_tree().process_frame
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, FADE_TIME)
