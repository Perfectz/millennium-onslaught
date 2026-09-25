## Builds (and caches) low-poly, vertex-coloured biomonster meshes for horde grunts.
## One ArrayMesh per HordeUnitDef is shared by every grunt of that type.
class_name HordeMeshFactory
extends RefCounted


const EYE_WHITE := Color(0.96, 0.96, 0.9)
const EYE_PUPIL := Color(0.05, 0.03, 0.08)

static var _cache: Dictionary = {}
static var _material: StandardMaterial3D = null


## Shared unshaded-friendly material that uses vertex colours as albedo.
static func get_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 0.85
	return _material


## Mesh for a unit def (built on first request).
static func get_mesh(def: HordeUnitDef) -> ArrayMesh:
	var key := "%s|%s|%s|%s|%.2f" % [def.unit_id, def.body_style, def.body_color.to_html(), def.accent_color.to_html(), def.body_scale]
	if _cache.has(key):
		return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	match def.body_style:
		&"insect":
			_build_insect(st, def)
		&"brute":
			_build_brute(st, def)
		&"grub":
			_build_grub(st, def)
		&"mantis":
			_build_mantis(st, def)
		&"cone_slime":
			_build_cone_slime(st, def)
		&"beetle":
			_build_beetle(st, def)
		&"fly":
			_build_fly(st, def)
		&"newt":
			_build_newt(st, def)
		&"mushroom":
			_build_mushroom(st, def)
		&"spider_crab":
			_build_spider_crab(st, def)
		&"tentacle":
			_build_tentacle(st, def)
		&"bird":
			_build_bird(st, def)
		&"soldier":
			_build_soldier(st, def)
		_:
			_build_blob(st, def)
	var mesh := st.commit()
	mesh.surface_set_material(0, get_material())
	_cache[key] = mesh
	return mesh


static func _build_blob(st: SurfaceTool, def: HordeUnitDef) -> void:
	var s := def.body_scale
	var body := def.body_color
	_ellipsoid(st, Vector3(0, 0.45, 0) * s, Vector3(0.55, 0.45, 0.5) * s, body, 6, 9)
	_ellipsoid(st, Vector3(0, 0.12, 0) * s, Vector3(0.62, 0.14, 0.58) * s, body.darkened(0.25), 3, 9)
	# Eyes face +X (the grunt's forward axis).
	for side in [-1.0, 1.0]:
		_ellipsoid(st, Vector3(0.42, 0.62, 0.17 * side) * s, Vector3(0.13, 0.15, 0.13) * s, EYE_WHITE, 4, 6)
		_ellipsoid(st, Vector3(0.53, 0.63, 0.17 * side) * s, Vector3(0.05, 0.07, 0.06) * s, EYE_PUPIL, 3, 5)
		_box(st, Vector3(0.05, 0.9, 0.22 * side) * s, Vector3(0.1, 0.3, 0.1) * s, def.accent_color, Basis(Vector3.RIGHT, 0.35 * side))


static func _build_insect(st: SurfaceTool, def: HordeUnitDef) -> void:
	var s := def.body_scale
	var body := def.body_color
	_ellipsoid(st, Vector3(-0.35, 0.55, 0) * s, Vector3(0.42, 0.26, 0.26) * s, body.darkened(0.15), 5, 8)
	_ellipsoid(st, Vector3(0.1, 0.6, 0) * s, Vector3(0.24, 0.22, 0.22) * s, body, 5, 8)
	_ellipsoid(st, Vector3(0.42, 0.68, 0) * s, Vector3(0.18, 0.17, 0.17) * s, body.lightened(0.1), 4, 7)
	for side in [-1.0, 1.0]:
		_ellipsoid(st, Vector3(0.52, 0.74, 0.1 * side) * s, Vector3(0.07, 0.07, 0.07) * s, def.accent_color, 3, 5)
		_box(st, Vector3(0.6, 0.95, 0.08 * side) * s, Vector3(0.03, 0.35, 0.03) * s, body.darkened(0.3), Basis(Vector3.BACK, -0.6))
		# Three legs per side.
		for i in 3:
			var x := (0.25 - 0.28 * i) * s
			_box(st, Vector3(x, 0.32, 0.3 * side) * s, Vector3(0.05, 0.5, 0.05) * s, body.darkened(0.35), Basis(Vector3.RIGHT, 0.7 * side))
		# Wing.
		_box(st, Vector3(-0.3, 0.82, 0.22 * side) * s, Vector3(0.6, 0.02, 0.26) * s, def.accent_color.lightened(0.3), Basis(Vector3.RIGHT, 0.25 * side))


