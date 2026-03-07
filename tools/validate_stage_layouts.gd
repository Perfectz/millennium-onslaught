## CLI validator for StageDef resources and generated stage layout contracts.
extends SceneTree


const STAGE_ROOT := "res://resources/stages"


func _initialize() -> void:
	var stage_paths := _find_stage_resources(STAGE_ROOT)
	var had_errors := false
	var total_warnings := 0

	for stage_path in stage_paths:
		var stage_def := load(stage_path) as StageDef
		if stage_def == null:
			continue
		var audit: Dictionary = StageValidator.audit_stage(stage_def)
		var errors: Array[String] = audit.get("errors", [])
		var warnings: Array[String] = audit.get("warnings", [])
		total_warnings += warnings.size()
		if errors.is_empty():
			print("[StageLayouts] %s OK (%d warnings)" % [stage_def.stage_id, warnings.size()])
			for warning in warnings:
				push_warning("  - %s" % warning)
			continue
		had_errors = true
		push_error("[StageLayouts] %s failed with %d errors" % [stage_def.stage_id, errors.size()])
		for error in errors:
			push_error("  - %s" % error)
		for warning in warnings:
			push_warning("  - warning: %s" % warning)

	print("[StageLayouts] Checked %d stage resources (%d warnings)." % [stage_paths.size(), total_warnings])
	quit(1 if had_errors else 0)


func _find_stage_resources(root_path: String) -> Array[String]:
	var results: Array[String] = []
	_walk_stage_dir(root_path, results)
	results.sort()
	return results


func _walk_stage_dir(path: String, results: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry == "":
			break
		if entry.begins_with("."):
			continue
		var full_path := "%s/%s" % [path, entry]
		if dir.current_is_dir():
			_walk_stage_dir(full_path, results)
		elif entry.ends_with(".tres"):
			results.append(full_path)
	dir.list_dir_end()
