## Visual for one base: a pulsing bio-hive mound (enemy) or a hunter camp (ally), a flag,
## and a ground ring showing the capture radius. Swaps look when ownership changes.
class_name BattlefieldBaseMarker
extends Node3D


const ALLY_COLOR := Color(0.3, 0.62, 1.0)
const ENEMY_COLOR := Color(0.85, 0.2, 0.55)
const DEAD_HIVE_COLOR := Color(0.35, 0.3, 0.3)
const HIVE_COLOR := Color(0.45, 0.2, 0.42)
const POST_COLOR := Color(0.42, 0.3, 0.2)
const PALISADE_POSTS: int = 18
const PULSE_SPEED: float = 2.2

var base_def: BattlefieldBaseDef = null
var side: int = 0

var _flag_mat := StandardMaterial3D.new()
var _ring_mat := StandardMaterial3D.new()
var _hive_mat := StandardMaterial3D.new()
var _vent_mat := StandardMaterial3D.new()
var _hive: Node3D = null
var _camp: Node3D = null
var _time: float = 0.0


## Build the marker for a base definition.
func setup(def: BattlefieldBaseDef) -> void:
	base_def = def
	position = Vector3(def.position.x, 0.0, def.position.y)
	_flag_mat.roughness = 0.8
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_hive_mat.roughness = 0.6
	_vent_mat.emission_enabled = true
	_vent_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_build_ring()
	_build_palisade()
	_build_flag()
	_hive = _build_hive()
	_camp = _build_camp()
	set_side(def.side)


## Update visuals for a new owner (BattlefieldControl.Side value).
func set_side(new_side: int) -> void:
	side = new_side
	var ally := side == BattlefieldControl.Side.ALLY
	var color := ALLY_COLOR if ally else ENEMY_COLOR
	_flag_mat.albedo_color = color
	_ring_mat.albedo_color = Color(color, 0.28)
	_camp.visible = ally
	_hive_mat.albedo_color = DEAD_HIVE_COLOR if ally else HIVE_COLOR
	_vent_mat.albedo_color = Color(0.2, 0.2, 0.2) if ally else Color(1.0, 0.35, 0.85)
	_vent_mat.emission = Color(0, 0, 0) if ally else Color(1.0, 0.3, 0.8)
	# The ally home camp never had a hive; captured hives stay as dead husks.
	_hive.visible = base_def.side == BattlefieldControl.Side.ENEMY


func _process(delta: float) -> void:
	if side != BattlefieldControl.Side.ENEMY or _hive == null:
		return
	_time += delta
	var pulse := 1.0 + sin(_time * PULSE_SPEED) * 0.04
	_hive.scale = Vector3(pulse, 1.0 / pulse, pulse)
	_vent_mat.emission_energy_multiplier = 1.2 + sin(_time * PULSE_SPEED * 1.7) * 0.6


func _build_ring() -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = Constants.BASE_CAPTURE_RADIUS - 0.25
	torus.outer_radius = Constants.BASE_CAPTURE_RADIUS + 0.25
	torus.rings = 48
	ring.mesh = torus
	ring.material_override = _ring_mat
	ring.scale = Vector3(1.0, 0.05, 1.0)
	ring.position.y = 0.03
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)


func _build_palisade() -> void:
	var post_mat := BattlefieldEnvironment._flat_material(POST_COLOR)
	var r := Constants.BASE_CAPTURE_RADIUS + 1.2
	for i in PALISADE_POSTS:
		# Leave a gap (gate) facing +Z.
		var a := TAU * float(i) / float(PALISADE_POSTS)
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.45:
			continue
		var post := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.radial_segments = 5
		mesh.top_radius = 0.05
		mesh.bottom_radius = 0.18
		mesh.height = 2.2 + fmod(float(i) * 0.37, 0.6)
		post.mesh = mesh
		post.material_override = post_mat
		post.position = Vector3(cos(a) * r, mesh.height * 0.5, sin(a) * r)
		post.rotation = Vector3(0.12 * sin(a), 0.0, -0.12 * cos(a))
		add_child(post)


func _build_flag() -> void:
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.05
	pole_mesh.bottom_radius = 0.07
	pole_mesh.height = 7.0
	pole.mesh = pole_mesh
	pole.material_override = BattlefieldEnvironment._flat_material(Color(0.75, 0.72, 0.65))
	pole.position = Vector3(2.6, 3.5, -2.6)
	add_child(pole)
	var flag := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.8, 1.1)
	flag.mesh = quad
	_flag_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	flag.material_override = _flag_mat
	flag.position = Vector3(3.5, 6.3, -2.6)
	add_child(flag)


func _build_hive() -> Node3D:
	var root := Node3D.new()
	root.name = "Hive"
	var mound := MeshInstance3D.new()
	var dome := SphereMesh.new()
	dome.radial_segments = 10
	dome.rings = 6
	dome.radius = 2.4
	dome.height = 3.2
	mound.mesh = dome
	mound.material_override = _hive_mat
	mound.position.y = 0.6
	root.add_child(mound)
	for i in 5:
		var vent := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.35
		sphere.height = 0.5
		sphere.radial_segments = 6
		sphere.rings = 3
		vent.mesh = sphere
		vent.material_override = _vent_mat
		var a := TAU * float(i) / 5.0
		vent.position = Vector3(cos(a) * 1.7, 1.5 + 0.35 * sin(a * 2.0), sin(a) * 1.7)
		root.add_child(vent)
	add_child(root)
	return root


func _build_camp() -> Node3D:
	var root := Node3D.new()
	root.name = "Camp"
	var tent_mat := BattlefieldEnvironment._flat_material(Color(0.86, 0.82, 0.7))
	var trim_mat := BattlefieldEnvironment._flat_material(ALLY_COLOR)
	for i in 3:
		var tent := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.radial_segments = 6
		cone.top_radius = 0.0
		cone.bottom_radius = 1.4
		cone.height = 2.2
		tent.mesh = cone
		tent.material_override = tent_mat
		var a := TAU * float(i) / 3.0 + 0.5
		tent.position = Vector3(cos(a) * 3.2, 1.1, sin(a) * 3.2)
		root.add_child(tent)
		var band := MeshInstance3D.new()
		var ring := CylinderMesh.new()
		ring.radial_segments = 6
		ring.top_radius = 1.05
		ring.bottom_radius = 1.15
		ring.height = 0.18
		band.mesh = ring
		band.material_override = trim_mat
		band.position = tent.position + Vector3(0, -0.35, 0)
		root.add_child(band)
	add_child(root)
	return root
