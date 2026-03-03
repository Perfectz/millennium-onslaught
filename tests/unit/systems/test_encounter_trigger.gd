## TDD tests for EncounterTrigger state machine logic.
class_name TestEncounterTrigger
extends GdUnitTestSuite


var _trigger: EncounterTrigger


func before_test() -> void:
	_trigger = EncounterTrigger.new()
	_trigger.trigger_index = 2


func after_test() -> void:
	if is_instance_valid(_trigger) and _trigger.is_inside_tree():
		_trigger.queue_free()
	_trigger = null


# --- Initial State ---

func test_initial_not_activated() -> void:
	assert_bool(_trigger.is_activated()).is_false()


func test_trigger_index_set() -> void:
	assert_int(_trigger.trigger_index).is_equal(2)


# --- Reset ---

func test_reset_clears_activated() -> void:
	_trigger._activated = true
	assert_bool(_trigger.is_activated()).is_true()
	_trigger.reset()
	assert_bool(_trigger.is_activated()).is_false()


# --- Signal Emission (unit test via direct call) ---

var _emitted_index: int = -1


func _on_triggered(index: int) -> void:
	_emitted_index = index


func test_trigger_emits_signal_once() -> void:
	_trigger.triggered.connect(_on_triggered)
	_emitted_index = -1
	# Simulate activation.
	_trigger._activated = false
	var mock := _make_mock_player()
	_trigger._on_body_entered(mock)
	mock.free()
	assert_int(_emitted_index).is_equal(2)


func test_trigger_does_not_repeat() -> void:
	_trigger.triggered.connect(_on_triggered)
	_emitted_index = -1
	# First activation.
	var mock := _make_mock_player()
	_trigger._on_body_entered(mock)
	assert_int(_emitted_index).is_equal(2)
	# Reset counter and try again.
	_emitted_index = -1
	_trigger._on_body_entered(mock)
	mock.free()
	# Should NOT have emitted again.
	assert_int(_emitted_index).is_equal(-1)


## Create a mock CharacterBody3D with player collision layer.
func _make_mock_player() -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.collision_layer = Constants.LAYER_PLAYER
	return body
