## Debug tool - validates StageDef data and generated stage scene layout.
class_name StageValidator
extends RefCounted


const FLOAT_TOLERANCE := 0.05
const OPEN_SIDE_CLEARANCE_X := 6.0
const OPEN_SIDE_CLEARANCE_Z := 4.5
const EXIT_APPROACH_CLEARANCE_X := 8.0
const EXIT_APPROACH_CLEARANCE_Z := 2.5
const COMBAT_LANE_HALF_Z := 5.0
const ACADEMY_ROOM_PREFIX := "res://scenes/dungeon/rooms/academy_"


## Validate a StageDef and return errors + warnings separately.
static func audit_stage(stage_def: StageDef) -> Dictionary:
	if stage_def == null:
		return {
			"errors": ["stage_def is null"],
			"warnings": [],
		}

	var errors: Array[String] = stage_def.validate()
	var warnings: Array[String] = _check_encounter_spacing(stage_def)
	errors.append_array(_check_chunk_scenes_loadable(stage_def))
	errors.append_array(_check_chunk_scene_layout(stage_def, warnings))

	return {
		"errors": errors,
		"warnings": warnings,
	}


## Validate an instantiated chunk/room against stage layout contracts.
## Context keys: `path`, `expected_width`, `chunk_index`, `total_chunks`.
static func audit_chunk_layout(chunk: Node, context: Dictionary = {}) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	if chunk == null:
		return {
			"errors": ["chunk is null"],
			"warnings": warnings,
		}

	var path: String = String(context.get("path", ""))
	var label: String = _context_label(chunk, path)
	var floor_info: Dictionary = _get_floor_info(chunk)
	if floor_info.is_empty():
		errors.append("%s missing Floor/CollisionShape3D" % label)
		return {
			"errors": errors,
			"warnings": warnings,
		}
	if not bool(floor_info.get("valid_shape", false)):
		errors.append("%s floor collision is not BoxShape3D" % label)
		return {
			"errors": errors,
			"warnings": warnings,
		}

	var floor_size: Vector3 = floor_info.get("size", Vector3.ZERO)
	var floor_origin: Vector3 = floor_info.get("origin", Vector3.ZERO)
	var expected_width: float = float(context.get("expected_width", 0.0))
	if expected_width > 0.0 and not _approx_eq(floor_size.x, expected_width):
		errors.append("%s floor width %.2f does not match stage chunk_width %.2f" % [
			label,
			floor_size.x,
			expected_width,
		])

	var expected_origin_x: float = floor_size.x * 0.5
	if not _approx_eq(floor_origin.x, expected_origin_x):
		errors.append("%s floor origin.x %.2f should be centered at %.2f" % [
			label,
			floor_origin.x,
			expected_origin_x,
		])
	if not _approx_eq(floor_origin.z, 0.0):
		errors.append("%s floor origin.z %.2f should be 0.0 for seamless tiling" % [
			label,
			floor_origin.z,
		])

	var chunk_index: int = int(context.get("chunk_index", 0))
	var total_chunks: int = maxi(int(context.get("total_chunks", 1)), 1)
	var is_final_chunk: bool = chunk_index == total_chunks - 1
	var exit_area: Area3D = _find_stage_exit_area(chunk)
	if exit_area != null:
		if not is_final_chunk:
			errors.append("%s exposes StageExitArea before the final chunk" % label)
		errors.append_array(_check_stage_exit_area(chunk, label, path, floor_size.x, exit_area))

	if _is_academy_room(path):
		errors.append_array(_check_academy_combat_lane(chunk, label, floor_size.x))
		if chunk_index > 0:
			errors.append_array(_check_open_side_clearance(chunk, label, floor_size.x, "west"))
		if chunk_index < total_chunks - 1:
			errors.append_array(_check_open_side_clearance(chunk, label, floor_size.x, "east"))

	return {
		"errors": errors,
		"warnings": warnings,
	}


