# GdUnit4 Test Suite for ObjectPoolSingleton lifecycle rules.
extends GdUnitTestSuite

const POOL_KEY: StringName = &"test_pool"

var _pool: ObjectPoolSingleton
var _scene: PackedScene


func before_test() -> void:
	_pool = auto_free(ObjectPoolSingleton.new())
	add_child(_pool)
	var template := Node3D.new()
	_scene = PackedScene.new()
	_scene.pack(template)
	template.free()


func test_get_instance_returns_active_instance() -> void:
	_pool.warm_pool(_scene, 2, POOL_KEY)
	var inst := _pool.get_instance(POOL_KEY)
	assert_object(inst).is_not_null()
	assert_bool(inst.get_meta(&"pool_active", false)).is_true()
	assert_int(_pool.get_active_count(POOL_KEY)).is_equal(1)


func test_returned_instance_is_reparented_back_to_pool() -> void:
	_pool.warm_pool(_scene, 1, POOL_KEY)
	var level := auto_free(Node3D.new()) as Node3D
	add_child(level)
	var inst := _pool.get_instance(POOL_KEY)
	inst.reparent(level)
	_pool.return_instance(inst)
	assert_object(inst.get_parent()).is_same(_pool)


func test_returned_instance_survives_level_teardown() -> void:
	_pool.warm_pool(_scene, 1, POOL_KEY)
	var level := Node3D.new()
	add_child(level)
	var inst := _pool.get_instance(POOL_KEY)
	inst.reparent(level)
	_pool.return_instance(inst)
	level.free()
	assert_bool(is_instance_valid(inst)).is_true()
	assert_object(_pool.get_instance(POOL_KEY)).is_same(inst)


func test_get_instance_skips_freed_instances() -> void:
	_pool.warm_pool(_scene, 2, POOL_KEY)
	var first := _pool.get_instance(POOL_KEY)
	var second := _pool.get_instance(POOL_KEY)
	_pool.return_instance(second)
	_pool.return_instance(first)
	# Simulate an instance destroyed outside the pool (e.g. freed along with its level).
	first.free()
	var got := _pool.get_instance(POOL_KEY)
	assert_object(got).is_same(second)
	assert_object(_pool.get_instance(POOL_KEY)).is_null()


func test_parentless_instance_is_adopted_on_return() -> void:
	_pool.warm_pool(_scene, 1, POOL_KEY)
	var inst := _pool.get_instance(POOL_KEY)
	_pool.remove_child(inst)
	_pool.return_instance(inst)
	assert_object(inst.get_parent()).is_same(_pool)
