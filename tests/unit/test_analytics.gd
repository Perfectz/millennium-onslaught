## Tests for AnalyticsService — event recording, stats tracking, serialization.
extends GdUnitTestSuite


var _analytics: AnalyticsService


func before_test() -> void:
	_analytics = AnalyticsService.new()
	add_child(_analytics)
	_analytics.start_session()


func after_test() -> void:
	_analytics.end_session()
	_analytics.queue_free()


func test_session_starts_with_zero_stats() -> void:
	var stats: Dictionary = _analytics.get_stats()
	assert_int(stats["total_kills"]).is_equal(0)
	assert_int(stats["total_deaths"]).is_equal(0)
	assert_float(stats["total_damage_dealt"]).is_equal(0.0)


func test_record_event_adds_to_events() -> void:
	_analytics.record_event("test_event", {"value": 42})
	var events: Array[Dictionary] = _analytics.get_events()
	# Should have at least 2: session_started + test_event.
	assert_int(events.size()).is_greater_equal(2)


func test_events_have_timestamp() -> void:
	_analytics.record_event("test", {})
	var events: Array[Dictionary] = _analytics.get_events()
	var last: Dictionary = events[events.size() - 1]
	assert_bool("time" in last).is_true()
	assert_bool("event" in last).is_true()


func test_serialize_session_contains_stats() -> void:
	var serialized: Dictionary = _analytics.serialize_session()
	assert_bool("stats" in serialized).is_true()
	assert_bool("events" in serialized).is_true()
	assert_bool("session_start" in serialized).is_true()


func test_get_summary_returns_string() -> void:
	var summary: String = _analytics.get_summary()
	assert_str(summary).contains("Session Summary")
	assert_str(summary).contains("Kills")
	assert_str(summary).contains("Deaths")
