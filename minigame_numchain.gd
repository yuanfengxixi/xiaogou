# minigame_numchain.gd
# 数字串串 — Growing number sequence memory on an 8×8 grid.
# Memorize highlighted positions for 3 s → all cells go dark →
# click cells in ascending order. Wrong cell or wrong order = fail.
# Each successful round adds one number. Complete all rounds → pass.
#
# Result values: "pass" | "fail"

class_name MinigameNumChain
extends VBoxContainer

signal minigame_completed(result: String)

const _COLS:     int   = 8
const _ROWS:     int   = 8
const _CELL:     int   = 56
const _MEMO_SEC: float = 3.0

const _C_NEUTRAL:  Color = Color(0.25, 0.25, 0.30)
const _C_MEMORIZE: Color = Color(0.85, 0.72, 0.20)
const _C_CORRECT:  Color = Color(0.25, 0.70, 0.32)
const _C_REVEAL:   Color = Color(0.55, 0.40, 0.12)

var _start_count:     int = 3
var _required_rounds: int = 3

var _round:        int    = 0
var _cur_count:    int    = 0
var _positions:    Array  = []   # [{cell_idx, value}]
var _click_expect: int    = 1
var _phase:        String = "idle"  # idle|memorize|recall|between|done

var _cells:      Array = []
var _hud_lbl:    Label
var _time_lbl:   Label
var _memo_secs:  float = 0.0
var _memo_timer: Timer

# ── Presets ──────────────────────────────────────────────────────────

static func preset_qiqi() -> Dictionary:
	return {"start_count": 3, "required_rounds": 3}

static func preset_zhuji() -> Dictionary:
	return {"start_count": 4, "required_rounds": 4}

static func preset_jindan() -> Dictionary:
	return {"start_count": 5, "required_rounds": 5}

# ── Setup ────────────────────────────────────────────────────────────

func configure(d: Dictionary) -> void:
	_start_count     = d.get("start_count",     3)
	_required_rounds = d.get("required_rounds", 3)

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_build_ui()
	_start_round()

func _build_ui() -> void:
	var hud_row := HBoxContainer.new()
	hud_row.add_theme_constant_override("separation", 20)

	_hud_lbl = Label.new()
	_hud_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	hud_row.add_child(_hud_lbl)

	_time_lbl = Label.new()
	_time_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	hud_row.add_child(_time_lbl)

	add_child(hud_row)
	add_child(HSeparator.new())

	var grid := GridContainer.new()
	grid.columns = _COLS
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)

	for i in range(_COLS * _ROWS):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(_CELL, _CELL)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_cell.bind(i))
		_paint(btn, _C_NEUTRAL, "")
		grid.add_child(btn)
		_cells.append(btn)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(grid)
	add_child(center)

	_memo_timer = Timer.new()
	_memo_timer.wait_time = 1.0
	_memo_timer.timeout.connect(_on_memo_tick)
	add_child(_memo_timer)

# ── Round lifecycle ──────────────────────────────────────────────────

func _start_round() -> void:
	_round        += 1
	_cur_count    = _start_count + _round - 1
	_click_expect = 1
	_phase        = "memorize"

	var pool: Array = []
	for i in range(_COLS * _ROWS):
		pool.append(i)
	pool.shuffle()

	_positions.clear()
	for i in range(_cur_count):
		_positions.append({"cell_idx": pool[i], "value": i + 1})

	for btn in _cells:
		_paint(btn, _C_NEUTRAL, "")
		btn.disabled = true

	for item in _positions:
		_paint(_cells[item.cell_idx], _C_MEMORIZE, str(item.value))

	_hud_lbl.text = "第%d关/共%d关 — 记忆 %d 个位置" % [_round, _required_rounds, _cur_count]
	_memo_secs    = _MEMO_SEC
	_time_lbl.text = "记忆 3s"
	_memo_timer.start()

func _on_memo_tick() -> void:
	_memo_secs -= 1.0
	if _memo_secs <= 0.0:
		_memo_timer.stop()
		_flip_to_recall()
	else:
		_time_lbl.text = "记忆 %ds" % int(_memo_secs)

func _flip_to_recall() -> void:
	_phase = "recall"
	for btn in _cells:
		_paint(btn, _C_NEUTRAL, "")
		btn.disabled = false
	_hud_lbl.text = "第%d关/共%d关 — 依序点击（共%d个）" % [_round, _required_rounds, _cur_count]
	_time_lbl.text = "下一: 1"

# ── Click handling ───────────────────────────────────────────────────

func _on_cell(idx: int) -> void:
	if _phase != "recall":
		return

	var found_val: int = -1
	for item in _positions:
		if item.cell_idx == idx:
			found_val = item.value
			break

	if found_val == -1 or found_val != _click_expect:
		_do_fail()
		return

	_paint(_cells[idx], _C_CORRECT, str(found_val))
	_cells[idx].disabled = true
	_click_expect += 1
	_time_lbl.text = "下一: %d" % _click_expect

	if _click_expect > _cur_count:
		_phase = "between"
		if _round >= _required_rounds:
			_do_pass()
		else:
			_hud_lbl.text = "第%d关通过！准备下一关…" % _round
			var t := Timer.new()
			t.wait_time  = 0.9
			t.one_shot   = true
			t.timeout.connect(func(): t.queue_free(); _start_round())
			add_child(t)
			t.start()

func _do_fail() -> void:
	_memo_timer.stop()
	_phase = "done"
	for btn in _cells:
		btn.disabled = true
	for item in _positions:
		_paint(_cells[item.cell_idx], _C_REVEAL, str(item.value))
	_hud_lbl.text = "灵念错乱，渡劫失败"
	_emit_after(1.5, "fail")

func _do_pass() -> void:
	_phase = "done"
	_hud_lbl.text = "灵念清明，渡劫成功！"
	_emit_after(1.2, "pass")

func _emit_after(delay: float, result: String) -> void:
	var t := Timer.new()
	t.wait_time = delay
	t.one_shot  = true
	t.timeout.connect(func(): t.queue_free(); minigame_completed.emit(result))
	add_child(t)
	t.start()

# ── Visual helpers ───────────────────────────────────────────────────

func _paint(btn: Button, color: Color, txt: String) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(3)
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(s, sb)
	btn.text = txt
	var fc := Color(0.08, 0.08, 0.08) if color == _C_MEMORIZE else Color.WHITE
	btn.add_theme_color_override("font_color",          fc)
	btn.add_theme_color_override("font_disabled_color", fc)
