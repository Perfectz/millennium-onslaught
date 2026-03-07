## Regression coverage for transient runtime state ownership.
class_name TestRuntimeState
extends GdUnitTestSuite


func after_test() -> void:
	RuntimeState.reset_dungeon()
	RuntimeState.current_phase = &"main_menu"


func test_reset_dungeon_clears_transient_progress() -> void:
	RuntimeState.current_phase = &"dungeon"
	RuntimeState.current_dungeon_id = &"dungeon_1"
	RuntimeState.current_room_index = 3
	RuntimeState.dungeon_drops = [{"item_id": &"iron_sword"}]
	RuntimeState.encounter_active = true
	RuntimeState.encounter_enemies_alive = 2
	RuntimeState.stage_mode = true
	RuntimeState.current_stage_id = &"academy_b2"
	RuntimeState.stage_encounters_completed = 4
	RuntimeState.stage_total_encounters = 9
	RuntimeState.current_stage_index = 1
	RuntimeState.stage_floor_count = 3
	RuntimeState.set_room_bounds(2.0, 12.0, -4.0, 4.0)
	RuntimeState.arena_lock_min_x = 5.0
	RuntimeState.arena_lock_max_x = 18.0

	RuntimeState.reset_dungeon()

	assert_str(String(RuntimeState.current_phase)).is_equal("dungeon")
	assert_str(String(RuntimeState.current_dungeon_id)).is_empty()
	assert_int(RuntimeState.current_room_index).is_equal(0)
	assert_int(RuntimeState.dungeon_drops.size()).is_equal(0)
	assert_bool(RuntimeState.encounter_active).is_false()
	assert_int(RuntimeState.encounter_enemies_alive).is_equal(0)
	assert_bool(RuntimeState.stage_mode).is_false()
	assert_str(String(RuntimeState.current_stage_id)).is_empty()
	assert_int(RuntimeState.stage_encounters_completed).is_equal(0)
	assert_int(RuntimeState.stage_total_encounters).is_equal(0)
	assert_int(RuntimeState.current_stage_index).is_equal(0)
	assert_int(RuntimeState.stage_floor_count).is_equal(0)
	assert_bool(RuntimeState.room_bounds_active).is_false()
	assert_float(RuntimeState.arena_lock_min_x).is_equal(-100.0)
	assert_float(RuntimeState.arena_lock_max_x).is_equal(100.0)


func test_get_debug_snapshot_reflects_runtime_state() -> void:
	GameState.start_new_game()
	RuntimeState.current_phase = &"dungeon"
	RuntimeState.current_dungeon_id = &"birth_valley"
	RuntimeState.current_stage_id = &"valley_depths"
	RuntimeState.current_stage_index = 2
	RuntimeState.stage_encounters_completed = 5
	RuntimeState.stage_total_encounters = 7
	RuntimeState.stage_floor_count = 3
	RuntimeState.current_room_index = 1
	RuntimeState.encounter_active = true
	RuntimeState.encounter_enemies_alive = 3
	RuntimeState.set_room_bounds(1.0, 9.0, -2.0, 2.0)

	var snapshot := RuntimeState.get_debug_snapshot()
	var active_bounds := RuntimeState.get_active_bounds()
	var room_bounds := snapshot.get("room_bounds", {}) as Dictionary

	assert_str(String(snapshot.get("phase", ""))).is_equal("dungeon")
	assert_str(String(snapshot.get("current_dungeon_id", ""))).is_equal("birth_valley")
	assert_str(String(snapshot.get("current_stage_id", ""))).is_equal("valley_depths")
	assert_int(int(snapshot.get("current_stage_index", -1))).is_equal(2)
	assert_int(int(snapshot.get("stage_encounters_completed", -1))).is_equal(5)
	assert_int(int(snapshot.get("stage_total_encounters", -1))).is_equal(7)
	assert_int(int(snapshot.get("stage_floor_count", -1))).is_equal(3)
	assert_int(int(snapshot.get("encounter_enemies_alive", -1))).is_equal(3)
	assert_bool(bool(snapshot.get("room_bounds_active", false))).is_true()
	assert_float(float(room_bounds.get("min_x", 0.0))).is_equal(1.0)
	assert_float(float(room_bounds.get("max_z", 0.0))).is_equal(2.0)
	assert_str(String(active_bounds.get("source", ""))).is_equal("room")
	assert_float(float(active_bounds.get("max_x", 0.0))).is_equal(9.0)
