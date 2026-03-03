## TDD tests for GoldTracker — add/spend/track gold currency.
class_name TestGoldTracker
extends GdUnitTestSuite


var _gold: GoldTracker


func before_test() -> void:
	_gold = GoldTracker.new()


# --- Initial State ---

func test_initial_gold_is_zero() -> void:
	assert_int(_gold.get_gold()).is_equal(0)


# --- Add ---

func test_add_gold_increases_total() -> void:
	_gold.add_gold(50)
	assert_int(_gold.get_gold()).is_equal(50)


func test_add_gold_accumulates() -> void:
	_gold.add_gold(30)
	_gold.add_gold(20)
	assert_int(_gold.get_gold()).is_equal(50)


func test_add_negative_ignored() -> void:
	_gold.add_gold(-10)
	assert_int(_gold.get_gold()).is_equal(0)


func test_add_zero_ignored() -> void:
	_gold.add_gold(0)
	assert_int(_gold.get_gold()).is_equal(0)


# --- Spend ---

func test_spend_gold_reduces_total() -> void:
	_gold.add_gold(100)
	var success: bool = _gold.spend_gold(30)
	assert_bool(success).is_true()
	assert_int(_gold.get_gold()).is_equal(70)


func test_spend_gold_fails_if_insufficient() -> void:
	_gold.add_gold(10)
	var success: bool = _gold.spend_gold(50)
	assert_bool(success).is_false()
	assert_int(_gold.get_gold()).is_equal(10)


func test_spend_exact_amount_succeeds() -> void:
	_gold.add_gold(40)
	var success: bool = _gold.spend_gold(40)
	assert_bool(success).is_true()
	assert_int(_gold.get_gold()).is_equal(0)


# --- Can Afford ---

func test_can_afford_true_when_sufficient() -> void:
	_gold.add_gold(100)
	assert_bool(_gold.can_afford(50)).is_true()


func test_can_afford_false_when_insufficient() -> void:
	assert_bool(_gold.can_afford(200)).is_false()


# --- Set ---

func test_set_gold_overwrites() -> void:
	_gold.set_gold(999)
	assert_int(_gold.get_gold()).is_equal(999)


# --- Signal ---

func test_add_gold_emits_signal() -> void:
	var monitor := monitor_signals(_gold)
	_gold.add_gold(25)
	await assert_signal(monitor).is_emitted("gold_changed", [25])


func test_spend_gold_emits_signal() -> void:
	_gold.add_gold(100)
	var monitor := monitor_signals(_gold)
	_gold.spend_gold(30)
	await assert_signal(monitor).is_emitted("gold_changed", [70])
