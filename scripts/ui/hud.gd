## Main HUD controller. Subscribes to EventBus signals and updates UI elements.
class_name HUD
extends CanvasLayer


const UIStyleRef = preload("res://scripts/ui/ui_style.gd")
const BAR_EDGE_PADDING: float = 2.0
const NOW_PLAYING_DISPLAY_TIME: float = 3.0
const NOW_PLAYING_TOP: float = 72.0
const NOW_PLAYING_BOTTOM: float = 116.0
const NOW_PLAYING_SHOW_OFFSET: float = 6.0
const NOW_PLAYING_HIDE_OFFSET: float = 4.0
const STAGE_MAP_PANEL_WIDTH: float = 248.0
const STAGE_MAP_PANEL_HEIGHT: float = 116.0

@onready var hp_bar_bg: ColorRect = $Panel/StatsCard/Margin/VBox/HPBlock/HPBar/HPBarBG
@onready var hp_bar_fill: ColorRect = $Panel/StatsCard/Margin/VBox/HPBlock/HPBar/HPBarBG/HPBarFill
@onready var hp_label: Label = $Panel/StatsCard/Margin/VBox/HPBlock/HPHeader/HPLabel
@onready var tp_bar_bg: ColorRect = $Panel/StatsCard/Margin/VBox/TPBlock/TPBar/TPBarBG
@onready var tp_bar_fill: ColorRect = $Panel/StatsCard/Margin/VBox/TPBlock/TPBar/TPBarBG/TPBarFill
@onready var tp_label: Label = $Panel/StatsCard/Margin/VBox/TPBlock/TPHeader/TPLabel
@onready var objective_label: Label = $Panel/TopFrame/Margin/HBox/ObjectivePanel/HBox/ObjectiveLabel
@onready var now_playing_strip: PanelContainer = $Panel/NowPlayingStrip
@onready var now_playing_label: Label = $Panel/NowPlayingStrip/Margin/HBox/NowPlayingLabel
@onready var combo_badge: PanelContainer = $Panel/ComboBadge
@onready var combo_label: Label = $Panel/ComboBadge/Margin/VBox/ComboCounter
@onready var gold_label: Label = $Panel/StatsCard/Margin/VBox/GoldBlock/GoldLabel
@onready var state_badge: PanelContainer = $Panel/StateBadge
@onready var state_label: Label = $Panel/StateBadge/StateLabel
@onready var pilot_label: Label = $Panel/TopFrame/Margin/HBox/PlayerBlock/PilotLabel
@onready var role_label: Label = $Panel/TopFrame/Margin/HBox/PlayerBlock/RoleLabel
@onready var action_hints: PanelContainer = $Panel/ActionHints
@onready var sub_hint_label: Label = $Panel/StatsCard/Margin/VBox/SubHintLabel

var _hp_display: float = 1.0
var _hp_target: float = 1.0
var _hp_fill_width: float = 0.0
var _tp_ratio: float = 0.0
var _tp_fill_width: float = 0.0
var _combo_count: int = 0
var _combo_timer: float = 0.0
var _now_playing_timer: float = 0.0
var _now_playing_tween: Tween = null

var _hp_low_pulse_active: bool = false
var _hp_low_tween: Tween = null
var _tp_full_glow_active: bool = false
var _compact_layout: bool = false
var _combat_active: bool = false
var _action_hints_target_alpha: float = 0.0

## RPG HUD elements (created in code).
var _level_label: Label = null
var _xp_bar_bg: ColorRect = null
var _xp_bar_fill: ColorRect = null
var _technique_label: Label = null
var _stage_map_panel: PanelContainer = null
var _stage_map_floor_row: HBoxContainer = null
var _stage_map_progress_label: Label = null
var _stage_map_status_label: Label = null
var _stage_map_floor_cards: Array[PanelContainer] = []
var _stage_map_floor_labels: Array[Label] = []
var _stage_map_last_signature: String = ""

