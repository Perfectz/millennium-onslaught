## Regression coverage for EventBus checked emission and debug diagnostics.
class_name TestEventBusDiagnostics
extends GdUnitTestSuite


var _probe_node: Node = null
var _captured_save_slot: int = -1


func before_test() -> void:
	EventBus.clear_debug_buffers()
	_captured_save_slot = -1
	_probe_node = Node.new()
	add_child(_probe_node)


func after_test() -> void:
	if EventBus.save_completed.is_connected(_capture_save_completed):
		EventBus.save_completed.disconnect(_capture_save_completed)
	EventBus.clear_debug_buffers()
	if is_instance_valid(_probe_node):
		if _probe_node.get_parent() != null:
			_probe_node.get_parent().remove_child(_probe_node)
		_probe_node.free()
	_probe_node = null


func test_emit_checked_logs_known_signal_and_payload() -> void:
	EventBus.save_completed.connect(_capture_save_completed, CONNECT_ONE_SHOT)

	var emitted := EventBus.emit_checked(&"save_completed", [2], {"slot": 2}, true)

	assert_bool(emitted).is_true()
	assert_int(_captured_save_slot).is_equal(2)

	var recent_events := EventBus.get_recent_events(1)
	assert_int(recent_events.size()).is_equal(1)
	var entry: Dictionary = recent_events[0]
	assert_str(String(entry.get("event", ""))).is_equal("save_completed")
	assert_bool(int(entry.get("listeners", 0)) > 0).is_true()
	assert_bool(bool(entry.get("unmatched", true))).is_false()

	var payload := entry.get("payload", {}) as Dictionary
	assert_int(int(payload.get("slot", -1))).is_equal(2)


func test_emit_checked_records_unmatched_signals_in_debug_buffers() -> void:
	assert_int(EventBus.get_signal_connection_list(&"combat_spell_heal").size()).is_equal(0)

	var emitted := EventBus.emit_checked(&"combat_spell_heal", [_probe_node, 12.0], {
		"player": "probe",
		"amount": 12.0,
	})

	assert_bool(emitted).is_true()

	var unmatched_events := EventBus.get_unmatched_events(1)
	assert_int(unmatched_events.size()).is_equal(1)
	var unmatched_entry: Dictionary = unmatched_events[0]
	assert_str(String(unmatched_entry.get("event", ""))).is_equal("combat_spell_heal")
	assert_bool(bool(unmatched_entry.get("unmatched", false))).is_true()

	var recent_events := EventBus.get_recent_events(1)
	assert_int(recent_events.size()).is_equal(1)
	var recent_entry: Dictionary = recent_events[0]
	assert_str(String(recent_entry.get("event", ""))).is_equal("combat_spell_heal")
	assert_bool(bool(recent_entry.get("unmatched", false))).is_true()


func test_try_emit_checked_logs_unknown_signal_without_asserting() -> void:
	var emitted := EventBus.try_emit_checked(&"missing_signal", [], {"source": "unit_test"})

	assert_bool(emitted).is_false()

	var recent_events := EventBus.get_recent_events(1)
	assert_int(recent_events.size()).is_equal(1)
	var entry: Dictionary = recent_events[0]
	assert_str(String(entry.get("event", ""))).is_equal("event_bus_unknown_signal")

	var payload := entry.get("payload", {}) as Dictionary
	assert_str(String(payload.get("signal", ""))).is_equal("missing_signal")


func _capture_save_completed(slot: int) -> void:
	_captured_save_slot = slot