## Validate adjacent chunk seam compatibility.
## Context keys: `left_path`, `right_path`.
static func audit_chunk_seam(left_chunk: Node, right_chunk: Node, context: Dictionary = {}) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	if left_chunk == null or right_chunk == null:
		return {
			"errors": errors,
			"warnings": warnings,
		}

	var left_path: String = String(context.get("left_path", ""))
	var right_path: String = String(context.get("right_path", ""))
	var left_label: String = _context_label(left_chunk, left_path)
	var right_label: String = _context_label(right_chunk, right_path)
	var left_info: Dictionary = _get_floor_info(left_chunk)
	var right_info: Dictionary = _get_floor_info(right_chunk)
	if left_info.is_empty() or right_info.is_empty():
		return {
			"errors": errors,
			"warnings": warnings,
		}
	if not bool(left_info.get("valid_shape", false)) or not bool(right_info.get("valid_shape", false)):
		return {
			"errors": errors,
			"warnings": warnings,
		}

	var left_size: Vector3 = left_info.get("size", Vector3.ZERO)
	var right_size: Vector3 = right_info.get("size", Vector3.ZERO)
	var left_origin: Vector3 = left_info.get("origin", Vector3.ZERO)
	var right_origin: Vector3 = right_info.get("origin", Vector3.ZERO)
	var left_top_y: float = float(left_info.get("top_y", 0.0))
	var right_top_y: float = float(right_info.get("top_y", 0.0))

	if not _approx_eq(left_size.z, right_size.z):
		errors.append("adjacent chunk floor depths mismatch between %s and %s: %.2f vs %.2f" % [
			left_label,
			right_label,
			left_size.z,
			right_size.z,
		])
	if not _approx_eq(left_origin.z, right_origin.z):
		errors.append("adjacent chunk floor center.z mismatch between %s and %s: %.2f vs %.2f" % [
			left_label,
			right_label,
			left_origin.z,
			right_origin.z,
		])
	if not _approx_eq(left_top_y, right_top_y):
		errors.append("adjacent chunk floor top height mismatch between %s and %s: %.2f vs %.2f" % [
			left_label,
			right_label,
			left_top_y,
			right_top_y,
		])

	return {
		"errors": errors,
		"warnings": warnings,
	}


## Validate a StageDef and print results to console.
static func validate_and_print(stage_def: StageDef) -> bool:
	var audit: Dictionary = audit_stage(stage_def)
	var errors: Array[String] = audit.get("errors", [])
	var warnings: Array[String] = audit.get("warnings", [])

	if errors.is_empty():
		print("[StageValidator] %s: VALID (%d chunks, %d encounters, %.0f units)" % [
			stage_def.stage_id,
			stage_def.chunk_scenes.size(),
			stage_def.get_encounter_count(),
			stage_def.get_total_width()
		])
		for warning in warnings:
			push_warning("[StageValidator] %s warning: %s" % [stage_def.stage_id, warning])
		return true

	push_warning("[StageValidator] %s: %d errors found:" % [stage_def.stage_id, errors.size()])
	for err in errors:
		push_warning("  - %s" % err)
	for warning in warnings:
		push_warning("  - warning: %s" % warning)
	return false


## Check that all chunk scene paths can be loaded.
static func _check_chunk_scenes_loadable(stage_def: StageDef) -> Array[String]:
	var errors: Array[String] = []
	for i in stage_def.chunk_scenes.size():
		var path: String = stage_def.chunk_scenes[i]
		if not ResourceLoader.exists(path):
			errors.append("chunk_scenes[%d] path does not exist: %s" % [i, path])
	return errors


## Check minimum spacing between encounters to flag cramped pacing.
static func _check_encounter_spacing(stage_def: StageDef) -> Array[String]:
	var warnings: Array[String] = []
	var recommended_spacing: float = stage_def.chunk_width * 0.75
	for i in range(1, stage_def.encounters.size()):
		if stage_def.encounters[i] == null or stage_def.encounters[i - 1] == null:
			continue
		var spacing: float = stage_def.encounters[i].trigger_x - stage_def.encounters[i - 1].trigger_x
		if spacing < recommended_spacing:
			warnings.append("encounters [%d->%d] spacing %.1f < recommended %.1f" % [
				i - 1, i, spacing, recommended_spacing])
	return warnings