static func _build_brute(st: SurfaceTool, def: HordeUnitDef) -> void:
	var s := def.body_scale
	var body := def.body_color
	_ellipsoid(st, Vector3(0, 0.85, 0) * s, Vector3(0.5, 0.55, 0.55) * s, body, 6, 9)
	_ellipsoid(st, Vector3(0.28, 1.3, 0) * s, Vector3(0.26, 0.24, 0.26) * s, body.lightened(0.08), 5, 8)
	for side in [-1.0, 1.0]:
		_box(st, Vector3(0.15, 0.3, 0.25 * side) * s, Vector3(0.2, 0.6, 0.2) * s, body.darkened(0.3), Basis.IDENTITY)
		_box(st, Vector3(0.2, 0.8, 0.62 * side) * s, Vector3(0.2, 0.7, 0.2) * s, body.darkened(0.15), Basis(Vector3.RIGHT, 0.3 * side))
		_ellipsoid(st, Vector3(0.5, 1.35, 0.1 * side) * s, Vector3(0.05, 0.05, 0.05) * s, def.accent_color, 3, 5)
		_box(st, Vector3(0.5, 1.18, 0.12 * side) * s, Vector3(0.05, 0.16, 0.05) * s, EYE_WHITE, Basis(Vector3.BACK, -0.5))


## Flat-shaded UV ellipsoid.
static func _ellipsoid(st: SurfaceTool, center: Vector3, radii: Vector3, color: Color, rings: int, segments: int) -> void:
	var rows: Array[PackedVector3Array] = []
	for r in rings + 1:
		var phi := PI * float(r) / float(rings)
		var row := PackedVector3Array()
		for sgi in segments:
			var theta := TAU * float(sgi) / float(segments)
			row.append(center + Vector3(sin(phi) * cos(theta) * radii.x, cos(phi) * radii.y, sin(phi) * sin(theta) * radii.z))
		rows.append(row)
	for r in rings:
		for sgi in segments:
			var n := (sgi + 1) % segments
			var a := rows[r][sgi]
			var b := rows[r][n]
			var c := rows[r + 1][n]
			var d := rows[r + 1][sgi]
			if r > 0:
				_tri(st, a, b, d, color)
			if r < rings - 1:
				_tri(st, b, c, d, color)


## Flat-shaded oriented box.
static func _box(st: SurfaceTool, center: Vector3, size: Vector3, color: Color, basis: Basis) -> void:
	var h := size * 0.5
	var c: Array[Vector3] = []
	for i in 8:
		var local := Vector3(h.x if i & 1 else -h.x, h.y if i & 2 else -h.y, h.z if i & 4 else -h.z)
		c.append(center + basis * local)
	var faces := [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]]
	for f: Array in faces:
		_tri(st, c[f[0]], c[f[2]], c[f[1]], color)
		_tri(st, c[f[0]], c[f[3]], c[f[2]], color)


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var normal := (b - a).cross(c - a)
	if normal.length_squared() < 1e-12:
		return
	normal = -normal.normalized()
	for v: Vector3 in [a, b, c]:
		st.set_color(color)
		st.set_normal(normal)
		st.add_vertex(v)


# --- PSIV families (modelled after the original sprites; forward is +X) ---

## Crawler / Carrion Crawler / Caterpillar: an upright, ribbed grub rearing up.
static func _build_grub(st: SurfaceTool, def: HordeUnitDef) -> void:
	var s := def.body_scale
	var c := def.body_color
	for i in 5:
		var t := float(i) / 4.0
		var center := Vector3(0.12 * sin(t * 2.4), 0.2 + t * 0.95, 0.0) * s
		var r := lerpf(0.36, 0.22, t)
		_ellipsoid(st, center, Vector3(r, 0.17, r) * s, c if i % 2 == 0 else c.darkened(0.2), 4, 8)
	_ellipsoid(st, Vector3(0.22, 1.25, 0) * s, Vector3(0.2, 0.18, 0.2) * s, c.lightened(0.1), 4, 8)
	for side in [-1.0, 1.0]:
		_ellipsoid(st, Vector3(0.36, 1.3, 0.09 * side) * s, Vector3(0.06, 0.06, 0.06) * s, def.accent_color, 3, 5)
		for i in 3:
			_box(st, Vector3(0.18, 0.35 + i * 0.22, 0.28 * side) * s, Vector3(0.18, 0.04, 0.04) * s, c.darkened(0.35), Basis(Vector3.RIGHT, 0.5 * side))


