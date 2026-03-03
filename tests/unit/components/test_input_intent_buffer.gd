class_name TestInputIntentBuffer
extends GdUnitTestSuite


## Fake clock for deterministic testing. Time in microseconds.
var _fake_time_usec: int = 1_000_000  # Start at 1 second to avoid 0 edge cases
var _buffer: InputIntentBuffer


func _get_fake_time() -> int:
	return _fake_time_usec


func _advance_time_sec(seconds: float) -> void:
	_fake_time_usec += int(seconds * 1_000_000.0)


func before_test() -> void:
	_fake_time_usec = 1_000_000
	_buffer = InputIntentBuffer.new(Callable(self, "_get_fake_time"))


# --- Record / Consume basics ---

func test_consume_returns_false_when_no_intent() -> void:
	assert_bool(_buffer.consume(&"attack_light")).is_false()


func test_record_then_consume_returns_true() -> void:
	_buffer.record(&"attack_light")
	assert_bool(_buffer.consume(&"attack_light")).is_true()


func test_consume_clears_the_intent() -> void:
	_buffer.record(&"attack_light")
	_buffer.consume(&"attack_light")
	assert_bool(_buffer.consume(&"attack_light")).is_false()


func test_consume_within_window_succeeds() -> void:
	_buffer.record(&"attack_light")
	_advance_time_sec(Constants.ACTION_BUFFER_WINDOW * 0.5)
	assert_bool(_buffer.consume(&"attack_light")).is_true()


func test_consume_at_window_boundary_succeeds() -> void:
	_buffer.record(&"attack_light")
	_advance_time_sec(Constants.ACTION_BUFFER_WINDOW)
	assert_bool(_buffer.consume(&"attack_light")).is_true()


func test_consume_after_window_expires_returns_false() -> void:
	_buffer.record(&"attack_light")
	_advance_time_sec(Constants.ACTION_BUFFER_WINDOW + 0.001)
	assert_bool(_buffer.consume(&"attack_light")).is_false()


# --- has_buffered ---

func test_has_buffered_false_when_empty() -> void:
	assert_bool(_buffer.has_buffered(&"dodge")).is_false()


func test_has_buffered_true_after_record() -> void:
	_buffer.record(&"dodge")
	assert_bool(_buffer.has_buffered(&"dodge")).is_true()


func test_has_buffered_false_after_expiry() -> void:
	_buffer.record(&"dodge")
	_advance_time_sec(Constants.DODGE_BUFFER_WINDOW + 0.001)
	assert_bool(_buffer.has_buffered(&"dodge")).is_false()


func test_has_buffered_does_not_consume() -> void:
	_buffer.record(&"attack_heavy")
	assert_bool(_buffer.has_buffered(&"attack_heavy")).is_true()
	# Still there after checking.
	assert_bool(_buffer.consume(&"attack_heavy")).is_true()


# --- Category isolation ---

func test_categories_are_independent() -> void:
	_buffer.record(&"attack_light")
	assert_bool(_buffer.consume(&"attack_heavy")).is_false()
	assert_bool(_buffer.consume(&"dodge")).is_false()
	assert_bool(_buffer.consume(&"attack_light")).is_true()


func test_multiple_categories_at_once() -> void:
	_buffer.record(&"attack_light")
	_buffer.record(&"dodge")
	assert_bool(_buffer.consume(&"attack_light")).is_true()
	assert_bool(_buffer.consume(&"dodge")).is_true()
	assert_bool(_buffer.consume(&"attack_light")).is_false()


# --- Last-intent-wins ---

func test_last_intent_wins_refreshes_timestamp() -> void:
	_buffer.record(&"attack_light")
	_advance_time_sec(Constants.ACTION_BUFFER_WINDOW * 0.8)
	# Re-record — should refresh the window.
	_buffer.record(&"attack_light")
	_advance_time_sec(Constants.ACTION_BUFFER_WINDOW * 0.8)
	# Total time from first record exceeds window, but second record keeps it alive.
	assert_bool(_buffer.consume(&"attack_light")).is_true()


# --- clear_all ---

func test_clear_all_removes_all_intents() -> void:
	_buffer.record(&"attack_light")
	_buffer.record(&"attack_heavy")
	_buffer.record(&"dodge")
	_buffer.record(&"technique")
	_buffer.clear_all()
	assert_bool(_buffer.consume(&"attack_light")).is_false()
	assert_bool(_buffer.consume(&"attack_heavy")).is_false()
	assert_bool(_buffer.consume(&"dodge")).is_false()
	assert_bool(_buffer.consume(&"technique")).is_false()


# --- clear single ---

func test_clear_single_category() -> void:
	_buffer.record(&"attack_light")
	_buffer.record(&"dodge")
	_buffer.clear(&"attack_light")
	assert_bool(_buffer.consume(&"attack_light")).is_false()
	assert_bool(_buffer.consume(&"dodge")).is_true()


# --- Category-specific windows ---

func test_dodge_uses_dodge_window() -> void:
	_buffer.record(&"dodge")
	_advance_time_sec(Constants.DODGE_BUFFER_WINDOW)
	assert_bool(_buffer.consume(&"dodge")).is_true()


func test_dodge_expires_after_dodge_window() -> void:
	_buffer.record(&"dodge")
	_advance_time_sec(Constants.DODGE_BUFFER_WINDOW + 0.001)
	assert_bool(_buffer.consume(&"dodge")).is_false()


func test_technique_uses_technique_window() -> void:
	_buffer.record(&"technique")
	_advance_time_sec(Constants.TECHNIQUE_BUFFER_WINDOW)
	assert_bool(_buffer.consume(&"technique")).is_true()


func test_technique_expires_after_technique_window() -> void:
	_buffer.record(&"technique")
	_advance_time_sec(Constants.TECHNIQUE_BUFFER_WINDOW + 0.001)
	assert_bool(_buffer.consume(&"technique")).is_false()


# --- All five categories ---

func test_all_five_categories_work() -> void:
	var categories := [&"attack_light", &"attack_heavy", &"dodge", &"technique"]
	for cat: StringName in categories:
		_buffer.record(cat)
	for cat: StringName in categories:
		assert_bool(_buffer.consume(cat)).is_true()


# --- Edge: expired intent is cleaned on consume ---

func test_expired_intent_cleared_on_consume_attempt() -> void:
	_buffer.record(&"attack_light")
	_advance_time_sec(1.0)  # Well past any window.
	_buffer.consume(&"attack_light")  # Should fail and clear.
	# Internal state should be 0 now — verify by recording fresh.
	_buffer.record(&"attack_light")
	assert_bool(_buffer.consume(&"attack_light")).is_true()
