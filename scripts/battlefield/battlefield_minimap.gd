## Top-down minimap of the battlefield: bases, grunts, officers and the player.
class_name BattlefieldMinimap
extends Control


const BG := Color(0.03, 0.05, 0.09, 0.8)
const BORDER := Color(0.38, 0.62, 0.95, 0.7)
const GRUNT_COLOR := Color(0.95, 0.35, 0.45, 0.85)
const OFFICER_COLOR := Color(1.0, 0.6, 0.2)
const PLAYER_COLOR := Color(1.0, 1.0, 1.0)

var _run: Node = null


## Attach the run that provides map data (BattlefieldRun).
func bind(run: Node) -> void:
	_run = run
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	draw_rect(Rect2(Vector2.ZERO, size), BORDER, false, 1.0)
	if _run == null or not _run.has_method("get_minimap_snapshot"):
		return
	var snap: Dictionary = _run.get_minimap_snapshot()
	var arena: Vector2 = snap["arena"]
	var scale := minf(size.x / arena.x, size.y / arena.y)
	var center := size * 0.5
	for b: Dictionary in snap["bases"]:
		var ally: bool = b["side"] == BattlefieldControl.Side.ALLY
		var c := BattlefieldBaseMarker.ALLY_COLOR if ally else BattlefieldBaseMarker.ENEMY_COLOR
		var p := center + (b["pos"] as Vector2) * scale
		draw_circle(p, Constants.BASE_CAPTURE_RADIUS * scale, Color(c, 0.35))
		draw_arc(p, Constants.BASE_CAPTURE_RADIUS * scale, 0.0, TAU, 20, c, 1.5)
	for g: Vector2 in snap["grunts"]:
		draw_rect(Rect2(center + g * scale - Vector2(1, 1), Vector2(2, 2)), GRUNT_COLOR)
	for o: Vector2 in snap["officers"]:
		var p := center + o * scale
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -5), p + Vector2(5, 0), p + Vector2(0, 5), p + Vector2(-5, 0)]), OFFICER_COLOR)
	var pp := center + (snap["player"] as Vector2) * scale
	var dir: Vector2 = snap["player_dir"]
	var side := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([pp + dir * 7.0, pp - dir * 4.0 + side * 4.5, pp - dir * 4.0 - side * 4.5]), PLAYER_COLOR)