## Damage number pool — pre-allocated labels for zero-alloc spawning.
var _damage_pool: Array[Label] = []
var _damage_pool_index: int = 0


func _ready() -> void:
	UIStyleRef.apply_theme($Panel)
	_override_hud_panels()
	process_mode = PROCESS_MODE_ALWAYS
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_tp_changed.connect(_on_tp_changed)
	EventBus.combat_hit_event.connect(_on_hit_event)
	EventBus.combat_combo_step.connect(_on_combo_step)
	EventBus.combat_combo_dropped.connect(_on_combo_dropped)
	EventBus.rpg_gold_changed.connect(_on_gold_changed)
	EventBus.audio_track_changed.connect(_on_audio_track_changed)
	EventBus.rpg_level_up.connect(_on_level_up)
	EventBus.rpg_xp_gained.connect(_on_xp_gained)
	EventBus.rpg_character_switched.connect(_on_character_switched)
	EventBus.dungeon_entered.connect(_on_dungeon_entered)
	EventBus.stage_encounter_triggered.connect(_on_encounter_triggered)
	EventBus.stage_encounter_cleared.connect(_on_encounter_cleared)
	EventBus.stage_completed.connect(_on_stage_completed)
	hp_bar_bg.resized.connect(_refresh_bar_widths)
	tp_bar_bg.resized.connect(_refresh_bar_widths)
	combo_badge.visible = false
	combo_badge.scale = Vector2.ONE
	now_playing_strip.visible = false
	now_playing_strip.modulate.a = 0.0
	state_badge.visible = false
	action_hints.modulate.a = 0.0
	hp_label.text = "100 / 100"
	tp_label.text = "0 / 100"
	gold_label.text = str(GameState.gold)
	call_deferred("_refresh_bar_widths")
	_update_pilot_label()
	_init_damage_pool()
	_create_rpg_hud()
	_create_stage_map_panel()
	_refresh_stage_map_if_needed(true)
	_update_demo_hint()
	_refresh_layout()
	get_viewport().size_changed.connect(_refresh_layout)


func _process(delta: float) -> void:
	# Smooth HP bar lerp.
	if absf(_hp_display - _hp_target) > 0.001:
		_hp_display = lerpf(_hp_display, _hp_target, Constants.HUD_HP_BAR_LERP_SPEED * delta)
		_update_hp_bar_visual()

	# Combo counter fade timer.
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			combo_badge.visible = false
			combo_badge.scale = Vector2.ONE
			_combo_count = 0

	if _now_playing_timer > 0.0:
		_now_playing_timer -= delta
		if _now_playing_timer <= 0.0:
			_hide_now_playing()

	var hint_alpha := move_toward(action_hints.modulate.a, _action_hints_target_alpha, delta * 4.0)
	action_hints.modulate.a = hint_alpha
	action_hints.visible = hint_alpha > 0.02
	_refresh_stage_map_if_needed()


func _on_health_changed(_player_index: int, new_hp: float, max_hp: float) -> void:
	_hp_target = clampf(new_hp / max_hp, 0.0, 1.0) if max_hp > 0.0 else 0.0
	hp_label.text = "%.0f / %.0f" % [new_hp, max_hp]
	# Low HP warning pulse.
	if _hp_target <= 0.25 and _hp_target > 0.0 and not _hp_low_pulse_active:
		_start_hp_low_pulse()
	elif (_hp_target > 0.25 or _hp_target <= 0.0) and _hp_low_pulse_active:
		_stop_hp_low_pulse()


## Updates the pilot name label from active party and Constants.
func _update_pilot_label() -> void:
	var char_id: StringName = GameState.active_party[0] if GameState.active_party.size() > 0 else &"alys"
	var char_name: String = Constants.CHARACTER_DISPLAY_NAMES.get(char_id, str(char_id).to_upper())
	var char_role: String = Constants.CHARACTER_ROLES.get(char_id, "")
	var level := int(GameState.character_data.get(char_id, {}).get("level", 1))
	pilot_label.text = char_name.to_upper()
	role_label.text = "LV %d  //  %s" % [level, char_role.to_upper()]


