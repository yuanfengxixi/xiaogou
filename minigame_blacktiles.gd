# minigame_blacktiles.gd
# Don't-step-on-white-tiles mini-game (single-row variant).
# Each round shows N tiles, exactly 1 black; tap black → next round;
# tap white = immediate fail; row timeout = fail. Reach target → pass.
#
# Usage:
#   var mg := MinigameBlacktiles.new()
#   mg.configure(MinigameBlacktiles.preset_zhuji())
#   mg.minigame_completed.connect(_on_result)
#   choices_box.add_child(mg)
#
# Result values: "pass" | "fail"

class_name MinigameBlacktiles
extends VBoxContainer

signal minigame_completed(result: String)

# ── Config ────────────────────────────────────────────────────────
var cfg_narrative:    String = ""
var cfg_target_count: int    = 10     # rounds to clear
var cfg_time_per_row: float  = 1.5    # seconds per row
var cfg_num_cols:     int    = 4      # tiles per row

# ── Runtime ───────────────────────────────────────────────────────
var _hits:          int   = 0
var _time_left:     float = 0.0
var _active:        bool  = false
var _current_black: int   = 0
var _row_buttons:   Array = []

# ── UI refs ───────────────────────────────────────────────────────
var _narrative_lbl: Label
var _hud_lbl:       Label
var _grid:          GridContainer

const _CELL_MIN: Vector2 = Vector2(96, 96)
const _C_BLACK: Color = Color(0.10, 0.10, 0.10)
const _C_WHITE: Color = Color(0.95, 0.95, 0.95)
const _C_HIT:   Color = Color(0.20, 0.65, 0.20)
const _C_MISS:  Color = Color(0.80, 0.20, 0.20)

# ── Presets ───────────────────────────────────────────────────────

static func preset_qiqi() -> Dictionary:
	return {
		"narrative":    "心如电闪——黑则触，白则避。",
		"target_count": 8,
		"time_per_row": 1.6,
		"num_cols":     4,
	}

static func preset_zhuji() -> Dictionary:
	return {
		"narrative":    "筑基考较——速度更快，心神更专。",
		"target_count": 12,
		"time_per_row": 1.3,
		"num_cols":     4,
	}

static func preset_jindan() -> Dictionary:
	return {
		"narrative":    "金丹凝形——稍纵即逝，差之毫厘。",
		"target_count": 16,
		"time_per_row": 1.0,
		"num_cols":     4,
	}

# ── Setup ─────────────────────────────────────────────────────────

func configure(d: Dictionary) -> void:
	if d.has("narrative"):    cfg_narrative    = d["narrative"]
	if d.has("target_count"): cfg_target_count = d["target_count"]
	if d.has("time_per_row"): cfg_time_per_row = d["time_per_row"]
	if d.has("num_cols"):     cfg_num_cols     = d["num_cols"]

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_build_ui()
	_start()

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
	_grid.columns = cfg_num_cols
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	add_child(_grid)

	for i in range(cfg_num_cols):
		var btn := Button.new()
		btn.custom_minimum_size = _CELL_MIN
		btn.text = ""
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_click.bind(i))
		_grid.add_child(btn)
		_row_buttons.append(btn)

func _apply_color(btn: Button, color: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal",   sb)
	btn.add_theme_stylebox_override("hover",    sb)
	btn.add_theme_stylebox_override("pressed",  sb)
	btn.add_theme_stylebox_override("focus",    sb)
	btn.add_theme_stylebox_override("disabled", sb)

# ── Lifecycle ─────────────────────────────────────────────────────

func _start() -> void:
	_hits   = 0
	_active = true
	_next_row()

func _next_row() -> void:
	_current_black = randi() % cfg_num_cols
	_time_left = cfg_time_per_row
	for i in range(_row_buttons.size()):
		var btn: Button = _row_buttons[i]
		btn.disabled = false
		_apply_color(btn, _C_BLACK if i == _current_black else _C_WHITE)
	_update_hud()

func _process(delta: float) -> void:
	if not _active:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_time_left = 0.0
		_update_hud()
		_fail()
		return
	_update_hud()

func _update_hud() -> void:
	_hud_lbl.text = "进度：%d / %d   |   剩余：%.1f 秒" % [_hits, cfg_target_count, _time_left]

# ── Click ─────────────────────────────────────────────────────────

func _on_click(idx: int) -> void:
	if not _active:
		return
	if idx == _current_black:
		_apply_color(_row_buttons[idx], _C_HIT)
		_hits += 1
		if _hits >= cfg_target_count:
			_active = false
			_disable_all()
			minigame_completed.emit("pass")
		else:
			_next_row()
	else:
		_active = false
		_apply_color(_row_buttons[idx], _C_MISS)
		_disable_all()
		minigame_completed.emit("fail")

func _disable_all() -> void:
	for b in _row_buttons:
		b.disabled = true

func _fail() -> void:
	_active = false
	_disable_all()
	minigame_completed.emit("fail")
