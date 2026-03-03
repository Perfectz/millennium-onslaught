## Debug tool — validates StageDef data at runtime.
## Run via StageValidator.validate_stage(stage_def) or press F9 during stage mode.
class_name StageValidator
extends RefCounted


## Validate a StageDef and print results to console.
static func validate_and_print(stage_def: StageDef) -> bool:
	if stage_def == null:
		push_error("StageValidator: stage_def is null")
		return false

	var errors := stage_def.validate()

	# Additional runtime checks.
	errors.append_array(_check_chunk_scenes_loadable(stage_def))
	errors.append_array(_check_encounter_spacing(stage_def))

	if errors.is_empty():
		print("[StageValidator] %s: VALID (%d chunks, %d encounters, %.0f units)" % [
			stage_def.stage_id,
			stage_def.chunk_scenes.size(),
			stage_def.get_encounter_count(),
			stage_def.get_total_width()
		])
		return true
	else:
		push_warning("[StageValidator] %s: %d errors found:" % [stage_def.stage_id, errors.size()])
		for err in errors:
			push_warning("  - %s" % err)
		return false


## Check that all chunk scene paths can be loaded.
static func _check_chunk_scenes_loadable(stage_def: StageDef) -> Array[String]:
	var errors: Array[String] = []
	for i in stage_def.chunk_scenes.size():
		var path := stage_def.chunk_scenes[i]
		if not ResourceLoader.exists(path):
			errors.append("chunk_scenes[%d] path does not exist: %s" % [i, path])
	return errors


## Check minimum spacing between encounters (pacing rule: ≥ 2 chunks apart).
static func _check_encounter_spacing(stage_def: StageDef) -> Array[String]:
	var warnings: Array[String] = []
	var min_spacing := stage_def.chunk_width * 2.0
	for i in range(1, stage_def.encounters.size()):
		if stage_def.encounters[i] == null or stage_def.encounters[i - 1] == null:
			continue
		var spacing := stage_def.encounters[i].trigger_x - stage_def.encounters[i - 1].trigger_x
		if spacing < min_spacing:
			warnings.append("encounters [%d→%d] spacing %.1f < recommended %.1f (2 chunks)" % [
				i - 1, i, spacing, min_spacing])
	return warnings