func _on_tp_changed(_player_index: int, new_tp: float, max_tp: float) -> void:
	_tp_ratio = clampf(new_tp / max_tp, 0.0, 1.0) if max_tp > 0.0 else 0.0
	_update_tp_bar_visual()
	tp_label.text = "%.0f / %.0f" % [new_tp, max_tp]


func _on_hit_event(event: CombatHitEvent) -> void:
	_combo_count += 1
	_combo_timer = Constants.HUD_COMBO_DISPLAY_TIME
	combo_label.text = "HIT %d" % _combo_count
	combo_badge.visible = true
	# Escalating punch strength for higher combos.
	var punch_strength := minf(0.08 + _combo_count * 0.015, 0.2)
	UIStyleRef.punch(combo_badge, punch_strength)
	# Flash the combo label brighter on milestone hits.
	if _combo_count % 5 == 0:
		UIStyleRef.flash_label(combo_label, Color(1.0, 0.95, 0.5), 0.4)
	# Spawn floating damage number.
	_spawn_damage_number(event.damage, event.hit_position)


func _on_combo_step(_player: Node, _step: int) -> void:
	pass


func _on_combo_dropped(_player: Node) -> void:
	_combo_count = 0
	_combo_timer = 0.0
	combo_badge.visible = false


func _on_gold_changed(new_total: int) -> void:
	gold_label.text = str(new_total)
	UIStyleRef.flash_label(gold_label, Color(1.0, 0.9, 0.4), 0.5)


func _on_audio_track_changed(_track_id: StringName, display_name: String) -> void:
	_show_now_playing(display_name)


func _refresh_bar_widths() -> void:
	_hp_fill_width = maxf(hp_bar_bg.size.x - (BAR_EDGE_PADDING * 2.0), 0.0)
	_tp_fill_width = maxf(tp_bar_bg.size.x - (BAR_EDGE_PADDING * 2.0), 0.0)
	_update_hp_bar_visual()
	_update_tp_bar_visual()


func _update_hp_bar_visual() -> void:
	hp_bar_fill.position = Vector2(BAR_EDGE_PADDING, BAR_EDGE_PADDING)
	hp_bar_fill.size = Vector2(
		_hp_fill_width * _hp_display,
		maxf(hp_bar_bg.size.y - (BAR_EDGE_PADDING * 2.0), 0.0)
	)
	if _hp_display > 0.5:
		hp_bar_fill.color = Color(0.2, 0.8, 0.2).lerp(Color(0.9, 0.9, 0.2), (1.0 - _hp_display) * 2.0)
	else:
		hp_bar_fill.color = Color(0.9, 0.9, 0.2).lerp(Color(0.9, 0.1, 0.1), (0.5 - _hp_display) * 2.0)


func _update_tp_bar_visual() -> void:
	tp_bar_fill.position = Vector2(BAR_EDGE_PADDING, BAR_EDGE_PADDING)
	tp_bar_fill.size = Vector2(
		_tp_fill_width * _tp_ratio,
		maxf(tp_bar_bg.size.y - (BAR_EDGE_PADDING * 2.0), 0.0)
	)
	tp_bar_fill.color = Color(0.18, 0.5, 0.95).lerp(Color(0.33, 0.86, 1.0), _tp_ratio)
	# TP full glow.
	if _tp_ratio >= 1.0 and not _tp_full_glow_active:
		_tp_full_glow_active = true
		UIStyleRef.start_glow_pulse(tp_bar_fill, Color(1.2, 1.15, 1.1), Color(0.9, 0.95, 1.0), 1.5)
	elif _tp_ratio < 1.0 and _tp_full_glow_active:
		_tp_full_glow_active = false
		tp_bar_fill.self_modulate = Color.WHITE