## Check chunk scenes for basic runtime layout contracts.
static func _check_chunk_scene_layout(stage_def: StageDef, warnings: Array[String]) -> Array[String]:
	var errors: Array[String] = []
	var chunk_entries: Array[Dictionary] = []
	var total_chunks: int = stage_def.chunk_scenes.size()
	for i in stage_def.chunk_scenes.size():
		var path: String = stage_def.chunk_scenes[i]
		var scene: PackedScene = load(path) as PackedScene
		if scene == null:
			errors.append("chunk_scenes[%d] failed to load PackedScene: %s" % [i, path])
			continue
		var chunk: Node = scene.instantiate() as Node
		if chunk == null:
			errors.append("chunk_scenes[%d] failed to instantiate: %s" % [i, path])
			continue

		var audit: Dictionary = audit_chunk_layout(chunk, {
			"path": path,
			"expected_width": stage_def.chunk_width,
			"chunk_index": i,
			"total_chunks": total_chunks,
		})
		errors.append_array(audit.get("errors", []))
		warnings.append_array(audit.get("warnings", []))
		chunk_entries.append({
			"path": path,
			"chunk": chunk,
		})

	for i in range(1, chunk_entries.size()):
		var seam_audit: Dictionary = audit_chunk_seam(
			chunk_entries[i - 1].get("chunk") as Node,
			chunk_entries[i].get("chunk") as Node,
			{
				"left_path": chunk_entries[i - 1].get("path", ""),
				"right_path": chunk_entries[i].get("path", ""),
			}
		)
		errors.append_array(seam_audit.get("errors", []))
		warnings.append_array(seam_audit.get("warnings", []))

	for entry in chunk_entries:
		var chunk := entry.get("chunk") as Node
		if chunk != null:
			chunk.free()
	return errors


static func _check_stage_exit_area(
		chunk: Node,
		label: String,
		path: String,
		room_width: float,
		exit_area: Area3D
	) -> Array[String]:
	var errors: Array[String] = []
	if exit_area.collision_mask != Constants.LAYER_PLAYER:
		errors.append("%s StageExitArea collision_mask %d should target player layer %d" % [
			label,
			exit_area.collision_mask,
			Constants.LAYER_PLAYER,
		])
	if not exit_area.monitoring or not exit_area.monitorable:
		errors.append("%s StageExitArea must stay monitoring + monitorable" % label)

	var collision: CollisionShape3D = exit_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null:
		errors.append("%s StageExitArea missing CollisionShape3D" % label)
	elif not (collision.shape is BoxShape3D):
		errors.append("%s StageExitArea collision is not BoxShape3D" % label)

	var blocked_by: Array[String] = _collect_exit_boundary_blockers(chunk, exit_area.transform.origin.z)
	if not blocked_by.is_empty():
		errors.append("%s exit lane is blocked by %s" % [label, blocked_by])

	if _is_academy_room(path):
		var prop_blockers: Array[String] = _find_props_in_exit_approach(chunk, room_width, exit_area.transform.origin.z)
		if not prop_blockers.is_empty():
			errors.append("%s exit approach is blocked by %s" % [label, prop_blockers])

	return errors


static func _check_open_side_clearance(
		chunk: Node,
		label: String,
		room_width: float,
		side: String
	) -> Array[String]:
	var blockers: Array[String] = []
	for prop in _get_major_props(chunk):
		var origin := prop.transform.origin
		var in_side_band := false
		if side == "west":
			in_side_band = origin.x <= OPEN_SIDE_CLEARANCE_X
		elif side == "east":
			in_side_band = origin.x >= room_width - OPEN_SIDE_CLEARANCE_X
		if in_side_band and absf(origin.z) <= OPEN_SIDE_CLEARANCE_Z:
			blockers.append("%s@%s" % [prop.name, origin])

	if blockers.is_empty():
		return []
	return ["%s %s seam approach is blocked by %s" % [label, side, blockers]]


static func _check_academy_combat_lane(chunk: Node, label: String, room_width: float) -> Array[String]:
	var blockers: Array[String] = []
	for prop in _get_major_props(chunk):
		var origin := prop.transform.origin
		var outside_lane := absf(origin.z) >= COMBAT_LANE_HALF_Z or origin.x <= 4.0 or origin.x >= room_width - 4.0
		if not outside_lane:
			blockers.append("%s@%s" % [prop.name, origin])

	if blockers.is_empty():
		return []
	return ["%s combat lane is blocked by %s" % [label, blockers]]


