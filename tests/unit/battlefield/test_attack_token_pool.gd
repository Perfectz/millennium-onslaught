class_name TestAttackTokenPool
extends GdUnitTestSuite


func test_grants_up_to_capacity() -> void:
	var pool := AttackTokenPool.new(2)
	assert_bool(pool.request(1)).is_true()
	assert_bool(pool.request(2)).is_true()
	assert_bool(pool.request(3)).is_false()
	assert_int(pool.get_holder_count()).is_equal(2)


func test_request_is_idempotent_for_holder() -> void:
	var pool := AttackTokenPool.new(1)
	assert_bool(pool.request(7)).is_true()
	assert_bool(pool.request(7)).is_true()
	assert_int(pool.get_holder_count()).is_equal(1)


func test_release_frees_slot() -> void:
	var pool := AttackTokenPool.new(1)
	pool.request(1)
	pool.release(1)
	assert_bool(pool.has_token(1)).is_false()
	assert_bool(pool.request(2)).is_true()


func test_release_unknown_is_noop() -> void:
	var pool := AttackTokenPool.new(1)
	pool.release(99)
	assert_int(pool.get_holder_count()).is_equal(0)


func test_capacity_change_keeps_existing_holders() -> void:
	var pool := AttackTokenPool.new(3)
	pool.request(1)
	pool.request(2)
	pool.set_capacity(1)
	assert_bool(pool.has_token(1)).is_true()
	assert_bool(pool.has_token(2)).is_true()
	assert_bool(pool.request(3)).is_false()


func test_clear() -> void:
	var pool := AttackTokenPool.new(2)
	pool.request(1)
	pool.clear()
	assert_int(pool.get_holder_count()).is_equal(0)
