## Drives every horde grunt in a single batched physics loop (Dynasty-Warriors style crowds).
## Owns a fixed pool of HordeGrunt nodes, a spatial hash for separation, and an attack-token
## pool so only a few grunts swing at the player while the rest ring around and posture.
class_name HordeDirector
extends Node3D


signal grunt_defeated(grunt: HordeGrunt, base_id: StringName, attacker: Node3D)

const RING_SLOTS: int = 14
const RING_LAYER_SPACING: float = 1.4
const IDLE_WANDER_RADIUS: float = 2.5
const STRIKE_ARC_DOT: float = 0.3
const PLAYER_BODY_RADIUS: float = 0.75
const HOP_FREQUENCY: float = 11.0
const HOP_HEIGHT: float = 0.14
const TOKEN_REQUEST_EXTRA_RANGE: float = 2.5

var player: Node3D = null
## Camera used to hide grunts that would block the view (optional).
var view_camera: Camera3D = null
## Arena rectangle in XZ (x, z, width, depth).
var arena: Rect2 = Rect2(-50, -50, 100, 100)
var aggression: float = 1.0

var _pool: Array[HordeGrunt] = []
var _active: Array[HordeGrunt] = []
var _grid := SpatialHashGrid.new(Constants.HORDE_SPATIAL_CELL_SIZE)
var _tokens := AttackTokenPool.new(Constants.HORDE_ATTACK_TOKENS)
var _finished: Array[HordeGrunt] = []
var _time: float = 0.0
var _frame: int = 0


func _ready() -> void:
	for i in Constants.HORDE_MAX_GRUNTS:
		var g := HordeGrunt.new()
		g.name = "Grunt%03d" % i
		g.slot = i
		g.defeated.connect(_on_grunt_defeated)
		add_child(g)
		_pool.append(g)


## Spawn a grunt. Returns null when the pool is exhausted.
func spawn(def: HordeUnitDef, pos: Vector3, base_id: StringName = &"") -> HordeGrunt:
	if _pool.is_empty():
		return null
	var g: HordeGrunt = _pool.pop_back()
	g.activate(def, Vector3(pos.x, 0.0, pos.z), base_id)
	_active.append(g)
	return g


## Number of grunts alive (excludes corpses).
func get_alive_count() -> int:
	var n := 0
	for g in _active:
		if g.is_alive():
			n += 1
	return n


## Alive grunts guarding a base.
func get_garrison_alive(base_id: StringName) -> int:
	var n := 0
	for g in _active:
		if g.is_alive() and g.base_id == base_id:
			n += 1
	return n


## Free pool capacity.
func get_free_count() -> int:
	return _pool.size()


## Alive grunts, for UI (minimap) — do not mutate.
func get_active_grunts() -> Array[HordeGrunt]:
	return _active


## Scale how often grunts attack (1.0 = baseline). Also sets how many may attack at once.
func set_aggression(value: float) -> void:
	aggression = maxf(value, 0.1)
	_tokens.set_capacity(maxi(1, roundi(Constants.HORDE_ATTACK_TOKENS * aggression)))


## Wake every idle garrison grunt at a base (e.g. when its base is attacked).
func alert_base(base_id: StringName) -> void:
	for g in _active:
		if g.base_id == base_id and g.state == HordeGrunt.GruntState.IDLE:
			g.state = HordeGrunt.GruntState.ADVANCE


## Remove every grunt immediately (scene teardown / debug).
func clear_all() -> void:
	for g in _active.duplicate():
		_release(g)


func _physics_process(delta: float) -> void:
	var dt := minf(delta, Constants.DELTA_CAP)
	_time += dt
	_frame += 1
	_grid.clear()
	for i in _active.size():
		var g := _active[i]
		if g.is_alive():
			_grid.insert(i, Vector2(g.position.x, g.position.z))
	var hide_d2 := Constants.BATTLEFIELD_CAMERA_HIDE_DISTANCE * Constants.BATTLEFIELD_CAMERA_HIDE_DISTANCE
	var cam_pos := view_camera.global_position if view_camera != null and is_instance_valid(view_camera) else Vector3(INF, INF, INF)
	var player_pos := Vector2.ZERO
	var has_player := player != null and is_instance_valid(player)
	if has_player:
		player_pos = Vector2(player.global_position.x, player.global_position.z)

	# Grid ids are indices into _active, so releases are deferred until after the loop.
	_finished.clear()
	for i in _active.size():
		var g := _active[i]
		g.tick_flash(dt)
		g.visible = g.position.distance_squared_to(cam_pos) > hide_d2
		if g.state == HordeGrunt.GruntState.DEAD:
			_tick_corpse(g, dt)
			if g.state_timer <= 0.0:
				_finished.append(g)
		else:
			_tick_grunt(g, i, dt, player_pos, has_player)
	for g in _finished:
		_release(g)


