## Pure regression coverage for player hit/parry/block policy helpers.
class_name TestPlayerHitPolicy
extends GdUnitTestSuite


const PlayerHitPolicyScript := preload("res://scripts/components/player_hit_policy.gd")


func test_build_damage_context_converts_defense_stat() -> void:
	var context := PlayerHitPolicyScript.build_damage_context({"defense": 6}, 1.25)

	assert_float(context.get("defense", 0.0) as float).is_equal_approx(1.8, 0.001)
	assert_float(context.get("damage_taken_multiplier", 0.0) as float).is_equal_approx(1.25, 0.001)


func test_resolve_hit_response_returns_parry_without_knockback() -> void:
	var attack := AttackDef.new()
	attack.knockback_force = 9.0

	var response := PlayerHitPolicyScript.resolve_hit_response(
		attack,
		Vector3.ZERO,
		Vector3(2.0, 0.0, 0.0),
		Vector3.RIGHT,
		true,
		true,
		Constants.BLOCK_DAMAGE_REDUCTION,
		0.25,
		Constants.KNOCKBACK_Z_DAMPEN
	)

	assert_str(str(response.get("outcome", ""))).is_equal("parry")
	assert_bool(response.get("blocked", true) as bool).is_false()
	assert_vector(response.get("knockback_velocity", Vector3.ONE) as Vector3).is_equal(Vector3.ZERO)


func test_resolve_hit_response_scales_block_damage_and_knockback() -> void:
	var attack := AttackDef.new()
	attack.damage_multiplier = 1.5
	attack.knockback_force = 8.0

	var response := PlayerHitPolicyScript.resolve_hit_response(
		attack,
		Vector3(-2.0, 0.0, 0.0),
		Vector3.ZERO,
		Vector3.RIGHT,
		false,
		true,
		Constants.BLOCK_DAMAGE_REDUCTION,
		0.25,
		Constants.KNOCKBACK_Z_DAMPEN
	)
	var resolved := response.get("resolved_attack", null) as AttackDef
	var knockback := response.get("knockback_velocity", Vector3.ZERO) as Vector3

	assert_str(str(response.get("outcome", ""))).is_equal("blocked")
	assert_bool(response.get("blocked", false) as bool).is_true()
	assert_float(resolved.damage_multiplier).is_equal_approx(0.15, 0.001)
	assert_float(resolved.knockback_force).is_equal(2.0)
	assert_float(knockback.x).is_equal(2.0)


func test_resolve_hit_response_uses_facing_direction_when_positions_overlap() -> void:
	var attack := AttackDef.new()
	attack.knockback_force = 4.0

	var response := PlayerHitPolicyScript.resolve_hit_response(
		attack,
		Vector3.ZERO,
		Vector3.ZERO,
		Vector3.RIGHT,
		false,
		false,
		Constants.BLOCK_DAMAGE_REDUCTION,
		0.25,
		Constants.KNOCKBACK_Z_DAMPEN
	)
	var knockback := response.get("knockback_velocity", Vector3.ZERO) as Vector3

	assert_str(str(response.get("outcome", ""))).is_equal("hit")
	assert_float(knockback.x).is_equal(-4.0)
	assert_float(knockback.z).is_equal(0.0)
