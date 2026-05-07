# minigame_oddone.gd
# 独一无二 — Spot the odd symbol out.
# All symbols are the same except one. Click the different one → score.
# Refresh instantly on correct find. Wrong click: no penalty, keep looking.
# 60 s time limit. Score ≥ pass_score → "pass", else → "fail".
#
# Result values: "pass" | "fail"

class_name MinigameOddOne
extends VBoxContainer

signal minigame_completed(result: String)

const _TOTAL_SEC: float = 60.0

const _SYMBOL_PAIRS := [
	["●", "◎"],
	["■", "□"],
	["▲", "△"],
	["◆", "◇"],
	["★", "☆"],
]

var _item_count: int = 24
var _pass_score: int = 10

var _score:     int   = 0
var _time_left: float = _TOTAL_SEC
var _odd_idx:   int   = -1
var _active:    bool  = false

var _buttons:    Array = []
var _hud_lbl:    Label
var _timer_lbl:  Label
var _score_lbl:  Label
var _flow:       HFlowContainer
var _tick_timer: Timer

# ── Presets ──────────────────────────────────────────────────────────

static func preset_qiqi() -> Dictionary:
	return {"item_count": 24, "pass_score": 10}

static func preset_zhuji() -> Dictionary:
	return {"item_count": 30, "pass_score": 10}

static func preset_jindan() -> Dictionary:
	return {"item_count": 40, "pass_score": 10}

# ── Setup ────────────────────────────────────────────────────────────

func configure(d: Dictionary) -> void:
	_item_count = d.get("item_count", 6)
	_pass_score = d.get("pass_score", 5)

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_build_ui()
	_active = true
	_new_round()

func _build_ui() -> void:
	# Header row: status | score | timer
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 20)

	_hud_lbl = Label.new()
	_hud_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_lbl.text = "找出独一无二的图案"
	_hud_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	hdr.add_child(_hud_lbl)

	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 2)

	_score_lbl = Label.new()
	_score_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	_score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_col.add_child(_score_lbl)

	_timer_lbl = Label.new()
	_timer_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_col.add_child(_timer_lbl)

	hdr.add_child(right_col)
	add_child(hdr)
	add_child(HSeparator.new())

	# Flow layout — no grid; items wrap naturally
	_flow = HFlowContainer.new()
	_flow.add_theme_constant_override("h_separation", 14)
	_flow.add_theme_constant_override("v_separation", 14)
	_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_flow)

	# 1 Hz tick for the countdown display
	_tick_timer = Timer.new()
	_tick_timer.wait_time = 1.0
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)
	_tick_timer.start()

	_update_hud()

# ── Round ────────────────────────────────────────────────────────────

func _new_round() -> void:
	for btn in _buttons:
		btn.queue_free()
	_buttons.clear()

	var pair_idx: int = randi() % _SYMBOL_PAIRS.size()
	var pair: Array  = _SYMBOL_PAIRS[pair_idx]
	var majority: String
	var odd_char: String
	if randi() % 2 == 0:
		majority = pair[0]; odd_char = pair[1]
	else:
		majority = pair[1]; odd_char = pair[0]

	_odd_idx = randi() % _item_count

	for i in range(_item_count):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(56, 56)
		btn.focus_mode          = Control.FOCUS_NONE
		btn.text                = odd_char if i == _odd_idx else majority
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_on_btn.bind(i))
		_flow.add_child(btn)
		_buttons.append(btn)

func _on_btn(idx: int) -> void:
	if not _active:
		return
	if idx == _odd_idx:
		_score += 1
		_hud_lbl.text = "找到了！继续…"
		_update_hud()
		_new_round()
	else:
		_hud_lbl.text = "不是这个，再找找"

# ── Countdown ────────────────────────────────────────────────────────

func _on_tick() -> void:
	_time_left -= 1.0
	_update_hud()
	if _time_left <= 0.0:
		_tick_timer.stop()
		_finish()

func _update_hud() -> void:
	_score_lbl.text = "找到：%d / 目标：%d" % [_score, _pass_score]
	_timer_lbl.text = "剩余：%ds" % int(max(_time_left, 0.0))

# ── Finish ───────────────────────────────────────────────────────────

func _finish() -> void:
	_active = false
	for btn in _buttons:
		btn.disabled = true
	if _score >= _pass_score:
		_hud_lbl.text = "眼力过人，渡劫成功！（共找到 %d 处）" % _score
		_emit_after(1.5, "pass")
	else:
		_hud_lbl.text = "眼力不足，渡劫失败（%d / %d）" % [_score, _pass_score]
		_emit_after(1.5, "fail")

func _emit_after(delay: float, result: String) -> void:
	var t := Timer.new()
	t.wait_time = delay
	t.one_shot  = true
	t.timeout.connect(func(): t.queue_free(); minigame_completed.emit(result))
	add_child(t)
	t.start()
