extends Node

# ══════════════════════════════════════════════════════════════
#  任务调度器
#  职责：路由任务到对应难度 handler，统一资格检查
#  子 handler：task_easy / task_normal / task_hard
# ══════════════════════════════════════════════════════════════

const PRESTIGE_LOCK  = -50   # 宗门任务声望封禁线
# PARTIAL_RATIO 已删除 (Rev 3) — outcome 三档评分废除

var _current_difficulty: String = ""
var _easy:   Node
var _normal: Node
var _hard:   Node

func _ready() -> void:
	_easy   = preload("res://task_easy.gd").new()
	_normal = preload("res://task_normal.gd").new()
	_hard   = preload("res://task_hard.gd").new()
	_easy._dispatcher   = self
	_normal._dispatcher = self
	_hard._dispatcher   = self

# ── 对外接口 ─────────────────────────────────────────────────

func get_available_tasks(player) -> Dictionary:
	return {
		"easy":   _easy.get_available(player),
		"normal": _normal.get_available(player),
		"hard":   _hard.get_available(player),
	}

func start_task(id: String, difficulty: String) -> void:
	_current_difficulty = difficulty
	_get_handler().start(id)

func make_choice(index: int) -> Dictionary:
	if _current_difficulty == "easy":
		return {}
	return _get_handler().make_choice(index)

func finish_task(player) -> Dictionary:
	var result: Dictionary = _get_handler().finish(player)
	_current_difficulty = ""
	return result

# ── 小游戏接口（hard 专用）────────────────────────────────────

func is_awaiting_minigame() -> bool:
	if _current_difficulty != "hard":
		return false
	return _hard.awaiting_minigame

func get_current_minigame() -> String:
	if _current_difficulty != "hard":
		return ""
	return _hard.current_minigame_id

func notify_minigame_result(passed: bool) -> void:
	if _current_difficulty == "hard":
		_hard.on_minigame_result(passed)

func abort_current_task() -> void:
	match _current_difficulty:
		"easy":   _easy._current_task = {}
		"normal": _normal._abort()
		"hard":   _hard._reset()
	_current_difficulty = ""

func get_hard_step_data() -> Dictionary:
	if _current_difficulty != "hard":
		return {}
	return _hard.get_current_step_data()

func get_normal_situation_data() -> Dictionary:
	if _current_difficulty != "normal":
		return {}
	return _normal.get_situation_data()

# ── 资格检查（供子 handler 调用）─────────────────────────────

func is_eligible(task: Dictionary, player) -> bool:
	if task.get("realm_required", 0) > player.realm:
		return false
	if task.get("source", "") == "宗门任务":
		if player.faction == "散修":
			return false
		if player.prestige < PRESTIGE_LOCK:
			return false
	return true

# ── 内部 ─────────────────────────────────────────────────────

func _get_handler() -> Node:
	match _current_difficulty:
		"easy":   return _easy
		"normal": return _normal
		"hard":   return _hard
	push_error("TaskDispatcher: no active difficulty set")
	return _easy
