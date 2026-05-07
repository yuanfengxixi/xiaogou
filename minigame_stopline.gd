# minigame_stopline.gd
# Reusable stop-the-line timing mini-game.
#
# Usage:
#   var mg := MinigameStopline.new()
#   mg.configure(MinigameStopline.preset_yangtian_skill())
#   mg.minigame_completed.connect(_on_exam_result)
#   choices_box.add_child(mg)
#
# Result values: "pass" | "fail" | "death"
# "death" only possible when cfg_death_zone is set (修罗门).

class_name MinigameStopline
extends VBoxContainer

signal minigame_completed(result: String)

# ── Config (set via configure() before adding to tree) ────────────
var cfg_narrative: String  = ""
var cfg_speed:     float   = 200.0        # pixel/sec at reference width 600
var cfg_pass_zone: Array   = [0.30, 0.70] # [start_ratio, end_ratio]
var cfg_death_zone: Array  = []           # [] = none; 修罗门: [0.44, 0.56]
var cfg_random:    bool    = false        # 草门: chaotic cursor
var cfg_rounds:    int     = 1            # 衍天宗实力路: 3 consecutive
var cfg_random_pass_zone: bool = false    # 衍天宗：每轮 pass_zone 位置随机（保持宽度）

# ── Runtime state ─────────────────────────────────────────────────
var _cursor_ratio: float = 0.0  # 0.0–1.0, layout-independent
var _dir:          int   = 1
var _round:        int   = 0
var _active:       bool  = false
var _rand_timer:   float = 0.0

# ── UI refs ───────────────────────────────────────────────────────
var _bar:       _ZoneBar
var _cursor:    ColorRect
var _tap_btn:   Button
var _round_lbl: Label

const _BAR_H:    float = 52.0
const _CURSOR_W: float = 6.0
const _REF_W:    float = 600.0  # reference width for speed calibration

# ── Preset configs ────────────────────────────────────────────────

static func preset_yangtian_talent() -> Dictionary:
	return {
		"narrative":  "灵根鉴定中……",
		"speed":      100.0,
		"pass_zone":  [0.20, 0.80],
		"rounds":     1,
	}

static func preset_yangtian_skill() -> Dictionary:
	return {
		"narrative":  "衍天宗·实力路——刀走如电，绿区飘忽，七关连续，分毫不差方可入门。",
		"speed":      500.0,
		"pass_zone":  [0.46, 0.54],
		"rounds":     7,
		"random_pass_zone": true,
	}

static func preset_xiuluo() -> Dictionary:
	return {
		"narrative":  "修罗门考核。死亡区就在眼前，你看见了。",
		"speed":      220.0,
		"pass_zone":  [0.25, 0.70],
		"death_zone": [0.44, 0.56],
		"rounds":     1,
	}

static func preset_qingyun() -> Dictionary:
	return {
		"narrative":  "青云宗考核——心正则通，三关皆验。",
		"speed":      200.0,
		"pass_zone":  [0.32, 0.68],
		"rounds":     3,
	}

static func preset_caomen() -> Dictionary:
	return {
		"narrative":  "缘分自有定数，强求无益。",
		"speed":      200.0,
		"pass_zone":  [0.30, 0.70],
		"random":     true,
		"rounds":     1,
	}

static func preset_shouyi() -> Dictionary:
	return {
		"narrative":  "守一门，来了便是自己人。",
		"speed":      90.0,
		"pass_zone":  [0.15, 0.85],
		"rounds":     1,
	}

# ── Setup ─────────────────────────────────────────────────────────

func configure(d: Dictionary) -> void:
	if d.has("narrative"):   cfg_narrative  = d["narrative"]
	if d.has("speed"):       cfg_speed      = d["speed"]
	if d.has("pass_zone"):   cfg_pass_zone  = d["pass_zone"]
	if d.has("death_zone"):  cfg_death_zone = d["death_zone"]
	if d.has("random"):      cfg_random     = d["random"]
	if d.has("rounds"):      cfg_rounds     = d["rounds"]
	if d.has("random_pass_zone"): cfg_random_pass_zone = d["random_pass_zone"]

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_build_ui()
	_begin_round()

