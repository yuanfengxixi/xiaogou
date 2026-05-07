extends Node

# ══════════════════════════════════════════════════════════════
#  简单任务 handler
#  执行流程：接取 → 时间流逝 → 固定奖励，无选择
# ══════════════════════════════════════════════════════════════

const TASKS: Array = [
	# ── 通用宗门任务（所有宗门可见，时间换灵石）─────────────────
	{
		"id":             "te_qi",
		"text":           "藏经阁外门值守",
		"desc":           "三年时间，无事可做，正好顺手抄几页典籍。",
		"source":         "宗门任务",
		"realm_required": 0,
		"years":          3,
		"base_reward":    {"gold": 20, "prestige": 2, "cultivation": 0, "lifespan": 0, "item": ""}
	},
	{
		"id":             "te_zhuji",
		"text":           "灵田巡察",
		"desc":           "巡看山下灵田，记录灵气浓度变化与杂兽踪迹。",
		"source":         "宗门任务",
		"realm_required": 1,
		"years":          5,
		"base_reward":    {"gold": 60, "prestige": 3, "cultivation": 0, "lifespan": 0, "item": ""}
	},
	{
		"id":             "te_jindan",
		"text":           "镇守山门",
		"desc":           "金丹修士例行轮值。八年一班，灵脉自养，闲人勿扰。",
		"source":         "宗门任务",
		"realm_required": 2,
		"years":          8,
		"base_reward":    {"gold": 180, "prestige": 4, "cultivation": 0, "lifespan": 0, "item": ""}
	},
	{
		"id":             "te_yuanying",
		"text":           "整理万年灵材",
		"desc":           "宗门后山囤积的灵材年久失修，需元婴修士细致清点。",
		"source":         "宗门任务",
		"realm_required": 3,
		"years":          10,
		"base_reward":    {"gold": 450, "prestige": 5, "cultivation": 0, "lifespan": 0, "item": ""}
	},
	{
		"id":             "te_huashen",
		"text":           "督导藏经阁修编",
		"desc":           "化神长老挂名督导，实则镇压修编时溢散的远古残识。",
		"source":         "宗门任务",
		"realm_required": 4,
		"years":          12,
		"base_reward":    {"gold": 1100, "prestige": 6, "cultivation": 0, "lifespan": 0, "item": ""}
	},

	# ── 江湖悬赏（散修可接，无年俸，灵石中等偏高）─────────────────
	{
		"id":             "te_jh_low",
		"text":           "押送商队过山",
		"desc":           "城中商行贴的悬赏。两个月路程，遇匪自保即可。",
		"source":         "江湖悬赏",
		"realm_required": 0,
		"years":          3,
		"base_reward":    {"gold": 50, "prestige": 1, "cultivation": 0, "lifespan": 0, "item": ""}
	},
	{
		"id":             "te_jh_mid",
		"text":           "镇压山匪窝点",
		"desc":           "县衙贴出的悬赏。匪首筑基修为，金丹修士过去等于碾死蚂蚁。",
		"source":         "江湖悬赏",
		"realm_required": 2,
		"years":          6,
		"base_reward":    {"gold": 280, "prestige": 2, "cultivation": 0, "lifespan": 0, "item": ""}
	},
	{
		"id":             "te_jh_high",
		"text":           "护送奇珍出境",
		"desc":           "某大族雇佣，将一件来历不明的宝物护送到东海。十年来回，沿路六国，路上凶险只能自担。",
		"source":         "江湖悬赏",
		"realm_required": 3,
		"years":          10,
		"base_reward":    {"gold": 1500, "prestige": 3, "cultivation": 0, "lifespan": 0, "item": ""}
	},
]

var _current_task: Dictionary = {}
var _dispatcher: Node  # 由 task.gd 在 _ready 后赋值

# ── 接口 ─────────────────────────────────────────────────────

func get_available(player) -> Array:
	if _dispatcher == null:
		return []
	return TASKS.filter(func(t): return _dispatcher.is_eligible(t, player))

func start(id: String) -> void:
	_current_task = {}
	for t in TASKS:
		if t["id"] == id:
			_current_task = t.duplicate(true)
			return

func make_choice(_index: int) -> Dictionary:
	return {}  # 简单任务无选择

func finish(player) -> Dictionary:
	if _current_task.is_empty():
		return {}
	var task_data: Dictionary = _current_task
	var base: Dictionary = (task_data["base_reward"] as Dictionary).duplicate()
	var years: int = task_data["years"] as int

	var gold_b:     int    = base.get("gold", 0) as int
	var prestige_b: int    = base.get("prestige", 0) as int
	var item_b:     String = base.get("item", "") as String
	# task_easy: lifespan / cultivation 恒 0

	player.pass_time(years)

	if gold_b > 0:
		player.add_gold(gold_b)
	if prestige_b != 0:
		player.add_prestige(prestige_b)
	var items_arr: Array[String] = []
	if item_b != "":
		player.add_item(item_b)
		items_arr.append(item_b)

	var empty_items: Array[String] = []
	var result := {
		"task_text":      task_data["text"],
		"difficulty":     "easy",
		"years":          years,
		"base_reward":    {"gold": gold_b, "prestige": prestige_b, "cultivation": 0, "lifespan": 0, "item": item_b},
		"modifier_total": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "items": empty_items},
		"rewards":        {"gold": gold_b, "prestige": prestige_b, "cultivation": 0, "items": items_arr},
		"is_dead":        player.lifespan <= 0,
	}
	_current_task = {}
	return result