## Locusta: hunched spiky mantis with big raptorial claws.
static func _build_mantis(st: SurfaceTool, def: HordeUnitDef) -> void:
	var s := def.body_scale
	var c := def.body_color
	_ellipsoid(st, Vector3(-0.15, 0.75, 0) * s, Vector3(0.3, 0.42, 0.28) * s, c, 5, 8)
	_ellipsoid(st, Vector3(0.2, 1.15, 0) * s, Vector3(0.2, 0.2, 0.2) * s, c.lightened(0.1), 4, 7)
	for side in [-1.0, 1.0]:
		_ellipsoid(st, Vector3(0.34, 1.2, 0.1 * side) * s, Vector3(0.07, 0.07, 0.07) * s, def.accent_color, 3, 5)
		# Raptorial claw: upper arm + forearm blade.
		_box(st, Vector3(0.25, 0.95, 0.3 * side) * s, Vector3(0.4, 0.08, 0.08) * s, c.darkened(0.15), Basis(Vector3.BACK, 0.5))
		_box(st, Vector3(0.48, 0.78, 0.3 * side) * s, Vector3(0.06, 0.45, 0.06) * s, c.lightened(0.2), Basis(Vector3.BACK, -0.3))
		_box(st, Vector3(-0.1, 0.3, 0.22 * side) * s, Vector3(0.07, 0.6, 0.07) * s, c.darkened(0.3), Basis(Vector3.RIGHT, 0.3 * side))
		# Back spikes.
		_box(st, Vector3(-0.4, 1.05, 0.1 * side) * s, Vector3(0.05, 0.3, 0.05) * s, def.accent_color.darkened(0.2), Basis(Vector3.BACK, 0.6))


## Blob / Zol Slug / Jr. Ooze: a squat cone of slime with a face.
static func _build_cone_slime(st: SurfaceTool, def: HordeUnitDef) -> void:
	var s := def.body_scale
	var c := def.body_color
	_cone(st, Vector3(0, 0.0, 0) * s, 0.5 * s, 0.95 * s, c, 9)
	_ellipsoid(st, Vector3(0, 0.08, 0) * s, Vector3(0.56, 0.1, 0.56) * s, c.darkened(0.2), 3, 9)
	for side in [-1.0, 1.0]:
		_ellipsoid(st, Vector3(0.27, 0.45, 0.12 * side) * s, Vector3(0.07, 0.09, 0.07) * s, EYE_WHITE, 3, 5)
		_ellipsoid(st, Vector3(0.33, 0.45, 0.12 * side) * s, Vector3(0.03, 0.05, 0.04) * s, EYE_PUPIL, 3, 4)
	_ellipsoid(st, Vector3(0, 0.92, 0) * s, Vector3(0.08, 0.1, 0.08) * s, def.accent_color, 3, 5)


## Whistle: a domed beetle on short legs.
static func _build_beetle(st: SurfaceTool, def: HordeUnitDef) -> void:
	var s := def.body_scale
	var c := def.body_color
	_ellipsoid(st, Vector3(0, 0.45, 0) * s, Vector3(0.5, 0.38, 0.42) * s, c, 5, 10)
	_box(st, Vector3(0, 0.62, 0) * s, Vector3(0.9, 0.03, 0.04) * s, c.darkened(0.4), Basis.IDENTITY)
	_ellipsoid(st, Vector3(0.45, 0.35, 0) * s, Vector3(0.18, 0.15, 0.2) * s, c.darkened(0.25), 4, 7)
	for side in [-1.0, 1.0]:
		_ellipsoid(st, Vector3(0.58, 0.42, 0.1 * side) * s, Vector3(0.05, 0.05, 0.05) * s, def.accent_color, 3, 5)
		for i in 3:
			_box(st, Vector3(0.25 - i * 0.25, 0.15, 0.4 * side) * s, Vector3(0.05, 0.3, 0.05) * s, c.darkened(0.45), Basis(Vector3.RIGHT, 0.6 * side))


