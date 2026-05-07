# minigame_minesweeper.gd
# Minesweeper mini-game.
# Tap cell: if mine → fail; else reveal number, flood-fill on 0.
# Reveal all non-mine cells → pass. Timeout → fail.
#
# Usage:
#   var mg := MinigameMinesweeper.new()
#   mg.configure(MinigameMinesweeper.preset_zhuji())
#   mg.minigame_completed.connect(_on_result)
#   choices_box.add_child(mg)
#
# Result values: "pass" | "fail"

class_name MinigameMinesweeper
extends VBoxContainer

signal minigame_completed(result: String)

# ── Config ────────────────────────────────────────────────────────
var cfg_narrative:  String = ""
var cfg_grid_size:  int    = 5
var cfg_mine_count: int    = 3
var cfg_time_limit: float  = 60.0

# ── Runtime ───────────────────────────────────────────────────────
var _mines:          Array = []
var _revealed:       Array = []
var _buttons:        Array = []
var _safe_remaining: int   = 0
var _time_left:      float = 0.0
var _active:         bool  = false

# ── UI refs ───────────────────────────────────────────────────────
var _narrative_lbl: Label
var _hud_lbl:       Label
var _grid:          GridContainer

const _CELL_MIN:    Vector2 = Vector2(80, 80)
const _C_HIDDEN:    Color   = Color(0.30, 0.30, 0.36)
const _C_REVEALED:  Color   = Color(0.85, 0.85, 0.85)
const _C_MINE:      Color   = Color(0.82, 0.20, 0.20)

# ── Presets ───────────────────────────────────────────────────────

static func preset_qiqi() -> Dictionary:
	return {
		"narrative":  "心眼如灯，避开杀机。",
		"grid_size":  5,
		"mine_count": 3,
		"time_limit": 60.0,
	}

static func preset_zhuji() -> Dictionary:
	return {
		"narrative":  "筑基考心，杀机暗藏。",
		"grid_size":  6,
		"mine_count": 6,
		"time_limit": 75.0,
	}

static func preset_jindan() -> Dictionary:
	return {
		"narrative":  "金丹悟道，一念成劫。",
		"grid_size":  7,
		"mine_count": 10,
		"time_limit": 90.0,
	}

# ── Setup ─────────────────────────────────────────────────────────

func configure(d: Dictionary) -> void:
	if d.has("narrative"):  cfg_narrative  = d["narrative"]
	if d.has("grid_size"):  cfg_grid_size  = d["grid_size"]
	if d.has("mine_count"): cfg_mine_count = d["mine_count"]
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
	_grid.columns = cfg_grid_size
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	add_child(_grid)

	var total: int = cfg_grid_size * cfg_grid_size
	for i in range(total):
		var btn := Button.new()
		btn.text = ""
		btn.custom_minimum_size = _CELL_MIN
		btn.add_theme_font_size_override("font_size", UITheme.FONT_EMPHASIS)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_click.bind(i))
		_apply_color(btn, _C_HIDDEN)
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

# ── Lifecycle ─────────────────────────────────────────────────────

func _start() -> void:
	var total: int = cfg_grid_size * cfg_grid_size
	_revealed.resize(total)
	_revealed.fill(false)
	_mines.clear()
	var pool: Array = []
	for i in range(total):
		pool.append(i)
	pool.shuffle()
	var mc: int = mini(cfg_mine_count, total - 1)
	for i in range(mc):
		_mines.append(pool[i])
	_safe_remaining = total - mc
	_time_left = cfg_time_limit
	_active = true
	_update_hud()

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
	_hud_lbl.text = "雷数：%d   |   剩余：%.1f 秒" % [_mines.size(), _time_left]

# ── Click ─────────────────────────────────────────────────────────

func _on_click(idx: int) -> void:
	if not _active or _revealed[idx]:
		return
	if idx in _mines:
		_active = false
		_apply_color(_buttons[idx], _C_MINE)
		_reveal_all_mines()
		_disable_all()
		minigame_completed.emit("fail")
		return
	_flood_reveal(idx)
	if _safe_remaining <= 0:
		_active = false
		_disable_all()
		minigame_completed.emit("pass")

func _flood_reveal(idx: int) -> void:
	if _revealed[idx] or idx in _mines:
		return
	_revealed[idx] = true
	_safe_remaining -= 1
	var n: int = _count_neighbors(idx)
	var btn: Button = _buttons[idx]
	_apply_color(btn, _C_REVEALED)
	btn.disabled = true
	if n > 0:
		btn.text = str(n)
		var c: Color = _number_color(n)
		btn.add_theme_color_override("font_color", c)
		btn.add_theme_color_override("font_disabled_color", c)
	else:
		for nb in _neighbors(idx):
			if not _revealed[nb] and nb not in _mines:
				_flood_reveal(nb)

func _number_color(n: int) -> Color:
	match n:
		1: return Color(0.10, 0.30, 0.80)
		2: return Color(0.10, 0.55, 0.20)
		3: return Color(0.75, 0.15, 0.15)
		4: return Color(0.30, 0.10, 0.55)
		_: return Color(0.20, 0.20, 0.20)

func _neighbors(idx: int) -> Array:
	@warning_ignore("integer_division")
	var r: int = idx / cfg_grid_size
	var c: int = idx % cfg_grid_size
	var out: Array = []
	for dr in [-1, 0, 1]:
		for dc in [-1, 0, 1]:
			if dr == 0 and dc == 0:
				continue
			var nr: int = r + dr
			var nc: int = c + dc
			if nr >= 0 and nr < cfg_grid_size and nc >= 0 and nc < cfg_grid_size:
				out.append(nr * cfg_grid_size + nc)
	return out

func _count_neighbors(idx: int) -> int:
	var n: int = 0
	for nb in _neighbors(idx):
		if nb in _mines:
			n += 1
	return n

func _reveal_all_mines() -> void:
	for m in _mines:
		_apply_color(_buttons[m], _C_MINE)
		_buttons[m].text = "✸"

func _disable_all() -> void:
	for b in _buttons:
		b.disabled = true

func _fail_timeout() -> void:
	_active = false
	_reveal_all_mines()
	_disable_all()
	minigame_completed.emit("fail")