static func _find_stage_exit_area(chunk: Node) -> Area3D:
	var exit_area := chunk.get_node_or_null("StageExitArea") as Area3D
	if exit_area == null:
		exit_area = chunk.find_child("StageExitArea", true, false) as Area3D
	return exit_area


static func _collect_exit_boundary_blockers(chunk: Node, exit_z: float) -> Array[String]:
	var blockers: Array[String] = []
	for child in chunk.get_children():
		if not (child is StaticBody3D):
			continue
		var child_name := String(child.name)
		if not child_name.begins_with("EastBoundary"):
			continue
		var boundary: StaticBody3D = child as StaticBody3D
		var collision: CollisionShape3D = boundary.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if collision == null or not (collision.shape is BoxShape3D):
			continue
		var shape: BoxShape3D = collision.shape as BoxShape3D
		var half_z: float = shape.size.z * 0.5
		var min_z: float = boundary.transform.origin.z - half_z
		var max_z: float = boundary.transform.origin.z + half_z
		if exit_z >= min_z and exit_z <= max_z:
			blockers.append(child_name)
	return blockers


static func _find_props_in_exit_approach(chunk: Node, room_width: float, exit_z: float) -> Array[String]:
	var blockers: Array[String] = []
	for prop in _get_major_props(chunk):
		var origin := prop.transform.origin
		var in_exit_lane := origin.x >= room_width - EXIT_APPROACH_CLEARANCE_X and absf(origin.z - exit_z) <= EXIT_APPROACH_CLEARANCE_Z
		if in_exit_lane:
			blockers.append("%s@%s" % [prop.name, origin])
	return blockers


static func _get_major_props(chunk: Node) -> Array[Node3D]:
	var props: Array[Node3D] = []
	var container: Node = _get_prop_container(chunk)
	if container == null:
		return props
	for child in container.get_children():
		if child is Node3D and _is_major_prop_name(String(child.name)):
			props.append(child as Node3D)
	return props


static func _get_prop_container(chunk: Node) -> Node:
	var visuals: Node = chunk.get_node_or_null("Visuals")
	if visuals != null:
		return visuals
	return chunk.get_node_or_null("Props")


static func _get_floor_info(chunk: Node) -> Dictionary:
	var floor_collision: CollisionShape3D = chunk.get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
	if floor_collision == null:
		return {}
	var floor_body: Node3D = chunk.get_node_or_null("Floor") as Node3D
	if floor_body == null:
		floor_body = floor_collision.get_parent() as Node3D
	if floor_body == null:
		return {}

	var info := {
		"origin": floor_body.transform.origin,
		"valid_shape": floor_collision.shape is BoxShape3D,
	}
	if floor_collision.shape is BoxShape3D:
		var shape: BoxShape3D = floor_collision.shape as BoxShape3D
		var scale: Vector3 = floor_body.transform.basis.get_scale()
		var scaled_size: Vector3 = Vector3(
			shape.size.x * absf(scale.x),
			shape.size.y * absf(scale.y),
			shape.size.z * absf(scale.z)
		)
		info["size"] = scaled_size
		info["top_y"] = floor_body.transform.origin.y + scaled_size.y * 0.5
	return info


static func _context_label(chunk: Node, path: String) -> String:
	if not path.is_empty():
		return path
	if chunk == null:
		return "<null chunk>"
	return String(chunk.name)


static func _is_academy_room(path: String) -> bool:
	return path.begins_with(ACADEMY_ROOM_PREFIX)


static func _is_major_prop_name(node_name: String) -> bool:
	var lower_name := node_name.to_lower()
	return not (
		lower_name.begins_with("floortile")
		or lower_name.contains("wall")
		or lower_name.begins_with("torch")
		or lower_name.contains("banner")
		or lower_name.ends_with("light")
		or lower_name.ends_with("stairs")
	)


static func _approx_eq(left: float, right: float, tolerance: float = FLOAT_TOLERANCE) -> bool:
	return absf(left - right) <= tolerance