func _init_damage_pool() -> void:
	for i in Constants.DAMAGE_NUMBER_POOL_SIZE:
		var label := Label.new()
		label.size = Vector2(72, 40)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 28)
		label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.65))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		label.add_theme_constant_override("outline_size", 4)
		label.visible = false
		add_child(label)
		_damage_pool.append(label)


func _spawn_damage_number(damage: float, world_pos: Vector3) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var screen_pos := cam.unproject_position(world_pos)

	# Round-robin through the pool.
	var label := _damage_pool[_damage_pool_index]
	_damage_pool_index = (_damage_pool_index + 1) % _damage_pool.size()

	label.text = str(int(damage))
	label.position = screen_pos - (label.size * 0.5)
	label.modulate.a = 1.0
	label.scale = Vector2.ONE
	label.visible = true

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(label, "position:y", label.position.y - Constants.HUD_DAMAGE_NUMBER_RISE_SPEED, Constants.HUD_DAMAGE_NUMBER_LIFETIME)
	tween.parallel().tween_property(label, "modulate:a", 0.0, Constants.HUD_DAMAGE_NUMBER_LIFETIME)
	tween.parallel().tween_property(label, "scale", Vector2(1.15, 1.15), Constants.HUD_DAMAGE_NUMBER_LIFETIME * 0.4)
	tween.tween_callback(func() -> void: label.visible = false)


## Update debug state info (called from arena).
func update_state_info(info: String) -> void:
	if state_label:
		state_label.text = info
		state_badge.visible = not info.is_empty()


## Update room objective copy in the top tactical bar.
func update_objective(text: String) -> void:
	if objective_label:
		UIStyleRef.animate_objective(objective_label, text)


func _update_demo_hint() -> void:
	sub_hint_label.text = "F3 AI | F4 Perf | F5 Input | F6 Events | F7 Retry | F8 Photo | F9 Bundle | F10 Validate"


func _show_now_playing(display_name: String) -> void:
	if _compact_layout:
		return
	now_playing_label.text = "Now Playing  |  %s" % display_name
	_now_playing_timer = NOW_PLAYING_DISPLAY_TIME
	now_playing_strip.visible = true

	if _now_playing_tween != null:
		_now_playing_tween.kill()
		_now_playing_tween = null

	now_playing_strip.modulate.a = 0.0
	now_playing_strip.offset_top = NOW_PLAYING_TOP - NOW_PLAYING_SHOW_OFFSET
	now_playing_strip.offset_bottom = NOW_PLAYING_BOTTOM - NOW_PLAYING_SHOW_OFFSET
	_now_playing_tween = create_tween()
	_now_playing_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_now_playing_tween.set_trans(Tween.TRANS_QUAD)
	_now_playing_tween.set_ease(Tween.EASE_OUT)
	_now_playing_tween.tween_property(now_playing_strip, "modulate:a", 1.0, 0.16)
	_now_playing_tween.parallel().tween_property(now_playing_strip, "offset_top", NOW_PLAYING_TOP, 0.16)
	_now_playing_tween.parallel().tween_property(now_playing_strip, "offset_bottom", NOW_PLAYING_BOTTOM, 0.16)
	_now_playing_tween.finished.connect(func() -> void:
		_now_playing_tween = null
	)


func _hide_now_playing() -> void:
	if not now_playing_strip.visible:
		return

	if _now_playing_tween != null:
		_now_playing_tween.kill()
		_now_playing_tween = null

	_now_playing_tween = create_tween()
	_now_playing_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_now_playing_tween.set_trans(Tween.TRANS_QUAD)
	_now_playing_tween.set_ease(Tween.EASE_OUT)
	_now_playing_tween.tween_property(now_playing_strip, "modulate:a", 0.0, 0.2)
	_now_playing_tween.parallel().tween_property(now_playing_strip, "offset_top", NOW_PLAYING_TOP - NOW_PLAYING_HIDE_OFFSET, 0.2)
	_now_playing_tween.parallel().tween_property(now_playing_strip, "offset_bottom", NOW_PLAYING_BOTTOM - NOW_PLAYING_HIDE_OFFSET, 0.2)
	_now_playing_tween.finished.connect(func() -> void:
		now_playing_strip.visible = false
		_now_playing_tween = null
	)


