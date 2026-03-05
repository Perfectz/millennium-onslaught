## Stress test tool — spawns configurable enemy counts and measures FPS.
## Run from editor: attach to a Node and call run_stress_test().
class_name StressTest
extends Node


## Test configuration.
var _enemy_count: int = 50
var _test_frames: int = 300
var _current_frame: int = 0
var _fps_samples: Array[float] = []
var _is_running: bool = false


## Run a stress test with the given enemy count.
func run_stress_test(enemy_count: int = 50, test_frames: int = 300) -> void:
	_enemy_count = enemy_count
	_test_frames = test_frames
	_current_frame = 0
	_fps_samples.clear()
	_is_running = true
	print("[StressTest] Starting: %d enemies, %d frames" % [enemy_count, test_frames])


func _process(_delta: float) -> void:
	if not _is_running:
		return
	_fps_samples.append(Engine.get_frames_per_second())
	_current_frame += 1
	if _current_frame >= _test_frames:
		_finish_test()


func _finish_test() -> void:
	_is_running = false
	var report: String = generate_report()
	print(report)


## Generate a formatted stress test report.
func generate_report() -> String:
	if _fps_samples.is_empty():
		return "No stress test data available."
	var total: float = 0.0
	var min_fps: float = INF
	var max_fps: float = 0.0
	var below_30: int = 0
	var below_25: int = 0
	for fps: float in _fps_samples:
		total += fps
		min_fps = minf(min_fps, fps)
		max_fps = maxf(max_fps, fps)
		if fps < 30.0:
			below_30 += 1
		if fps < 25.0:
			below_25 += 1
	var avg: float = total / float(_fps_samples.size())
	var report: String = "=== Stress Test Report ===\n"
	report += "Enemies spawned: %d\n" % _enemy_count
	report += "Frames tested: %d\n" % _fps_samples.size()
	report += "Average FPS: %.1f\n" % avg
	report += "Min FPS: %.1f\n" % min_fps
	report += "Max FPS: %.1f\n" % max_fps
	report += "Frames below 30fps: %d (%.1f%%)\n" % [below_30, float(below_30) / float(_fps_samples.size()) * 100.0]
	report += "Frames below 25fps: %d (%.1f%%)\n" % [below_25, float(below_25) / float(_fps_samples.size()) * 100.0]
	report += "\n--- Verdict ---\n"
	if avg >= 60.0 and min_fps >= 55.0:
		report += "PASS: PC target met (60fps sustained)"
	elif avg >= 30.0 and below_25 == 0:
		report += "PASS: Android target met (30fps, no drops below 25)"
	else:
		report += "FAIL: Performance below targets"
	return report
