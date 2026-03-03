## TDD tests for StageDef validation and helper methods.
class_name TestStageDef
extends GdUnitTestSuite


## Helper — create a minimal valid StageDef (6 chunks = 144 units).
func _make_valid_stage() -> StageDef:
	var stage := StageDef.new()
	stage.stage_id = &"test_stage"
	stage.stage_name = "Test Stage"
	stage.chunk_scenes = [
		"res://scenes/dungeon/chunks/chunk_start.tscn",
		"res://scenes/dungeon/chunks/chunk_street_a.tscn",
		"res://scenes/dungeon/chunks/chunk_plaza_a.tscn",
		"res://scenes/dungeon/chunks/chunk_street_b.tscn",
		"res://scenes/dungeon/chunks/chunk_plaza_b.tscn",
		"res://scenes/dungeon/chunks/chunk_boss.tscn",
	]
	stage.chunk_width = 24.0

	var enc_entry := StageEncounterEntry.new()
	enc_entry.encounter_def = EncounterDef.new()
	enc_entry.trigger_x = 60.0
	enc_entry.arena_half_width = 10.0
	stage.encounters = [enc_entry]

	return stage


# --- Total Width Calculation ---

func test_total_width_single_chunk() -> void:
	var stage := StageDef.new()
	stage.chunk_scenes = ["res://chunk.tscn"]
	stage.chunk_width = 24.0
	assert_float(stage.get_total_width()).is_equal(24.0)


func test_total_width_six_chunks() -> void:
	var stage := StageDef.new()
	stage.chunk_scenes = ["a", "b", "c", "d", "e", "f"]
	stage.chunk_width = 24.0
	assert_float(stage.get_total_width()).is_equal(144.0)


func test_total_width_empty() -> void:
	var stage := StageDef.new()
	stage.chunk_scenes = []
	stage.chunk_width = 24.0
	assert_float(stage.get_total_width()).is_equal(0.0)


# --- Encounter Count ---

func test_encounter_count_zero() -> void:
	var stage := StageDef.new()
	assert_int(stage.get_encounter_count()).is_equal(0)


func test_encounter_count_three() -> void:
	var stage := StageDef.new()
	stage.encounters = [
		StageEncounterEntry.new(),
		StageEncounterEntry.new(),
		StageEncounterEntry.new(),
	]
	assert_int(stage.get_encounter_count()).is_equal(3)


# --- Validation: Empty/Invalid Stages ---

func test_empty_stage_invalid() -> void:
	var stage := StageDef.new()
	var errors := stage.validate()
	assert_array(errors).is_not_empty()
	# Should report empty stage_id and empty chunk_scenes.
	var joined := " ".join(errors)
	assert_bool("stage_id" in joined).is_true()
	assert_bool("chunk_scenes" in joined).is_true()


func test_negative_chunk_width_invalid() -> void:
	var stage := StageDef.new()
	stage.stage_id = &"test"
	stage.chunk_scenes = ["res://chunk.tscn"]
	stage.chunk_width = -5.0
	var errors := stage.validate()
	var joined := " ".join(errors)
	assert_bool("chunk_width" in joined).is_true()


# --- Validation: Valid Stage ---

func test_valid_stage_passes() -> void:
	var stage := _make_valid_stage()
	var errors := stage.validate()
	assert_array(errors).is_empty()


# --- Validation: Encounter Sorting ---

func test_encounters_sorted_ascending_valid() -> void:
	var stage := _make_valid_stage()
	# First encounter at 60 with half_width 10 → arena 50-70.
	# Second at 80 with half_width 2 → arena 78-82. No overlap.
	var enc2 := StageEncounterEntry.new()
	enc2.encounter_def = EncounterDef.new()
	enc2.trigger_x = 80.0
	enc2.arena_half_width = 2.0
	stage.encounters.append(enc2)
	var errors := stage.validate()
	assert_array(errors).is_empty()