## Start pulsing red glow on HP bar when health is critically low.
func _start_hp_low_pulse() -> void:
	_hp_low_pulse_active = true
	if _hp_low_tween != null:
		_hp_low_tween.kill()
	_hp_low_tween = create_tween()
	_hp_low_tween.set_loops()
	_hp_low_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_hp_low_tween.tween_property(hp_bar_bg, "self_modulate", Color(1.3, 0.8, 0.8), 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_hp_low_tween.tween_property(hp_bar_bg, "self_modulate", Color(1.0, 0.9, 0.9), 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


## Stop the low HP pulse effect.
func _stop_hp_low_pulse() -> void:
	_hp_low_pulse_active = false
	if _hp_low_tween != null:
		_hp_low_tween.kill()
		_hp_low_tween = null
	hp_bar_bg.self_modulate = Color.WHITE


## Override .tscn panel styles with glass-morphism variants.
func _override_hud_panels() -> void:
	var accent := Color(0.3, 0.5, 0.8)
	# Primary panels — higher alpha for combat readability.
	for panel: PanelContainer in [$Panel/TopFrame, $Panel/StatsCard]:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.03, 0.05, 0.09, 0.72)
		s.border_color = Color(accent.r, accent.g, accent.b, 0.22)
		s.border_width_left = 1
		s.border_width_top = 1
		s.border_width_right = 1
		s.border_width_bottom = 1
		s.corner_radius_top_left = 6
		s.corner_radius_top_right = 6
		s.corner_radius_bottom_left = 6
		s.corner_radius_bottom_right = 6
		s.shadow_color = Color(accent.r, accent.g, accent.b, 0.08)
		s.shadow_size = 10
		s.shadow_offset = Vector2(0, 1)
		s.anti_aliasing = true
		panel.add_theme_stylebox_override("panel", s)
	# Secondary panels.
	for panel: PanelContainer in [combo_badge, now_playing_strip, state_badge]:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.04, 0.06, 0.1, 0.54)
		s.border_color = Color(accent.r, accent.g, accent.b, 0.16)
		s.border_width_left = 1
		s.border_width_top = 1
		s.border_width_right = 1
		s.border_width_bottom = 1
		s.corner_radius_top_left = 6
		s.corner_radius_top_right = 6
		s.corner_radius_bottom_left = 6
		s.corner_radius_bottom_right = 6
		s.shadow_color = Color(accent.r, accent.g, accent.b, 0.06)
		s.shadow_size = 6
		s.shadow_offset = Vector2(0, 1)
		s.anti_aliasing = true
		panel.add_theme_stylebox_override("panel", s)
	var hint_style := StyleBoxFlat.new()
	hint_style.bg_color = Color(0.04, 0.06, 0.1, 0.38)
	hint_style.border_color = Color(accent.r, accent.g, accent.b, 0.08)
	hint_style.border_width_left = 1
	hint_style.border_width_top = 1
	hint_style.border_width_right = 1
	hint_style.border_width_bottom = 1
	hint_style.corner_radius_top_left = 6
	hint_style.corner_radius_top_right = 6
	hint_style.corner_radius_bottom_left = 6
	hint_style.corner_radius_bottom_right = 6
	hint_style.anti_aliasing = true
	action_hints.add_theme_stylebox_override("panel", hint_style)
	# Nested objective sub-panel.
	var obj_panel: PanelContainer = $Panel/TopFrame/Margin/HBox/ObjectivePanel
	var obj_s := StyleBoxFlat.new()
	obj_s.bg_color = Color(0.03, 0.05, 0.09, 0.56)
	obj_s.border_color = Color(accent.r, accent.g, accent.b, 0.18)
	obj_s.border_width_left = 1
	obj_s.border_width_top = 1
	obj_s.border_width_right = 1
	obj_s.border_width_bottom = 1
	obj_s.corner_radius_top_left = 6
	obj_s.corner_radius_top_right = 6
	obj_s.corner_radius_bottom_left = 6
	obj_s.corner_radius_bottom_right = 6
	obj_s.anti_aliasing = true
	obj_panel.add_theme_stylebox_override("panel", obj_s)


