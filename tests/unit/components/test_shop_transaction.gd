## TDD tests for ShopTransaction — buy/sell validation and execution.
class_name TestShopTransaction
extends GdUnitTestSuite


var _shop: ShopTransaction


func before_test() -> void:
	_shop = ShopTransaction.new()


# --- Can Buy ---

func test_can_buy_with_enough_gold() -> void:
	assert_bool(_shop.can_buy(200, 100)).is_true()


func test_can_buy_with_exact_gold() -> void:
	assert_bool(_shop.can_buy(100, 100)).is_true()


func test_cannot_buy_without_enough_gold() -> void:
	assert_bool(_shop.can_buy(50, 100)).is_false()


func test_cannot_buy_zero_cost() -> void:
	assert_bool(_shop.can_buy(100, 0)).is_false()


# --- Buy ---

func test_buy_reduces_gold() -> void:
	var result: Dictionary = _shop.buy(200, 100, &"iron_sword")
	assert_bool(result.success as bool).is_true()
	assert_int(result.new_gold as int).is_equal(100)


func test_buy_fails_without_gold() -> void:
	var result: Dictionary = _shop.buy(30, 100, &"iron_sword")
	assert_bool(result.success as bool).is_false()
	assert_int(result.new_gold as int).is_equal(30)


func test_buy_emits_purchase_completed() -> void:
	var monitor := monitor_signals(_shop)
	_shop.buy(200, 100, &"iron_sword")
	await assert_signal(monitor).is_emitted("purchase_completed", [&"iron_sword", 100])


func test_buy_emits_transaction_failed_on_insufficient() -> void:
	var monitor := monitor_signals(_shop)
	_shop.buy(30, 100, &"iron_sword")
	await assert_signal(monitor).is_emitted("transaction_failed", ["Insufficient gold"])


# --- Sell Price ---

func test_sell_price_calculation() -> void:
	assert_int(_shop.sell_price(100, 0.5)).is_equal(50)


func test_sell_price_rounds_down() -> void:
	assert_int(_shop.sell_price(99, 0.5)).is_equal(49)


# --- Sell ---

func test_sell_increases_gold() -> void:
	var result: Dictionary = _shop.sell(100, 80, 0.5, &"leather_armor")
	assert_bool(result.success as bool).is_true()
	assert_int(result.new_gold as int).is_equal(140)
	assert_int(result.earned as int).is_equal(40)


func test_sell_emits_sale_completed() -> void:
	var monitor := monitor_signals(_shop)
	_shop.sell(100, 80, 0.5, &"leather_armor")
	await assert_signal(monitor).is_emitted("sale_completed", [&"leather_armor", 40])