func _tick_grunt(g: HordeGrunt, index: int, dt: float, player_pos: Vector2, has_player: bool) -> void:
	var pos := Vector2(g.position.x, g.position.z)
	var to_player := player_pos - pos
	var dist := to_player.length()
	var steer := Vector2.ZERO
	var def := g.def
	if g.attack_cooldown > 0.0:
		g.attack_cooldown -= dt

	match g.state:
		HordeGrunt.GruntState.IDLE:
			var engage := has_player and (g.base_id == &"" or dist <= Constants.HORDE_ENGAGE_RADIUS)
			if engage:
				g.state = HordeGrunt.GruntState.ADVANCE
			else:
				var wander := g.home + Vector2(cos(_time * 0.4 + g.anim_phase), sin(_time * 0.3 + g.anim_phase)) * IDLE_WANDER_RADIUS
				steer = HordeSteering.seek(pos, wander, def.move_speed * 0.3, 0.3)
		HordeGrunt.GruntState.ADVANCE:
			if not has_player:
				g.state = HordeGrunt.GruntState.IDLE
			else:
				var wants_attack := g.attack_cooldown <= 0.0 and dist <= Constants.HORDE_RING_RADIUS + TOKEN_REQUEST_EXTRA_RANGE
				if wants_attack and _tokens.request(g.slot):
					steer = HordeSteering.seek(pos, player_pos, def.move_speed * 1.15, Constants.HORDE_ATTACK_RANGE * 0.8)
					g.facing = to_player.normalized() if dist > 0.001 else g.facing
					if dist <= Constants.HORDE_ATTACK_RANGE:
						g.state = HordeGrunt.GruntState.WINDUP
						g.state_timer = Constants.HORDE_ATTACK_WINDUP
				else:
					var layer := g.slot / RING_SLOTS
					var radius := Constants.HORDE_RING_RADIUS + layer * RING_LAYER_SPACING
					var slot_pos := HordeSteering.ring_slot(player_pos, g.slot + int(_time * 0.15 * RING_SLOTS) % RING_SLOTS, RING_SLOTS, radius)
					steer = HordeSteering.seek(pos, slot_pos, def.move_speed, 0.4)
					if dist > 0.001:
						g.facing = g.facing.lerp(to_player / dist, minf(dt * 8.0, 1.0)).normalized()
		HordeGrunt.GruntState.WINDUP:
			if dist > 0.001:
				g.facing = g.facing.lerp(to_player / dist, minf(dt * 10.0, 1.0)).normalized()
			g.state_timer -= dt
			if g.state_timer <= 0.0:
				g.state = HordeGrunt.GruntState.STRIKE
				g.state_timer = 0.12
				_resolve_strike(g, pos, player_pos, has_player)
		HordeGrunt.GruntState.STRIKE:
			steer = g.facing * def.move_speed * 1.6
			g.state_timer -= dt
			if g.state_timer <= 0.0:
				g.state = HordeGrunt.GruntState.RECOVER
				g.state_timer = Constants.HORDE_ATTACK_RECOVERY
		HordeGrunt.GruntState.RECOVER:
			g.state_timer -= dt
			if g.state_timer <= 0.0:
				_end_attack(g)
		HordeGrunt.GruntState.STAGGER:
			_tokens.release(g.slot)
			g.state_timer -= dt
			if g.state_timer <= 0.0:
				g.state = HordeGrunt.GruntState.ADVANCE
				g.attack_cooldown = maxf(g.attack_cooldown, Constants.HORDE_ATTACK_COOLDOWN * 0.5)
		HordeGrunt.GruntState.AIRBORNE:
			_tokens.release(g.slot)

	# Crowd separation from neighbours (time-sliced: half the crowd refreshes per frame)
	# and from the player's body (every frame, so nobody overlaps the hero).
	if g.state != HordeGrunt.GruntState.AIRBORNE:
		if (index + _frame) & 1 == 0:
			g.sep_cache = _grid.separation_sum(index, Constants.HORDE_SEPARATION_RADIUS * def.body_scale) * Constants.HORDE_SEPARATION_FORCE
		steer += g.sep_cache
		if has_player:
			steer += HordeSteering.separation(pos, player_pos, PLAYER_BODY_RADIUS + def.radius) * Constants.HORDE_SEPARATION_FORCE * 2.0

	_animate(g, steer, _integrate(g, steer, dt), dt)


