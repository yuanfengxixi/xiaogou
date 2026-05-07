# minigame_sudoku.gd
# 4x4 mini-sudoku. Numbers 1-4, 2x2 boxes.
# Tap blank cell to select, tap number 1..4 to fill (清 to clear).
# Fill all blanks correctly → pass. Wrong combination on full board → fail.
# Timeout → fail.
#
# Usage:
#   var mg := MinigameSudoku.new()
#   mg.configure(MinigameSudoku.preset_zhuji())
#   mg.minigame_completed.connect(_on_result)
#   choices_box.add_child(mg)
#
# Result values: "pass" | "fail"

class_name MinigameSudoku
extends VBoxContainer

signal minigame_completed(result: String)

# ── Config ────────────────────────────────────────────────────────
var cfg_narrative:  String = ""
var cfg_blanks:     int    = 4
var cfg_time_limit: float  = 60.0

# ── Runtime ───────────────────────────────────────────────────────
var _solution:      Array = []
var _cells:         Array = []
var _initial_blank: Array = []
var _selected:      int   = -1
var _buttons:       Array = []
var _num_buttons:   Array = []
var _time_left:     float = 0.0
var _active:        bool  = false

# ── UI refs ───────────────────────────────────────────────────────
var _narrative_lbl: Label
var _hud_lbl:       Label
var _grid:          GridContainer
var _num_row:       HBoxContainer

const _CELL_MIN:   Vector2 = Vector2(120, 120)
const _NUM_MIN:    Vector2 = Vector2(96, 96)
const _C_FIXED:    Color   = Color(0.22, 0.22, 0.28)
const _C_BLANK:    Color   = Color(0.40, 0.40, 0.46)
const _C_SELECTED: Color   = Color(1.00, 0.78, 0.20)
const _C_NUM:      Color   = Color(0.25, 0.40, 0.65)

# 4×4 valid solutions（行/列/2x2 宫均含 1..4）
const _SOLUTIONS: Array = [
	[1,2,3,4, 3,4,1,2, 2,1,4,3, 4,3,2,1],
	[1,2,3,4, 3,4,1,2, 4,3,2,1, 2,1,4,3],
	[1,3,2,4, 2,4,1,3, 3,1,4,2, 4,2,3,1],
	[2,4,1,3, 1,3,2,4, 4,2,3,1, 3,1,4,2],
	[3,1,4,2, 4,2,3,1, 1,3,2,4, 2,4,1,3],
	[4,3,2,1, 2,1,4,3, 3,4,1,2, 1,2,3,4],
]

# ── Presets ───────────────────────────────────────────────────────

static func preset_qiqi() -> Dictionary:
	return {
		"narrative":  "九宫初窥，凝神补白。",
		"blanks":     4,
		"time_limit": 60.0,
	}

static func preset_zhuji() -> Dictionary:
	return {
		"narrative":  "筑基九宫，神思如尺。",
		"blanks":     6,
		"time_limit": 75.0,
	}

static func preset_jindan() -> Dictionary:
	return {
		"narrative":  "金丹推演，一格千机。",
		"blanks":     9,
		"time_limit": 90.0,
	}

# ── Setup ─────────────────────────────────────────────────────────

