## Procedurally dresses a battlefield from a BattlefieldDef: sky, light, desert ground,
## boundary cliffs, rock spires, scatter, and one BattlefieldBaseMarker per base.
## Pure presentation plus floor/wall collision — no gameplay rules live here.
class_name BattlefieldEnvironment
extends Node3D


const GROUND_EXTENT: float = 420.0
const WALL_HEIGHT: float = 6.0
const SPIRE_COUNT: int = 26
const ROCK_COUNT: int = 70
const SHRUB_COUNT: int = 90
const SUN_SHADOW_DISTANCE: float = 70.0

const GROUND_SHADER := """
shader_type spatial;
render_mode diffuse_burley;
uniform vec3 color_a : source_color;
uniform vec3 color_b : source_color;
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = world_pos.xz;
	float n = noise(p * 0.05) * 0.6 + noise(p * 0.21) * 0.3 + noise(p * 1.3) * 0.1;
	float ripple = sin(p.x * 0.9 + noise(p * 0.1) * 6.0) * 0.5 + 0.5;
	vec3 c = mix(color_b, color_a, smoothstep(0.25, 0.75, n));
	c *= 0.93 + ripple * 0.07;
	ALBEDO = c;
	ROUGHNESS = 0.95;
}
"""

var _base_markers: Dictionary = {}  # base_id -> BattlefieldBaseMarker
var _rng := RandomNumberGenerator.new()


## Build everything for the given battlefield.
func build(def: BattlefieldDef) -> void:
	_rng.seed = def.scatter_seed
	_build_sky_and_light(def)
	_build_ground(def)
	_build_boundary(def)
	_build_scatter(def)
	for base_def in def.bases:
		var marker := BattlefieldBaseMarker.new()
		marker.name = "Base_%s" % base_def.base_id
		add_child(marker)
		marker.setup(base_def)
		_base_markers[base_def.base_id] = marker


## Visual marker for a base (flags, hive mound, capture ring).
func get_base_marker(base_id: StringName) -> BattlefieldBaseMarker:
	return _base_markers.get(base_id)


func _build_sky_and_light(def: BattlefieldDef) -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = def.sky_top_color
	sky_mat.sky_horizon_color = def.sky_horizon_color
	sky_mat.ground_horizon_color = def.sky_horizon_color
	sky_mat.ground_bottom_color = def.ground_color_alt.darkened(0.3)
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = def.sky_horizon_color
	env.fog_density = 0.006
	env.fog_sky_affect = 0.2
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48.0, -35.0, 0.0)
	sun.light_color = Color(1.0, 0.93, 0.8)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = SUN_SHADOW_DISTANCE
	add_child(sun)


func _build_ground(def: BattlefieldDef) -> void:
	var shader := Shader.new()
	shader.code = GROUND_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter(&"color_a", def.ground_color)
	mat.set_shader_parameter(&"color_b", def.ground_color_alt)
	var plane := PlaneMesh.new()
	plane.size = Vector2(GROUND_EXTENT, GROUND_EXTENT)
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = plane
	ground.material_override = mat
	add_child(ground)
	var body := StaticBody3D.new()
	body.name = "GroundBody"
	body.collision_layer = Constants.LAYER_ENVIRONMENT
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(GROUND_EXTENT, 1.0, GROUND_EXTENT)
	shape.shape = box
	shape.position.y = -0.5
	body.add_child(shape)
	add_child(body)


func _build_boundary(def: BattlefieldDef) -> void:
	var half := def.arena_size * 0.5
	# Invisible walls keep physics bodies (player, officers) inside the arena.
	var walls := StaticBody3D.new()
	walls.name = "BoundaryWalls"
	walls.collision_layer = Constants.LAYER_ENVIRONMENT
	walls.collision_mask = 0
	for side in 4:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		var horizontal := side < 2
		box.size = Vector3(def.arena_size.x + 4.0 if horizontal else 2.0, WALL_HEIGHT, 2.0 if horizontal else def.arena_size.y + 4.0)
		shape.shape = box
		var sign := -1.0 if side % 2 == 0 else 1.0
		shape.position = Vector3(0.0 if horizontal else sign * (half.x + 1.0), WALL_HEIGHT * 0.5, sign * (half.y + 1.0) if horizontal else 0.0)
		walls.add_child(shape)
	add_child(walls)
	# Visible cliff ring just outside the play area.
	var cliff_mat := _flat_material(def.ground_color_alt.darkened(0.25))
	var perimeter := 2.0 * (def.arena_size.x + def.arena_size.y)
	var count := int(perimeter / 7.0)
	for i in count:
		var t := float(i) / float(count)
		var p := _perimeter_point(half + Vector2(4.0, 4.0), t)
		var rock := _make_rock(_rng.randf_range(5.0, 9.0), _rng.randf_range(4.0, 10.0), cliff_mat)
		rock.position = Vector3(p.x, 0.0, p.y)
		add_child(rock)