func _refresh_layout() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var size := viewport.get_visible_rect().size
	_compact_layout = size.x < 1380.0 or size.y < 860.0
	pilot_label.add_theme_font_size_override("font_size", 15 if _compact_layout else 17)
	role_label.add_theme_font_size_override("font_size", 11 if _compact_layout else 12)
	objective_label.add_theme_font_size_override("font_size", 13 if _compact_layout else 14)
	hp_label.add_theme_font_size_override("font_size", 15 if _compact_layout else 16)
	tp_label.add_theme_font_size_override("font_size", 15 if _compact_layout else 16)
	gold_label.add_theme_font_size_override("font_size", 15 if _compact_layout else 16)
	combo_label.add_theme_font_size_override("font_size", 26 if _compact_layout else 30)
	now_playing_label.add_theme_font_size_override("font_size", 12 if _compact_layout else 13)
	state_label.add_theme_font_size_override("font_size", 12 if _compact_layout else 13)
	if _level_label:
		_level_label.add_theme_font_size_override("font_size", 14 if _compact_layout else 16)
	if _technique_label:
		_technique_label.add_theme_font_size_override("font_size", 12 if _compact_layout else 14)
	sub_hint_label.visible = not _compact_layout
	_update_demo_hint()
	if _compact_layout and now_playing_strip.visible:
		now_playing_strip.visible = false
		now_playing_strip.modulate.a = 0.0
	if _stage_map_panel:
		_stage_map_panel.offset_left = 20.0
		_stage_map_panel.offset_top = -STAGE_MAP_PANEL_HEIGHT - 24.0
		_stage_map_panel.offset_right = 20.0 + STAGE_MAP_PANEL_WIDTH
		_stage_map_panel.offset_bottom = -24.0
		_stage_map_panel.visible = RuntimeState.stage_mode and not _compact_layout
	_update_tertiary_visibility()


func _update_tertiary_visibility() -> void:
	_action_hints_target_alpha = 0.0 if _combat_active or _compact_layout else 0.54
	if _compact_layout:
		state_badge.modulate.a = 0.86
	else:
		state_badge.modulate.a = 1.0


## Create RPG HUD elements (level, XP bar, technique indicator) in code.
func _create_rpg_hud() -> void:
	var stats_card := $Panel/StatsCard/Margin/VBox
	if stats_card == null:
		return

	# Level label — inserted before gold block.
	_level_label = Label.new()
	_level_label.name = "LevelLabel"
	_level_label.add_theme_font_size_override("font_size", 16)
	_level_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
	stats_card.add_child(_level_label)

	# XP bar (thin, below level label).
	var xp_block := HBoxContainer.new()
	xp_block.name = "XPBlock"
	xp_block.custom_minimum_size = Vector2(0, 10)
	stats_card.add_child(xp_block)

	_xp_bar_bg = ColorRect.new()
	_xp_bar_bg.color = Color(0.15, 0.15, 0.2, 0.9)
	_xp_bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp_bar_bg.custom_minimum_size = Vector2(0, 8)
	_xp_bar_bg.resized.connect(_update_rpg_display)
	xp_block.add_child(_xp_bar_bg)

	_xp_bar_fill = ColorRect.new()
	_xp_bar_fill.color = Color(0.4, 0.7, 1.0)
	_xp_bar_fill.position = Vector2(1, 1)
	_xp_bar_fill.size = Vector2(0, 6)
	_xp_bar_bg.add_child(_xp_bar_fill)

	# Technique indicator.
	_technique_label = Label.new()
	_technique_label.name = "TechniqueLabel"
	_technique_label.add_theme_font_size_override("font_size", 14)
	_technique_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	stats_card.add_child(_technique_label)

	# Initial values.
	_update_rpg_display()


