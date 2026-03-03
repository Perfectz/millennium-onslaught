## TDD tests for HazardZone logic.
class_name TestHazardZone
extends GdUnitTestSuite


# --- Hazard Constants ---

func test_fire_damage_constant() -> void:
	assert_float(Constants.HAZARD_FIRE_DAMAGE).is_equal(5.0)


func test_fire_tick_interval_constant() -> void:
	assert_float(Constants.HAZARD_FIRE_TICK_INTERVAL).is_equal(0.5)


func test_spike_damage_constant() -> void:
	assert_float(Constants.HAZARD_SPIKE_DAMAGE).is_equal(25.0)


func test_knockback_force_constant() -> void:
	assert_float(Constants.HAZARD_KNOCKBACK_FORCE).is_equal(10.0)


# --- Hazard Type Configuration ---

func test_default_hazard_type_is_dot() -> void:
	var hazard := HazardZone.new()
	assert_int(hazard.hazard_type).is_equal(HazardZone.HazardType.DAMAGE_OVER_TIME)
	hazard.free()


func test_hazard_damage_default() -> void:
	var hazard := HazardZone.new()
	assert_float(hazard.damage).is_equal(Constants.HAZARD_FIRE_DAMAGE)
	hazard.free()


func test_hazard_tick_interval_default() -> void:
	var hazard := HazardZone.new()
	assert_float(hazard.tick_interval).is_equal(Constants.HAZARD_FIRE_TICK_INTERVAL)
	hazard.free()


func test_instant_hazard_type() -> void:
	var hazard := HazardZone.new()
	hazard.hazard_type = HazardZone.HazardType.INSTANT
	assert_int(hazard.hazard_type).is_equal(HazardZone.HazardType.INSTANT)
	hazard.free()


func test_knockback_hazard_type() -> void:
	var hazard := HazardZone.new()
	hazard.hazard_type = HazardZone.HazardType.KNOCKBACK
	assert_int(hazard.hazard_type).is_equal(HazardZone.HazardType.KNOCKBACK)
	hazard.free()
