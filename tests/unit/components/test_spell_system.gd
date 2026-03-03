## TDD tests for the right-stick spell system.
## Tests pure logic: TP spending, heal amounts, defense buff, AOE radius, intent buffer.
class_name TestSpellSystem
extends GdUnitTestSuite


var _tp: TPTracker
var _health: HealthComponent
var _status: StatusEffectTracker
var _buffer: InputIntentBuffer


func before_test() -> void:
	_tp = TPTracker.new()
	_health = HealthComponent.new(Constants.PLAYER_MAX_HP)
	_status = StatusEffectTracker.new()
	_buffer = InputIntentBuffer.new()


# --- Fireball (DOT projectile) ---

func test_fireball_tp_cost() -> void:
	_tp.add_tp(Constants.TP_MAX)
	var success := _tp.spend_tp(Constants.SPELL_FIREBALL_TP_COST)
	assert_bool(success).is_true()
	assert_float(_tp.get_current_tp()).is_equal_approx(Constants.TP_MAX - Constants.SPELL_FIREBALL_TP_COST, 0.01)


func test_fireball_damage_is_low_initial() -> void:
	assert_float(Constants.SPELL_FIREBALL_DAMAGE).is_less(15.0)


func test_fireball_burn_chance_is_guaranteed() -> void:
	assert_float(Constants.SPELL_FIREBALL_BURN_CHANCE).is_equal(1.0)


func test_fireball_burn_duration() -> void:
	assert_float(Constants.SPELL_FIREBALL_BURN_DURATION).is_greater(0.0)


func test_fireball_burn_applies_dot() -> void:
	_status.apply_effect(&"burn", Constants.SPELL_FIREBALL_BURN_DURATION)
	var damage := _status.tick(1.0)
	assert_float(damage).is_equal_approx(Constants.BURN_DAMAGE_PER_SECOND, 0.01)


func test_fireball_burn_total_dot_damage() -> void:
	_status.apply_effect(&"burn", Constants.SPELL_FIREBALL_BURN_DURATION)
	var total_damage: float = 0.0
	for i in range(int(Constants.SPELL_FIREBALL_BURN_DURATION * 10)):
		total_damage += _status.tick(0.1)
	var expected := Constants.BURN_DAMAGE_PER_SECOND * Constants.SPELL_FIREBALL_BURN_DURATION
	assert_float(total_damage).is_equal_approx(expected, 0.5)


# --- Heal spell ---

func test_heal_tp_cost() -> void:
	_tp.add_tp(Constants.TP_MAX)
	var success := _tp.spend_tp(Constants.SPELL_HEAL_TP_COST)
	assert_bool(success).is_true()
	assert_float(_tp.get_current_tp()).is_equal_approx(Constants.TP_MAX - Constants.SPELL_HEAL_TP_COST, 0.01)


func test_heal_restores_hp() -> void:
	_health.take_damage(50.0)
	var hp_before := _health.get_current_hp()
	_health.heal(Constants.SPELL_HEAL_AMOUNT)
	assert_float(_health.get_current_hp()).is_equal(hp_before + Constants.SPELL_HEAL_AMOUNT)


func test_heal_clamps_to_max_hp() -> void:
	_health.take_damage(10.0)
	_health.heal(Constants.SPELL_HEAL_AMOUNT)
	assert_float(_health.get_current_hp()).is_equal(Constants.PLAYER_MAX_HP)


func test_heal_amount_is_positive() -> void:
	assert_float(Constants.SPELL_HEAL_AMOUNT).is_greater(0.0)


# --- Radiant Burst (AOE) ---

func test_burst_tp_cost() -> void:
	_tp.add_tp(Constants.TP_MAX)
	var success := _tp.spend_tp(Constants.SPELL_BURST_TP_COST)
	assert_bool(success).is_true()
	assert_float(_tp.get_current_tp()).is_equal_approx(Constants.TP_MAX - Constants.SPELL_BURST_TP_COST, 0.01)


func test_burst_damage_is_positive() -> void:
	assert_float(Constants.SPELL_BURST_DAMAGE).is_greater(0.0)


func test_burst_radius_is_positive() -> void:
	assert_float(Constants.SPELL_BURST_RADIUS).is_greater(0.0)


# --- Barrier (Defense Buff) ---

