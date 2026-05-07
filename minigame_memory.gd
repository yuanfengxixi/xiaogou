# minigame_memory.gd
# Instant Memory mini-game (瞬时记忆).
# 8×8 grid. Round N highlights N random cells for X seconds, then hides them.
# Player must click all N hidden cells (any order). Wrong click = immediate fail.
# Reach cfg_target_round → pass.
#
# Usage:
#   var mg := MinigameMemory.new()
#   mg.configure(MinigameMemory.preset_zhuji())
#   mg.minigame_completed.connect(_on_result)
#   choices_box.add_child(mg)
#
# Result values: "pass" | "fail"

class_name MinigameMemory
extends VBoxContainer

signal minigame_completed(result: String)

# ── Config ────────────────────────────────────────────────────────
var cfg_narrative:    String = ""
var cfg_grid_size:    int    = 8
var cfg_target_round: int    = 5      # clear this many rounds → pass
var cfg_memorize_time: float = 3.0    # seconds to show highlights

# ── Runtime ───────────────────────────────────────────────────────
var _round:        int    = 0          # current round number (1-indexed)
var _highlights:   Array  = []         # cell indices to remember this round
var _clicked:      Array  = []         # correctly clicked indices this round
var _phase:        String = "memorize" # "memorize" | "answer"
var _phase_timer:  float  = 0.0
var _active:       bool   = false

# ── UI refs ───────────────────────────────────────────────────────
var _narrative_lbl: Label
var _hud_lbl:       Label
var _grid:          GridContainer
var _buttons:       Array = []

const _CELL_MIN: Vector2 = Vector2(72, 72)
const _C_DEFAULT:   Color = Color(0.22, 0.22, 0.28)
const _C_HIGHLIGHT: Color = Color(1.00, 0.84, 0.12)
const _C_CORRECT:   Color = Color(0.18, 0.68, 0.22)
const _C_WRONG:     Color = Color(0.82, 0.20, 0.20)

# ── Presets ───────────────────────────────────────────────────────

static func preset_qiqi() -> Dictionary:
	return {
		"narrative":     "凝目不动——记住高亮之处。",
		"target_round":  4,
		"memorize_time": 3.0,
	}

static func preset_zhuji() -> Dictionary:
	return {
		"narrative":     "心境澄澈——记住所有亮处。",
		"target_round":  6,
		"memorize_time": 2.5,
	}

static func preset_jindan() -> Dictionary:
	return {
		"narrative":     "金丹之劫——一目千机。",
		"target_round":  8,
		"memorize_time": 2.0,
	}

# ── Setup ─────────────────────────────────────────────────────────

func configure(d: Dictionary) -> void:
	if d.has("narrative"):     cfg_narrative     = d["narrative"]
	if d.has("grid_size"):     cfg_grid_size     = d["grid_size"]
	if d.has("target_round"):  cfg_target_round  = d["target_round"]
	if d.has("memorize_time"): cfg_memorize_time = d["memorize_time"]

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_build_ui()
	_start_round()

func _build_ui() -> void:
	if cfg_narrative != "":
		_narrative_lbl = Label.new()
		_narrative_lbl.text = cfg_narrative
		_narrative_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		_narrative_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		add_child(_narrative_lbl)

	_hud_lbl = Label.new()
	_hud_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	add_child(_hud_lbl)

	_grid = GridContainer.new()
	_grid.columns = cfg_grid_size
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	add_child(_grid)

	var total: int = cfg_grid_size * cfg_grid_size
	for i in range(total):
		var btn := Button.new()
		btn.text = ""
		btn.custom_minimum_size = _CELL_MIN
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_click.bind(i))
		_apply_color(btn, _C_DEFAULT)
		_grid.add_child(btn)
		_buttons.append(btn)

func _apply_color(btn: Button, color: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal",   sb)
	btn.add_theme_stylebox_override("hover",    sb)
	btn.add_theme_stylebox_override("pressed",  sb)
	btn.add_theme_stylebox_override("focus",    sb)
	btn.add_theme_stylebox_override("disabled", sb)

# ── Round flow ────────────────────────────────────────────────────

func _start_round() -> void:
	_round += 1
	_clicked.clear()

	var total: int = cfg_grid_size * cfg_grid_size
	var pool: Array = []
	for i in range(total):
		pool.append(i)
	pool.shuffle()
	_highlights = pool.slice(0, _round)

	# Reset board
	for btn in _buttons:
		_apply_color(btn, _C_DEFAULT)
		btn.disabled = true

	# Show highlights
	for idx in _highlights:
		_apply_color(_buttons[idx], _C_HIGHLIGHT)

	_phase       = "memorize"
	_phase_timer = cfg_memorize_time
	_active      = true
	_update_hud()

func _enter_answer_phase() -> void:
	_phase = "answer"
	for btn in _buttons:
		_apply_color(btn, _C_DEFAULT)
		btn.disabled = false
	_update_hud()

func _process(delta: float) -> void:
	if not _active:
		return
	if _phase == "memorize":
		_phase_timer -= delta
		if _phase_timer <= 0.0:
			_phase_timer = 0.0
			_enter_answer_phase()
			return
		_update_hud()

func _update_hud() -> void:
	if _phase == "memorize":
		_hud_lbl.text = "第 %d / %d 关  |  记忆中：%.1f 秒" % [_round, cfg_target_round, _phase_timer]
	else:
		_hud_lbl.text = "第 %d / %d 关  |  已点 %d / %d" % [_round, cfg_target_round, _clicked.size(), _highlights.size()]

# ── Click ─────────────────────────────────────────────────────────

func _on_click(idx: int) -> void:
	if not _active or _phase != "answer":
		return
	if idx in _clicked:
		return

	if idx in _highlights:
		_clicked.append(idx)
		_apply_color(_buttons[idx], _C_CORRECT)
		_buttons[idx].disabled = true
		_update_hud()
		if _clicked.size() >= _highlights.size():
			if _round >= cfg_target_round:
				_active = false
				_disable_all()
				minigame_completed.emit("pass")
			else:
				_active = false
				await get_tree().create_timer(0.6).timeout
				_start_round()
	else:
		_active = false
		_apply_color(_buttons[idx], _C_WRONG)
		_disable_all()
		minigame_completed.emit("fail")

func _disable_all() -> void:
	for btn in _buttons:
		btn.disabled = true