## Monsterfly: a hovering insect with large pale wings.
static func _build_fly(st: SurfaceTool, def: HordeUnitDef) -> void:
	var s := def.body_scale
	var c := def.body_color
	var lift := 0.7
	_ellipsoid(st, Vector3(-0.2, lift, 0) * s, Vector3(0.32, 0.18, 0.18) * s, c.darkened(0.1), 4, 7)
	_ellipsoid(st, Vector3(0.12, lift + 0.05, 0) * s, Vector3(0.16, 0.15, 0.15) * s, c, 4, 7)
	_ellipsoid(st, Vector3(0.32, lift + 0.08, 0) * s, Vector3(0.12, 0.12, 0.13) * s, c.lightened(0.1), 4, 6)
	for side in [-1.0, 1.0]:
		_ellipsoid(st, Vector3(0.4, lift + 0.12, 0.08 * side) * s, Vector3(0.06, 0.07, 0.06) * s, def.accent_color, 3, 5)
		_box(st, Vector3(0.0, lift + 0.25, 0.42 * side) * s, Vector3(0.5, 0.02, 0.6) * s, Color(0.95, 0.97, 1.0), Basis(Vector3.RIGHT, 0.35 * side))
		_box(st, Vector3(0.1, lift - 0.25, 0.1 * side) * s, Vector3(0.03, 0.35, 0.03) * s, c.darkened(0.4), Basis.IDENTITY)


## Sand Newt / Flame Newt: a flat, splayed lizard.
static func _build_newt(st: SurfaceTool, def: HordeUnitDef) -> void:
	var s := def.body_scale
	var c := def.body_color
	_ellipsoid(st, Vector3(0, 0.22, 0) * s, Vector3(0.5, 0.16, 0.3) * s, c, 4, 9)
	_ellipsoid(st, Vector3(0.52, 0.26, 0) * s, Vector3(0.22, 0.13, 0.2) * s, c.lightened(0.08), 4, 7)
	_box(st, Vector3(-0.7, 0.15, 0) * s, Vector3(0.6, 0.06, 0.1) * s, c.darkened(0.2), Basis(Vector3.BACK, 0.15))
	_box(st, Vector3(-0.1, 0.4, 0) * s, Vector3(0.7, 0.08, 0.06) * s, def.accent_color, Basis.IDENTITY)
	for side in [-1.0, 1.0]:
		_ellipsoid(st, Vector3(0.62, 0.36, 0.1 * side) * s, Vector3(0.05, 0.05, 0.05) * s, EYE_WHITE, 3, 5)
		for x in [0.3, -0.3]:
			_box(st, Vector3(x, 0.1, 0.38 * side) * s, Vector3(0.08, 0.06, 0.3) * s, c.darkened(0.3), Basis(Vector3.UP, 0.4 * side))


## Toadstool: a mushroom creature with a broad spotted cap.
static func _build_mushroom(st: SurfaceTool, def: HordeUnitDef) -> void:
	var s := def.body_scale
	var c := def.body_color
	_ellipsoid(st, Vector3(0, 0.35, 0) * s, Vector3(0.24, 0.35, 0.24) * s, Color(0.92, 0.88, 0.75), 4, 8)
	_ellipsoid(st, Vector3(0, 0.82, 0) * s, Vector3(0.55, 0.3, 0.55) * s, c, 5, 10)
	for i in 5:
		var a := TAU * float(i) / 5.0
		_ellipsoid(st, Vector3(cos(a) * 0.32, 0.98, sin(a) * 0.32) * s, Vector3(0.08, 0.05, 0.08) * s, def.accent_color, 3, 5)
	for side in [-1.0, 1.0]:
		_ellipsoid(st, Vector3(0.2, 0.45, 0.09 * side) * s, Vector3(0.05, 0.06, 0.05) * s, EYE_PUPIL, 3, 5)


## Igglanova / Guilgenova / Tarantella: a wide spider-crab with pincers.
static func _build_spider_crab(st: SurfaceTool, def: HordeUnitDef) -> void:
	var s := def.body_scale
	var c := def.body_color
	_ellipsoid(st, Vector3(0, 0.6, 0) * s, Vector3(0.55, 0.35, 0.6) * s, c, 5, 10)
	_ellipsoid(st, Vector3(0.45, 0.72, 0) * s, Vector3(0.22, 0.2, 0.28) * s, c.lightened(0.1), 4, 7)
	for side in [-1.0, 1.0]:
		_ellipsoid(st, Vector3(0.6, 0.85, 0.12 * side) * s, Vector3(0.06, 0.06, 0.06) * s, def.accent_color, 3, 5)
		_box(st, Vector3(0.7, 0.6, 0.45 * side) * s, Vector3(0.45, 0.12, 0.12) * s, c.darkened(0.2), Basis(Vector3.UP, -0.5 * side))
		_ellipsoid(st, Vector3(1.0, 0.6, 0.62 * side) * s, Vector3(0.2, 0.12, 0.1) * s, def.accent_color.darkened(0.2), 3, 6)
		for i in 3:
			var x := (0.25 - 0.3 * i)
			_box(st, Vector3(x, 0.35, 0.65 * side) * s, Vector3(0.07, 0.07, 0.6) * s, c.darkened(0.35), Basis(Vector3.RIGHT, 0.7 * side))