func test_barrier_tp_cost() -> void:
	_tp.add_tp(Constants.TP_MAX)
	var success := _tp.spend_tp(Constants.SPELL_BARRIER_TP_COST)
	assert_bool(success).is_true()
	assert_float(_tp.get_current_tp()).is_equal_approx(Constants.TP_MAX - Constants.SPELL_BARRIER_TP_COST, 0.01)


func test_barrier_applies_defense_up() -> void:
	_status.apply_effect(&"defense_up", Constants.SPELL_BARRIER_DURATION, Constants.SPELL_BARRIER_DEFENSE_BONUS)
	assert_bool(_status.has_effect(&"defense_up")).is_true()


func test_barrier_defense_bonus_value() -> void:
	_status.apply_effect(&"defense_up", Constants.SPELL_BARRIER_DURATION, Constants.SPELL_BARRIER_DEFENSE_BONUS)
	assert_float(_status.get_defense_bonus()).is_equal(Constants.SPELL_BARRIER_DEFENSE_BONUS)


func test_barrier_expires_after_duration() -> void:
	_status.apply_effect(&"defense_up", Constants.SPELL_BARRIER_DURATION, Constants.SPELL_BARRIER_DEFENSE_BONUS)
	_status.tick(Constants.SPELL_BARRIER_DURATION + 0.1)
	assert_bool(_status.has_effect(&"defense_up")).is_false()
	assert_float(_status.get_defense_bonus()).is_equal(0.0)


func test_defense_bonus_zero_without_buff() -> void:
	assert_float(_status.get_defense_bonus()).is_equal(0.0)


func test_barrier_refreshes_on_recast() -> void:
	_status.apply_effect(&"defense_up", 3.0, Constants.SPELL_BARRIER_DEFENSE_BONUS)
	_status.tick(2.0)
	_status.apply_effect(&"defense_up", Constants.SPELL_BARRIER_DURATION, Constants.SPELL_BARRIER_DEFENSE_BONUS)
	_status.tick(5.0)
	assert_bool(_status.has_effect(&"defense_up")).is_true()


# --- Insufficient TP ---

func test_insufficient_tp_fireball() -> void:
	_tp.set_current_tp(Constants.SPELL_FIREBALL_TP_COST - 1.0)
	var success := _tp.spend_tp(Constants.SPELL_FIREBALL_TP_COST)
	assert_bool(success).is_false()


func test_insufficient_tp_heal() -> void:
	_tp.set_current_tp(Constants.SPELL_HEAL_TP_COST - 1.0)
	var success := _tp.spend_tp(Constants.SPELL_HEAL_TP_COST)
	assert_bool(success).is_false()


func test_insufficient_tp_burst() -> void:
	_tp.set_current_tp(Constants.SPELL_BURST_TP_COST - 1.0)
	var success := _tp.spend_tp(Constants.SPELL_BURST_TP_COST)
	assert_bool(success).is_false()


func test_insufficient_tp_barrier() -> void:
	_tp.set_current_tp(Constants.SPELL_BARRIER_TP_COST - 1.0)
	var success := _tp.spend_tp(Constants.SPELL_BARRIER_TP_COST)
	assert_bool(success).is_false()


# --- Intent Buffer ---

func test_spell_buffer_category_exists() -> void:
	_buffer.record(&"spell")
	assert_bool(_buffer.has_buffered(&"spell")).is_true()


func test_spell_buffer_consume() -> void:
	_buffer.record(&"spell")
	var consumed := _buffer.consume(&"spell")
	assert_bool(consumed).is_true()
	assert_bool(_buffer.has_buffered(&"spell")).is_false()


func test_spell_buffer_cleared_with_clear_all() -> void:
	_buffer.record(&"spell")
	_buffer.clear_all()
	assert_bool(_buffer.has_buffered(&"spell")).is_false()


# --- Spell Constants Validation ---

func test_spell_stick_deadzone_range() -> void:
	assert_float(Constants.SPELL_STICK_DEADZONE).is_greater(0.0)
	assert_float(Constants.SPELL_STICK_DEADZONE).is_less(1.0)


func test_spell_windup_time_positive() -> void:
	assert_float(Constants.SPELL_WINDUP_TIME).is_greater(0.0)


func test_spell_recovery_time_positive() -> void:
	assert_float(Constants.SPELL_RECOVERY_TIME).is_greater(0.0)