func test_encounters_not_sorted_invalid() -> void:
	var stage := _make_valid_stage()
	# Add encounter with lower trigger_x than the first.
	var enc2 := StageEncounterEntry.new()
	enc2.encounter_def = EncounterDef.new()
	enc2.trigger_x = 10.0
	enc2.arena_half_width = 2.0
	stage.encounters.append(enc2)
	var errors := stage.validate()
	var joined := " ".join(errors)
	assert_bool("not sorted" in joined).is_true()


# --- Validation: Encounter Bounds ---

func test_encounter_within_stage_bounds() -> void:
	var stage := _make_valid_stage()
	# trigger_x=60 is within 3*24=72 total width.
	var errors := stage.validate()
	assert_array(errors).is_empty()


func test_encounter_beyond_stage_bounds_invalid() -> void:
	var stage := StageDef.new()
	stage.stage_id = &"test"
	stage.chunk_scenes = ["res://chunk.tscn"]  # 1 chunk = 24 units
	stage.chunk_width = 24.0
	var enc := StageEncounterEntry.new()
	enc.encounter_def = EncounterDef.new()
	enc.trigger_x = 50.0  # Beyond 24 total width
	enc.arena_half_width = 5.0
	stage.encounters = [enc]
	var errors := stage.validate()
	var joined := " ".join(errors)
	assert_bool("exceeds stage width" in joined).is_true()


# --- Validation: Boss Must Be Last ---

func test_boss_encounter_is_last_valid() -> void:
	var stage := _make_valid_stage()
	stage.encounters[0].is_boss = true  # Only encounter, so it's last.
	var errors := stage.validate()
	assert_array(errors).is_empty()


func test_boss_encounter_not_last_invalid() -> void:
	var stage := _make_valid_stage()
	stage.encounters[0].is_boss = true
	# Add a non-boss encounter after it.
	var enc2 := StageEncounterEntry.new()
	enc2.encounter_def = EncounterDef.new()
	enc2.trigger_x = 70.0
	enc2.arena_half_width = 2.0
	enc2.is_boss = false
	stage.encounters.append(enc2)
	var errors := stage.validate()
	var joined := " ".join(errors)
	assert_bool("is_boss" in joined).is_true()


# --- Validation: Arena Overlap ---

func test_non_overlapping_arenas_valid() -> void:
	var stage := _make_valid_stage()
	stage.encounters[0].trigger_x = 30.0
	stage.encounters[0].arena_half_width = 8.0  # 22-38
	var enc2 := StageEncounterEntry.new()
	enc2.encounter_def = EncounterDef.new()
	enc2.trigger_x = 60.0
	enc2.arena_half_width = 8.0  # 52-68, no overlap
	stage.encounters.append(enc2)
	var errors := stage.validate()
	assert_array(errors).is_empty()


func test_overlapping_arenas_invalid() -> void:
	var stage := _make_valid_stage()
	stage.encounters[0].trigger_x = 30.0
	stage.encounters[0].arena_half_width = 20.0  # 10-50
	var enc2 := StageEncounterEntry.new()
	enc2.encounter_def = EncounterDef.new()
	enc2.trigger_x = 45.0
	enc2.arena_half_width = 10.0  # 35-55, overlaps with 10-50
	stage.encounters.append(enc2)
	var errors := stage.validate()
	var joined := " ".join(errors)
	assert_bool("overlap" in joined).is_true()


# --- Validation: Null Encounter Def ---

func test_null_encounter_def_invalid() -> void:
	var stage := StageDef.new()
	stage.stage_id = &"test"
	stage.chunk_scenes = ["res://chunk.tscn", "res://chunk2.tscn", "res://chunk3.tscn"]
	stage.chunk_width = 24.0
	var enc := StageEncounterEntry.new()
	enc.encounter_def = null
	enc.trigger_x = 20.0
	stage.encounters = [enc]
	var errors := stage.validate()
	var joined := " ".join(errors)
	assert_bool("null encounter_def" in joined).is_true()
