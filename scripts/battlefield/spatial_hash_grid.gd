## Uniform 2D (XZ) spatial hash for fast neighbour queries across large hordes.
## Rebuilt each physics frame: clear() then insert() every agent. Ids should be small,
## dense integers (e.g. indices into an active list) — points live in a packed array.
class_name SpatialHashGrid
extends RefCounted


var _cell_size: float
var _inv_cell: float
var _cells: Dictionary = {}  # int cell key -> Array[int] of ids (reference type: no copy-on-write)
var _points := PackedVector2Array()
var _present := PackedByteArray()


func _init(cell_size: float = Constants.HORDE_SPATIAL_CELL_SIZE) -> void:
	_cell_size = maxf(cell_size, 0.01)
	_inv_cell = 1.0 / _cell_size


## Remove every point (cell arrays are kept to avoid reallocation).
func clear() -> void:
	for bucket: Array in _cells.values():
		bucket.clear()
	_present.fill(0)


## Add a point with a non-negative integer id.
func insert(id: int, pos: Vector2) -> void:
	if id >= _points.size():
		var n := maxi(id + 1, _points.size() * 2)
		_points.resize(n)
		_present.resize(n)
	_points[id] = pos
	_present[id] = 1
	var key := _key(floori(pos.x * _inv_cell), floori(pos.y * _inv_cell))
	var bucket: Array = _cells.get(key, [])
	if bucket.is_empty() and not _cells.has(key):
		_cells[key] = bucket
	bucket.append(id)


## Fill `out` with ids whose points lie within `radius` of `center`. `out` is cleared first.
func query_radius(center: Vector2, radius: float, out: PackedInt32Array) -> void:
	out.clear()
	var r2 := radius * radius
	var x0 := floori((center.x - radius) * _inv_cell)
	var x1 := floori((center.x + radius) * _inv_cell)
	var y0 := floori((center.y - radius) * _inv_cell)
	var y1 := floori((center.y + radius) * _inv_cell)
	for cx in range(x0, x1 + 1):
		for cy in range(y0, y1 + 1):
			var key := _key(cx, cy)
			if not _cells.has(key):
				continue
			var bucket: Array = _cells[key]
			for id: int in bucket:
				if _points[id].distance_squared_to(center) <= r2:
					out.append(id)


## Sum of HordeSteering.separation() pushes on point `id` from every other point within
## `radius`, computed in one pass without allocating.
func separation_sum(id: int, radius: float) -> Vector2:
	if id < 0 or id >= _present.size() or _present[id] == 0:
		return Vector2.ZERO
	var center := _points[id]
	var r2 := radius * radius
	var inv_r := 1.0 / radius
	var total := Vector2.ZERO
	var x0 := floori((center.x - radius) * _inv_cell)
	var x1 := floori((center.x + radius) * _inv_cell)
	var y0 := floori((center.y - radius) * _inv_cell)
	var y1 := floori((center.y + radius) * _inv_cell)
	for cx in range(x0, x1 + 1):
		for cy in range(y0, y1 + 1):
			var key := _key(cx, cy)
			if not _cells.has(key):
				continue
			var bucket: Array = _cells[key]
			for other: int in bucket:
				if other == id:
					continue
				var offset := center - _points[other]
				var d2 := offset.length_squared()
				if d2 >= r2:
					continue
				if d2 < 0.00000001:
					total += HordeSteering.separation(center, center, radius)
					continue
				var d := sqrt(d2)
				total += offset / d * (1.0 - d * inv_r)
	return total


static func _key(cx: int, cy: int) -> int:
	# Pack two signed cell coordinates into one int key (exact for |c| < 2^31).
	return (cx << 32) ^ (cy & 0xFFFFFFFF)