func configure(d: Dictionary) -> void:
	if d.has("narrative"):  cfg_narrative  = d["narrative"]
	if d.has("blanks"):     cfg_blanks     = d["blanks"]
	if d.has("time_limit"): cfg_time_limit = d["time_limit"]

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
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	add_child(_grid)

	for i in range(16):
		var btn := Button.new()
		btn.text = ""
		btn.custom_minimum_size = _CELL_MIN
		btn.add_theme_font_size_override("font_size", UITheme.FONT_EMPHASIS)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_cell.bind(i))
		_grid.add_child(btn)
		_buttons.append(btn)

	add_child(HSeparator.new())

	_num_row = HBoxContainer.new()
	_num_row.add_theme_constant_override("separation", 8)
	add_child(_num_row)

	for n in range(1, 5):
		var nb := Button.new()
		nb.text = str(n)
		nb.custom_minimum_size = _NUM_MIN
		nb.add_theme_font_size_override("font_size", UITheme.FONT_EMPHASIS)
		nb.focus_mode = Control.FOCUS_NONE
		nb.pressed.connect(_on_number.bind(n))
		_apply_color(nb, _C_NUM)
		_num_row.add_child(nb)
		_num_buttons.append(nb)

	var clear_btn := Button.new()
	clear_btn.text = "清"
	clear_btn.custom_minimum_size = _NUM_MIN
	clear_btn.add_theme_font_size_override("font_size", UITheme.FONT_EMPHASIS)
	clear_btn.focus_mode = Control.FOCUS_NONE
	clear_btn.pressed.connect(_on_number.bind(0))
	_apply_color(clear_btn, _C_NUM)
	_num_row.add_child(clear_btn)
	_num_buttons.append(clear_btn)

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
	_solution = (_SOLUTIONS[randi() % _SOLUTIONS.size()] as Array).duplicate()
	_cells = _solution.duplicate()
	_initial_blank.resize(16)
	_initial_blank.fill(false)
	var pool: Array = []
	for i in range(16):
		pool.append(i)
	pool.shuffle()
	var bn: int = mini(cfg_blanks, 16)
	for i in range(bn):
		var bidx: int = pool[i]
		_cells[bidx] = 0
		_initial_blank[bidx] = true
	_selected = -1
	_time_left = cfg_time_limit
	_active = true
	_refresh_board()

func _refresh_board() -> void:
	for i in range(16):
		var btn: Button = _buttons[i]
		btn.text = "" if _cells[i] == 0 else str(_cells[i])
		if _initial_blank[i]:
			_apply_color(btn, _C_SELECTED if i == _selected else _C_BLANK)
			btn.disabled = false
		else:
			_apply_color(btn, _C_FIXED)
			btn.disabled = true

func _process(delta: float) -> void:
	if not _active:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_time_left = 0.0
		_update_hud()
		_fail_timeout()
		return
	_update_hud()

func _update_hud() -> void:
	var blanks_left: int = 0
	for i in range(16):
		if _initial_blank[i] and _cells[i] == 0:
			blanks_left += 1
	_hud_lbl.text = "余空：%d   |   剩余：%.1f 秒" % [blanks_left, _time_left]

# ── Click ─────────────────────────────────────────────────────────

func _on_cell(idx: int) -> void:
	if not _active or not _initial_blank[idx]:
		return
	_selected = idx
	_refresh_board()

func _on_number(n: int) -> void:
	if not _active or _selected < 0:
		return
	_cells[_selected] = n
	if n != 0 and _is_complete():
		if _check_valid():
			_active = false
			_disable_all()
			minigame_completed.emit("pass")
		else:
			_active = false
			_disable_all()
			minigame_completed.emit("fail")
		return
	_refresh_board()

func _is_complete() -> bool:
	for v in _cells:
		if v == 0:
			return false
	return true

func _check_valid() -> bool:
	for r in range(4):
		var seen: Dictionary = {}
		for c in range(4):
			var v: int = _cells[r * 4 + c]
			if seen.has(v):
				return false
			seen[v] = true
	for c in range(4):
		var seen: Dictionary = {}
		for r in range(4):
			var v: int = _cells[r * 4 + c]
			if seen.has(v):
				return false
			seen[v] = true
	for box in range(4):
		@warning_ignore("integer_division")
		var br: int = (box / 2) * 2
		var bc: int = (box % 2) * 2
		var seen: Dictionary = {}
		for dr in range(2):
			for dc in range(2):
				var v: int = _cells[(br + dr) * 4 + (bc + dc)]
				if seen.has(v):
					return false
				seen[v] = true
	return true

func _disable_all() -> void:
	for b in _buttons:
		b.disabled = true
	for b in _num_buttons:
		b.disabled = true

func _fail_timeout() -> void:
	_active = false
	_disable_all()
	minigame_completed.emit("fail")