## Refresh RPG HUD labels from GameState.
func _update_rpg_display() -> void:
	var char_id: StringName = GameState.active_party[0] if not GameState.active_party.is_empty() else &"alys"
	var data: Dictionary = GameState.character_data.get(char_id, {})
	var level: int = data.get("level", 1)

	if _level_label:
		_level_label.text = "LV %d" % level

	# XP bar fill.
	if _xp_bar_bg and _xp_bar_fill:
		var xp: int = data.get("xp", 0)
		var xp_next := int(floorf(Constants.LEVEL_XP_BASE * pow(Constants.LEVEL_XP_GROWTH_RATE, level - 1)))
		var progress: float = float(xp) / maxf(float(xp_next), 1.0)
		var fill_width := maxf(_xp_bar_bg.size.x - 2.0, 0.0) * clampf(progress, 0.0, 1.0)
		_xp_bar_fill.size = Vector2(fill_width, 6)

	if _technique_label:
		_technique_label.text = ""
	role_label.text = "LV %d  //  %s" % [level, Constants.CHARACTER_ROLES.get(char_id, "").to_upper()]


func _on_level_up(_player_index: int, new_level: int) -> void:
	if _level_label:
		_level_label.text = "LV %d" % new_level
		UIStyleRef.flash_label(_level_label, Color(1.0, 1.0, 0.5), 0.6)
	role_label.text = "LV %d  //  %s" % [
		new_level,
		Constants.CHARACTER_ROLES.get(
			GameState.active_party[0] if not GameState.active_party.is_empty() else &"alys",
			""
		).to_upper()
	]


func _on_xp_gained(_player_index: int, _amount: int) -> void:
	_update_rpg_display()


func _on_character_switched(_old_char: StringName, _new_char: StringName) -> void:
	_update_pilot_label()
	_update_rpg_display()


func _on_dungeon_entered(_dungeon_id: StringName) -> void:
	_combat_active = false
	_update_tertiary_visibility()
	if RuntimeState.stage_mode:
		update_objective("Reach the next encounter")
	else:
		update_objective("Clear the room")


func _on_encounter_triggered(encounter_index: int) -> void:
	_combat_active = true
	_update_tertiary_visibility()
	var total: int = RuntimeState.stage_total_encounters
	update_objective("Defeat all enemies (%d/%d)" % [encounter_index + 1, total])


func _on_encounter_cleared(_encounter_index: int) -> void:
	_combat_active = false
	_update_tertiary_visibility()
	update_objective("Move forward")


func _on_stage_completed(_stage_id: StringName) -> void:
	_combat_active = false
	_update_tertiary_visibility()
	update_objective("Stage Complete!")
	_refresh_stage_map_if_needed(true)


