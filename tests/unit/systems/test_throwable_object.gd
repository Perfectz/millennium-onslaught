## TDD tests for ThrowableObject logic.
class_name TestThrowableObject
extends GdUnitTestSuite


# --- Range Check ---

func test_in_range_when_close() -> void:
	var throwable := ThrowableObject.new()
	throwable.position = Vector3(5, 0, 0)
	var player_pos := Vector3(5.5, 0, 0)
	assert_bool(throwable.is_in_range(player_pos)).is_true()
	throwable.free()


func test_out_of_range_when_far() -> void:
	var throwable := ThrowableObject.new()
	throwable.position = Vector3(5, 0, 0)
	var player_pos := Vector3(20, 0, 0)
	assert_bool(throwable.is_in_range(player_pos)).is_false()
	throwable.free()


# --- Pickup State ---

func test_initial_not_picked_up() -> void:
	var throwable := ThrowableObject.new()
	assert_bool(throwable.is_picked_up()).is_false()
	throwable.free()


# --- Damage Constants ---

func test_throwable_damage_value() -> void:
	assert_float(Constants.THROWABLE_DAMAGE).is_equal(30.0)


func test_throwable_speed_value() -> void:
	assert_float(Constants.THROWABLE_SPEED).is_equal(15.0)


func test_throwable_lifetime_value() -> void:
	assert_float(Constants.THROWABLE_LIFETIME).is_equal(2.0)


func test_throwable_knockback_value() -> void:
	assert_float(Constants.THROWABLE_KNOCKBACK).is_equal(12.0)
