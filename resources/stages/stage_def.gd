## Data definition for a continuous scrolling stage ("beads on a string" model).
## Chunks tile along the X axis; encounters trigger dynamically as the player advances.
class_name StageDef
extends Resource


## Unique stage identifier.
@export var stage_id: StringName = &""

## Display name for UI.
@export var stage_name: String = ""

## Ordered list of chunk scene paths that tile left-to-right.
@export var chunk_scenes: Array[String] = []

## Uniform width of each chunk in world units.
@export var chunk_width: float = 24.0

## Encounter placements along the stage, sorted by trigger_x ascending.
@export var encounters: Array[StageEncounterEntry] = []

## Background music track for this stage.
@export var music_track: StringName = &""

## Belt-depth Z bounds (±).
@export var belt_depth: float = 3.0


## Total stage width in world units.
func get_total_width() -> float:
	return chunk_scenes.size() * chunk_width


## Number of encounters in this stage.
func get_encounter_count() -> int:
	return encounters.size()


## Validate stage data. Returns an array of error strings (empty = valid).
func validate() -> Array[String]:
	var errors: Array[String] = []

	if stage_id == &"":
		errors.append("stage_id is empty")
	if chunk_scenes.is_empty():
		errors.append("chunk_scenes is empty — stage has no chunks")
	if chunk_width <= 0.0:
		errors.append("chunk_width must be positive, got %f" % chunk_width)

	var total_width := get_total_width()

	# Validate encounters are sorted by trigger_x.
	var prev_x := -INF
	for i in encounters.size():
		var entry := encounters[i]
		if entry == null:
			errors.append("encounter[%d] is null" % i)
			continue
		if entry.encounter_def == null:
			errors.append("encounter[%d] has null encounter_def" % i)
		if entry.trigger_x < 0.0:
			errors.append("encounter[%d] trigger_x (%.1f) is negative" % [i, entry.trigger_x])
		if entry.trigger_x > total_width and not chunk_scenes.is_empty():
			errors.append("encounter[%d] trigger_x (%.1f) exceeds stage width (%.1f)" % [i, entry.trigger_x, total_width])
		if entry.trigger_x < prev_x:
			errors.append("encounter[%d] trigger_x (%.1f) is not sorted ascending (prev: %.1f)" % [i, entry.trigger_x, prev_x])
		if entry.arena_half_width <= 0.0:
			errors.append("encounter[%d] arena_half_width must be positive" % i)
		prev_x = entry.trigger_x

	# Boss encounter must be last if present.
	for i in encounters.size():
		if encounters[i] != null and encounters[i].is_boss and i != encounters.size() - 1:
			errors.append("encounter[%d] is_boss but not the last encounter" % i)

	# Check arenas don't overlap.
	for i in range(1, encounters.size()):
		if encounters[i] == null or encounters[i - 1] == null:
			continue
		var prev_right := encounters[i - 1].trigger_x + encounters[i - 1].arena_half_width
		var curr_left := encounters[i].trigger_x - encounters[i].arena_half_width
		if prev_right > curr_left:
			errors.append("encounter[%d] arena overlaps with encounter[%d]" % [i, i - 1])

	return errors