func _build_ui() -> void:
	if cfg_narrative != "":
		var lbl := Label.new()
		lbl.text = cfg_narrative
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		add_child(lbl)

	if cfg_rounds > 1:
		_round_lbl = Label.new()
		_round_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		add_child(_round_lbl)

	_bar = _ZoneBar.new()
	_bar.pass_zone  = cfg_pass_zone
	_bar.death_zone = cfg_death_zone
	_bar.custom_minimum_size = Vector2(0, _BAR_H)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_bar)

	_cursor = ColorRect.new()
	_cursor.color    = Color(1.0, 0.92, 0.0)
	_cursor.size     = Vector2(_CURSOR_W, _BAR_H)
	_cursor.position = Vector2(0.0, 0.0)
	_cursor.z_index  = 10
	_bar.add_child(_cursor)

	_tap_btn = Button.new()
	_tap_btn.text = "—— 停 ——"
	_tap_btn.custom_minimum_size = Vector2(0, UITheme.BTN_H)
	_tap_btn.add_theme_font_size_override("font_size", UITheme.FONT_BTN)
	_tap_btn.button_down.connect(_on_tap)
	add_child(_tap_btn)

# ── Round management ──────────────────────────────────────────────

func _begin_round() -> void:
	_cursor_ratio = 0.0
	_dir          = 1
	_rand_timer   = 0.0
	_active       = true
	_tap_btn.disabled = false
	# 衍天宗：每轮 pass_zone 位置随机（保持宽度，移动起点）
	if cfg_random_pass_zone:
		var width: float = cfg_pass_zone[1] - cfg_pass_zone[0]
		var max_start: float = 1.0 - width
		var new_start: float = randf_range(0.05, max_start - 0.05)  # 边缘留 5% 余量
		cfg_pass_zone = [new_start, new_start + width]
		if _bar:
			_bar.pass_zone = cfg_pass_zone
			_bar.queue_redraw()
	if _round_lbl:
		_round_lbl.text = "第 %d / %d 关" % [_round + 1, cfg_rounds]

# ── Cursor movement ───────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _active:
		return

	var speed_ratio := cfg_speed / _REF_W

	if cfg_random:
		_rand_timer -= delta
		if _rand_timer <= 0.0:
			_dir        = 1 if randf() > 0.5 else -1
			_rand_timer = randf_range(0.08, 0.35)

	_cursor_ratio += speed_ratio * _dir * delta
	_cursor_ratio  = clampf(_cursor_ratio, 0.0, 1.0)

	if not cfg_random:
		if _cursor_ratio >= 1.0: _dir = -1
		elif _cursor_ratio <= 0.0: _dir = 1

	var bar_w := _bar.size.x
	if bar_w < 4.0:
		bar_w = _REF_W
	_cursor.position.x = _cursor_ratio * (bar_w - _CURSOR_W)

# ── Input ─────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_tap()
			get_viewport().set_input_as_handled()

func _on_tap() -> void:
	if not _active:
		return
	_active           = false
	_tap_btn.disabled = true

	var result := _check_zone(_cursor_ratio)

	if result == "pass":
		_round += 1
		if _round >= cfg_rounds:
			minigame_completed.emit("pass")
		else:
			await get_tree().create_timer(0.4).timeout
			_begin_round()
	else:
		minigame_completed.emit(result)

func _check_zone(ratio: float) -> String:
	if not cfg_death_zone.is_empty():
		if ratio >= cfg_death_zone[0] and ratio <= cfg_death_zone[1]:
			return "death"
	if ratio >= cfg_pass_zone[0] and ratio <= cfg_pass_zone[1]:
		return "pass"
	return "fail"

# ── Zone bar (inner class, draws zones via _draw) ─────────────────

class _ZoneBar extends Control:
	var pass_zone:  Array = [0.30, 0.70]
	var death_zone: Array = []

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w < 4.0:
			return

		var C_FAIL  := Color(0.22, 0.22, 0.22)
		var C_PASS  := Color(0.12, 0.62, 0.12)
		var C_DEATH := Color(0.58, 0.07, 0.07)

		var ps: float = pass_zone[0] * w
		var pe: float = pass_zone[1] * w

		if death_zone.is_empty():
			if ps > 0.0:  draw_rect(Rect2(0,   0, ps,      h), C_FAIL)
			draw_rect(              Rect2(ps,  0, pe - ps, h), C_PASS)
			if pe < w:    draw_rect(Rect2(pe,  0, w - pe,  h), C_FAIL)
		else:
			var ds: float = death_zone[0] * w
			var de: float = death_zone[1] * w
			if ps > 0.0:  draw_rect(Rect2(0,   0, ps,      h), C_FAIL)
			if ds > ps:   draw_rect(Rect2(ps,  0, ds - ps, h), C_PASS)
			draw_rect(              Rect2(ds,  0, de - ds, h), C_DEATH)
			if de < pe:   draw_rect(Rect2(de,  0, pe - de, h), C_PASS)
			if pe < w:    draw_rect(Rect2(pe,  0, w - pe,  h), C_FAIL)