func _create_stage_map_panel() -> void:
	var root := $Panel
	if root == null:
		return

	_stage_map_panel = PanelContainer.new()
	_stage_map_panel.name = "StageMapPanel"
	_stage_map_panel.anchor_top = 1.0
	_stage_map_panel.anchor_bottom = 1.0
	_stage_map_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_stage_map_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.05, 0.09, 0.72)
	panel_style.border_color = Color(0.28, 0.72, 0.96, 0.22)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.shadow_color = Color(0.1, 0.5, 0.95, 0.08)
	panel_style.shadow_size = 10
	_stage_map_panel.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	_stage_map_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var header := Label.new()
	header.text = "STAGE MAP"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.58, 0.82, 1.0))
	vbox.add_child(header)

	_stage_map_progress_label = Label.new()
	_stage_map_progress_label.add_theme_font_size_override("font_size", 18)
	_stage_map_progress_label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0))
	vbox.add_child(_stage_map_progress_label)

	_stage_map_floor_row = HBoxContainer.new()
	_stage_map_floor_row.add_theme_constant_override("separation", 8)
	vbox.add_child(_stage_map_floor_row)

	_stage_map_status_label = Label.new()
	_stage_map_status_label.add_theme_font_size_override("font_size", 13)
	_stage_map_status_label.add_theme_color_override("font_color", Color(0.65, 0.84, 0.96))
	vbox.add_child(_stage_map_status_label)


func _refresh_stage_map_if_needed(force: bool = false) -> void:
	var signature := "%s|%d|%d|%d|%d" % [
		str(RuntimeState.stage_mode),
		RuntimeState.stage_floor_count,
		RuntimeState.current_stage_index,
		RuntimeState.stage_encounters_completed,
		RuntimeState.stage_total_encounters
	]
	if force or signature != _stage_map_last_signature:
		_stage_map_last_signature = signature
		_update_stage_map()


func _update_stage_map() -> void:
	if _stage_map_panel == null:
		return
	var total_floors := maxi(RuntimeState.stage_floor_count, 0)
	var should_show := RuntimeState.stage_mode and total_floors > 0 and not _compact_layout
	_stage_map_panel.visible = should_show
	if not should_show:
		return

	_ensure_stage_map_floor_cards(total_floors)

	var current_floor := clampi(RuntimeState.current_stage_index, 0, maxi(total_floors - 1, 0))
	_stage_map_progress_label.text = "Floor %d / %d" % [current_floor + 1, total_floors]
	_stage_map_status_label.text = "Overall clear %d / %d encounters" % [
		RuntimeState.stage_encounters_completed,
		RuntimeState.stage_total_encounters
	]

	for i in _stage_map_floor_cards.size():
		var bg := Color(0.04, 0.08, 0.12, 0.92)
		var border := Color(0.18, 0.3, 0.44, 0.82)
		var text_col := Color(0.58, 0.72, 0.84)
		if i < current_floor:
			bg = Color(0.08, 0.18, 0.12, 0.95)
			border = Color(0.36, 0.88, 0.56, 0.9)
			text_col = Color(0.82, 1.0, 0.86)
		elif i == current_floor:
			bg = Color(0.05, 0.13, 0.19, 0.98)
			border = Color(0.44, 0.84, 1.0, 0.96)
			text_col = Color(0.92, 0.98, 1.0)
		_stage_map_floor_cards[i].add_theme_stylebox_override("panel", _make_stage_map_floor_style(bg, border))
		_stage_map_floor_labels[i].text = _get_stage_floor_label(i)
		_stage_map_floor_labels[i].add_theme_color_override("font_color", text_col)


func _ensure_stage_map_floor_cards(total_floors: int) -> void:
	if _stage_map_floor_cards.size() == total_floors:
		return
	for child in _stage_map_floor_row.get_children():
		child.queue_free()
	_stage_map_floor_cards.clear()
	_stage_map_floor_labels.clear()
	for i in total_floors:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(48, 34)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_stage_map_floor_row.add_child(card)
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		card.add_child(label)
		_stage_map_floor_cards.append(card)
		_stage_map_floor_labels.append(label)


func _make_stage_map_floor_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.shadow_color = Color(0, 0, 0, 0.2)
	style.shadow_size = 3
	return style


func _get_stage_floor_label(index: int) -> String:
	if RuntimeState.current_dungeon_id == &"dungeon_1":
		return "B%d" % (index + 1)
	return "F%d" % (index + 1)
