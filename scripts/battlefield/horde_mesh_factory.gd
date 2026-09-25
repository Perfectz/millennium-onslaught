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