func _resolve_strike(g: HordeGrunt, pos: Vector2, player_pos: Vector2, has_player: bool) -> void:
	if not has_player or g.def.attack == null:
		return
	var reach := Constants.HORDE_ATTACK_RANGE + g.def.radius
	if not HordeSteering.in_strike_arc(pos, g.facing, player_pos, reach, STRIKE_ARC_DOT):
		return
	var hurtbox := player.get(&"hurtbox") as Hurtbox
	if hurtbox != null:
		hurtbox.receive_hit(g.def.attack, g)


func _end_attack(g: HordeGrunt) -> void:
	_tokens.release(g.slot)
	g.attack_cooldown = Constants.HORDE_ATTACK_COOLDOWN / aggression * randf_range(0.8, 1.4)
	g.state = HordeGrunt.GruntState.ADVANCE


## Advance position/velocity and return the new position (the caller writes the transform once).
func _integrate(g: HordeGrunt, steer: Vector2, dt: float) -> Vector3:
	var p := g.position
	p.x += (steer.x + g.velocity.x) * dt
	p.z += (steer.y + g.velocity.z) * dt
	if g.state == HordeGrunt.GruntState.AIRBORNE or p.y > 0.0 or g.velocity.y > 0.0:
		g.velocity.y -= Constants.HORDE_LAUNCH_GRAVITY * dt
		p.y += g.velocity.y * dt
		if p.y <= 0.0:
			p.y = 0.0
			g.velocity.y = 0.0
			if g.state == HordeGrunt.GruntState.AIRBORNE:
				g.state = HordeGrunt.GruntState.STAGGER
				g.state_timer = Constants.HORDE_STAGGER_TIME * 1.5
	# Ground friction on knockback.
	var decay := exp(-Constants.HORDE_KNOCKBACK_DECAY * dt)
	g.velocity.x *= decay
	g.velocity.z *= decay
	p.x = clampf(p.x, arena.position.x, arena.end.x)
	p.z = clampf(p.z, arena.position.y, arena.end.y)
	return p


func _animate(g: HordeGrunt, steer: Vector2, pos: Vector3, dt: float) -> void:
	var body := g.get_body()
	var speed := steer.length()
	g.anim_phase += dt * HOP_FREQUENCY * clampf(speed / maxf(g.def.move_speed, 0.1), 0.25, 1.4)
	var hop := absf(sin(g.anim_phase)) * HOP_HEIGHT * clampf(speed, 0.0, 1.0)
	var squash := 1.0
	var lean := 0.0
	match g.state:
		HordeGrunt.GruntState.WINDUP:
			# Telegraph: rear back and swell so the player can read the attack.
			var t := 1.0 - g.state_timer / Constants.HORDE_ATTACK_WINDUP
			squash = 1.0 + 0.25 * t
			lean = -0.35 * t
			hop = 0.0
		HordeGrunt.GruntState.STRIKE:
			lean = 0.5
			squash = 0.85
		HordeGrunt.GruntState.STAGGER:
			lean = -0.4
			squash = 0.9
		HordeGrunt.GruntState.AIRBORNE:
			lean = -0.9
	var widen := 1.0 / sqrt(squash)
	body.transform = Transform3D(Basis(Vector3.BACK, lean).scaled(Vector3(widen, squash, widen)), Vector3(0.0, hop, 0.0))
	g.transform = Transform3D(Basis(Vector3.UP, atan2(-g.facing.y, g.facing.x)), pos)


func _tick_corpse(g: HordeGrunt, dt: float) -> void:
	g.state_timer -= dt
	g.position = _integrate(g, Vector2.ZERO, dt)
	var t := clampf(g.state_timer / Constants.HORDE_CORPSE_TIME, 0.0, 1.0)
	# Topple over and shrink away.
	g.get_body().transform = Transform3D(Basis(Vector3.BACK, lerpf(-1.4, 0.0, t)).scaled(Vector3.ONE * maxf(t, 0.05)), Vector3.ZERO)


func _on_grunt_defeated(grunt: HordeGrunt, attacker: Node3D) -> void:
	_tokens.release(grunt.slot)
	grunt_defeated.emit(grunt, grunt.base_id, attacker)


func _release(g: HordeGrunt) -> void:
	_tokens.release(g.slot)
	g.deactivate()
	_active.erase(g)
	_pool.append(g)