func _build_scatter(def: BattlefieldDef) -> void:
	var half := def.arena_size * 0.5
	var spire_mat := _flat_material(Color(0.62, 0.42, 0.3))
	for i in SPIRE_COUNT:
		var p := _perimeter_point(half + Vector2(_rng.randf_range(10.0, 40.0), _rng.randf_range(10.0, 40.0)), _rng.randf())
		add_child(_make_spire(Vector3(p.x, 0.0, p.y), spire_mat))
	var rock_mat := _flat_material(def.ground_color_alt.darkened(0.15))
	for i in ROCK_COUNT:
		var p := _random_open_point(def, 5.0)
		var rock := _make_rock(_rng.randf_range(0.5, 1.6), _rng.randf_range(0.4, 1.2), rock_mat)
		rock.position = Vector3(p.x, 0.0, p.y)
		add_child(rock)
	var shrub_mat := _flat_material(Color(0.45, 0.5, 0.25))
	for i in SHRUB_COUNT:
		var p := _random_open_point(def, 3.0)
		add_child(_make_shrub(Vector3(p.x, 0.0, p.y), shrub_mat))


## A point in the arena that keeps clear of bases and the player spawn.
func _random_open_point(def: BattlefieldDef, clearance: float) -> Vector2:
	var half := def.arena_size * 0.5 - Vector2(2.0, 2.0)
	for attempt in 12:
		var p := Vector2(_rng.randf_range(-half.x, half.x), _rng.randf_range(-half.y, half.y))
		var ok := p.distance_to(def.player_spawn) > Constants.BASE_CAPTURE_RADIUS + clearance
		for b in def.bases:
			if p.distance_to(b.position) < Constants.BASE_CAPTURE_RADIUS + clearance:
				ok = false
				break
		if ok:
			return p
	return Vector2(half.x, half.y)


func _perimeter_point(half: Vector2, t: float) -> Vector2:
	var w := half.x * 2.0
	var h := half.y * 2.0
	var d := fposmod(t, 1.0) * 2.0 * (w + h)
	if d < w:
		return Vector2(-half.x + d, -half.y)
	d -= w
	if d < h:
		return Vector2(half.x, -half.y + d)
	d -= h
	if d < w:
		return Vector2(half.x - d, half.y)
	d -= w
	return Vector2(-half.x, half.y - d)


func _make_rock(width: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 6
	mesh.rings = 3
	mesh.radius = width * 0.5
	mesh.height = height
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.rotation = Vector3(_rng.randf_range(-0.2, 0.2), _rng.randf() * TAU, _rng.randf_range(-0.2, 0.2))
	mi.scale = Vector3(1.0, 1.0, _rng.randf_range(0.7, 1.3))
	return mi


func _make_spire(pos: Vector3, mat: Material) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	var h := _rng.randf_range(10.0, 26.0)
	var r := _rng.randf_range(2.0, 4.5)
	var y := 0.0
	var tiers := 3
	for i in tiers:
		var seg := CylinderMesh.new()
		seg.radial_segments = 7
		seg.bottom_radius = r * (1.0 - 0.22 * i)
		seg.top_radius = r * (1.0 - 0.22 * (i + 1)) + 0.4
		seg.height = h / tiers
		var mi := MeshInstance3D.new()
		mi.mesh = seg
		mi.material_override = mat
		mi.position.y = y + seg.height * 0.5
		mi.rotation.y = _rng.randf() * TAU
		root.add_child(mi)
		y += seg.height
	return root


func _make_shrub(pos: Vector3, mat: Material) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	for i in 3:
		var cone := CylinderMesh.new()
		cone.radial_segments = 5
		cone.top_radius = 0.0
		cone.bottom_radius = _rng.randf_range(0.15, 0.3)
		cone.height = _rng.randf_range(0.5, 1.0)
		var mi := MeshInstance3D.new()
		mi.mesh = cone
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(_rng.randf_range(-0.3, 0.3), cone.height * 0.5, _rng.randf_range(-0.3, 0.3))
		mi.rotation = Vector3(_rng.randf_range(-0.4, 0.4), 0.0, _rng.randf_range(-0.4, 0.4))
		root.add_child(mi)
	return root


static func _flat_material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	return m
