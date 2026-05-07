# minigame_schulte.gd
# Schulte table mini-game — click numbers 1..N² in order.
# Wrong click = immediate fail. Timeout = fail. Complete all = pass.
#
# Usage:
#   var mg := MinigameSchulte.new()
#   mg.configure(MinigameSchulte.preset_qiqi())
#   mg.minigame_completed.connect(_on_result)
#   choices_box.add_child(mg)
#
# Result values: "pass" | "fail"

class_name MinigameSchulte
extends VBoxContainer

signal minigame_completed(result: String)

# ── Config ────────────────────────────────────────────────────────
var cfg_narrative:  String = ""
var cfg_grid_size:  int    = 3      # 3=练气 / 4=筑基 / 5=金丹+
var cfg_time_limit: float  = 30.0   # seconds

# ── Runtime ───────────────────────────────────────────────────────
var _next_target: int   = 1
var _time_left:   float = 0.0
var _active:      bool  = false

# ── UI refs ───────────────────────────────────────────────────────
var _narrative_lbl: Label
var _hud_lbl:       Label
var _grid:          GridContainer
var _buttons:       Array = []

const _CELL_MIN: Vector2 = Vector2(96, 96)

# ── Presets ───────────────────────────────────────────────────────

static func preset_qiqi() -> Dictionary:
	return {
		"narrative":  "凝神静心，按 1 至 9 依序点击。",
		"grid_size":  3,
		"time_limit": 30.0,
	}

static func preset_zhuji() -> Dictionary:
	return {
		"narrative":  "心如止水，按 1 至 16 依序点击。",
		"grid_size":  4,
		"time_limit": 45.0,
	}

static func preset_jindan() -> Dictionary:
	return {
		"narrative":  "金丹凝形，按 1 至 25 依序点击。",
		"grid_size":  5,
		"time_limit": 70.0,
	}

# ── Setup ─────────────────────────────────────────────────────────

func configure(d: Dictionary) -> void:
	if d.has("narrative"):  cfg_narrative  = d["narrative"]
	if d.has("grid_size"):  cfg_grid_size  = d["grid_size"]
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
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	add_child(_grid)

	var total: int = cfg_grid_size * cfg_grid_size
	var nums: Array = []
	for i in range(1, total + 1):
		nums.append(i)
	nums.shuffle()

	for n in nums:
		var btn := Button.new()
		btn.text = str(n)
		btn.custom_minimum_size = _CELL_MIN
		btn.add_theme_font_size_override("font_size", UITheme.FONT_BTN)
		btn.pressed.connect(_on_click.bind(n, btn))
		_grid.add_child(btn)
		_buttons.append(btn)

# ── Lifecycle ─────────────────────────────────────────────────────

func _start() -> void:
	_next_target = 1
	_time_left   = cfg_time_limit
	_active      = true
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
	_hud_lbl.text = "下一个：%d   |   剩余：%.1f 秒" % [_next_target, _time_left]

# ── Click handling ────────────────────────────────────────────────

func _on_click(n: int, btn: Button) -> void:
	if not _active:
		return
	if n == _next_target:
		btn.disabled = true
		btn.modulate  = Color(0.5, 1.0, 0.5)
		_next_target += 1
		if _next_target > cfg_grid_size * cfg_grid_size:
			_active = false
			_update_hud()
			minigame_completed.emit("pass")
	else:
		_active = false
		btn.modulate = Color(1.0, 0.4, 0.4)
		_disable_all()
		minigame_completed.emit("fail")

func _disable_all() -> void:
	for b in _buttons:
		b.disabled = true

func _fail_timeout() -> void:
	_active = false
	_disable_all()
	minigame_completed.emit("fail")