## Xanafalgue / Gicefalgue: a bulb-headed creature on tentacle legs.
static func _build_tentacle(st: SurfaceTool, def: HordeUnitDef) -> void:
	var s := def.body_scale
	var c := def.body_color
	_ellipsoid(st, Vector3(0, 1.0, 0) * s, Vector3(0.42, 0.4, 0.42) * s, c, 5, 9)
	_ellipsoid(st, Vector3(0.3, 0.95, 0) * s, Vector3(0.14, 0.2, 0.28) * s, def.accent_color, 4, 7)
	for i in 5:
		var a := TAU * float(i) / 5.0
		_box(st, Vector3(cos(a) * 0.3, 0.4, sin(a) * 0.3) * s, Vector3(0.1, 0.8, 0.1) * s, c.darkened(0.25), Basis(Vector3(sin(a), 0, -cos(a)), 0.35))


## Rappy: a round, flightless bird.
static func _build_bird(st: SurfaceTool, def: HordeUnitDef) -> void:
	var s := def.body_scale
	var c := def.body_color
	_ellipsoid(st, Vector3(0, 0.5, 0) * s, Vector3(0.42, 0.4, 0.38) * s, c, 5, 9)
	_cone(st, Vector3(0.38, 0.55, 0) * s, 0.08 * s, 0.22 * s, def.accent_color, 5, Basis(Vector3.BACK, -PI * 0.5))
	_ellipsoid(st, Vector3(-0.1, 0.92, 0) * s, Vector3(0.06, 0.12, 0.06) * s, def.accent_color, 3, 5)
	for side in [-1.0, 1.0]:
		_ellipsoid(st, Vector3(0.3, 0.68, 0.14 * side) * s, Vector3(0.07, 0.08, 0.06) * s, EYE_WHITE, 3, 5)
		_ellipsoid(st, Vector3(0.35, 0.68, 0.14 * side) * s, Vector3(0.03, 0.05, 0.04) * s, EYE_PUPIL, 3, 4)
		_box(st, Vector3(0.0, 0.08, 0.16 * side) * s, Vector3(0.05, 0.18, 0.05) * s, def.accent_color, Basis.IDENTITY)


## Speard / Zio's Guard: an armoured humanoid spearman.
static func _build_soldier(st: SurfaceTool, def: HordeUnitDef) -> void:
	var s := def.body_scale
	var c := def.body_color
	_box(st, Vector3(0, 1.05, 0) * s, Vector3(0.3, 0.55, 0.45) * s, c, Basis.IDENTITY)
	_ellipsoid(st, Vector3(0, 1.5, 0) * s, Vector3(0.16, 0.18, 0.16) * s, c.lightened(0.15), 4, 7)
	_box(st, Vector3(0.12, 1.5, 0) * s, Vector3(0.06, 0.06, 0.26) * s, def.accent_color, Basis.IDENTITY)
	for side in [-1.0, 1.0]:
		_box(st, Vector3(0, 0.45, 0.13 * side) * s, Vector3(0.14, 0.75, 0.14) * s, c.darkened(0.25), Basis.IDENTITY)
		_box(st, Vector3(0.05, 1.05, 0.3 * side) * s, Vector3(0.11, 0.5, 0.11) * s, c.darkened(0.1), Basis(Vector3.BACK, 0.25))
	# Spear held forward.
	_box(st, Vector3(0.45, 1.0, 0.3) * s, Vector3(1.4, 0.04, 0.04) * s, Color(0.7, 0.7, 0.75), Basis(Vector3.BACK, 0.12))
	_cone(st, Vector3(1.15, 1.08, 0.3) * s, 0.06 * s, 0.25 * s, def.accent_color.lightened(0.3), 4, Basis(Vector3.BACK, -PI * 0.5))


## Flat-shaded cone standing on `base` (optionally rotated by `basis` about its base).
static func _cone(st: SurfaceTool, base: Vector3, radius: float, height: float, color: Color, segments: int, basis: Basis = Basis.IDENTITY) -> void:
	var tip := base + basis * Vector3(0, height, 0)
	for i in segments:
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		var p0 := base + basis * Vector3(cos(a0) * radius, 0, sin(a0) * radius)
		var p1 := base + basis * Vector3(cos(a1) * radius, 0, sin(a1) * radius)
		_tri(st, p0, tip, p1, color)
		_tri(st, p0, p1, base, color.darkened(0.3))
