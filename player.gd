extends Node

var player_name   = "小狗"
var faction: String = ""
var realm         = 0
var cultivation   = 0
var lifespan      = 80
var lifespan_max  = 80
var prestige      = 0
var gold          = 0
var items         = []
var age           = 20   # 年纪（凡人入门 20 岁；pass_time → age += N）；修行年岁 = age - 20

var mind_max: float = 5.0   # 心志上限（内部 float，UI 显示 floor）
var mind_used: int  = 0     # 累计闭关年数（仅 calculate_retreat 路径递增）

var join_year: int = -1                # 入宗年纪（= 入宗时 player.age）；散修 = -1
var faction_affinity: Dictionary = {}  # {宗门名: int}；入宗 = 50；中途变更见 faction-system.md

var talent_speed  = 0   # 起手 0；通过功法消耗永久 +N（story-system.md §3.5）
var talent_luck   = 0   # = 气运；起手 0；通过气运丹消耗或重要 NPC 击杀（qiyun 字段）+N

var lifespan_pill_used = 0  # 已使用延寿丹次数（药效递减用）
var breakthrough_boost = 0.0  # 破境符激活的额外突破成功率（一次性）

# 海克斯：已抽中的 hex id 列表（含开局 + 突破触发，供图鉴 / 复盘用）
var hex_log: Array = []

# 编年史：玩家一生重大事件按年龄段聚合记录
# entry schema: {age_start: int, age_end: int, type: String, text: String}
# type 取值：birth / join / rogue / retreat / story / breakthrough / death
var life_log: Array = []

func add_life_entry(age_start: int, age_end: int, entry_type: String, text: String) -> void:
	life_log.append({
		"age_start": age_start,
		"age_end": age_end,
		"type": entry_type,
		"text": text,
	})

const REALMS            = ["练气期", "筑基期", "金丹期", "元婴期", "化神期", "飞升"]
const REALM_REQUIRED    = [100, 800, 2000, 5000, 10000, 99999]
const REALM_LIFESPAN    = [80, 200, 400, 800, 1000, 99999]
const REALM_ITEMS          = ["", "筑基丹", "金丹", "元婴珠", "化神石", ""]
const REALM_ITEMS_INFERIOR = ["", "怪味筑基丹", "怪味金丹", "怪味元婴珠", "怪味化神石", ""]
const REALM_BASE_CHANCE = [0.70, 0.55, 0.40, 0.25, 0.15]  # 各境界突破基础成功率（高境界天险递增）

const PRACTICE_MIND_GAIN = 0.25   # 历练完成 mind_max 增量（必须为 0.25 倍数避免 floor 截断异常）
const MIND_BREAKTHROUGH_DIVISOR = 15.0   # 突破时 mind_max += diff / 15

func init_with_talents(speed: int, luck: int):
	talent_speed  = speed
	talent_luck   = luck

func get_realm_name() -> String:
	return REALMS[realm]

func get_speed_multiplier() -> float:
	return 1.0 + talent_speed * 0.1

func get_luck_multiplier() -> float:
	return 1.0 + talent_luck * 0.1

func get_lifespan_pill_bonus() -> int:
	return maxi(0, 50 - lifespan_pill_used * 10)

func get_hidden_event_chance() -> float:
	if prestige <= 0:
		return 0.0
	return minf(float(prestige) / float(prestige + 100), 0.60)

func get_base_breakthrough_chance() -> float:
	var base = REALM_BASE_CHANCE[mini(realm, REALM_BASE_CHANCE.size() - 1)]
	return clampf(base + talent_luck * 0.02, 0.10, 0.95)

func get_breakthrough_chance() -> float:
	return clampf(get_base_breakthrough_chance() + breakthrough_boost, 0.10, 0.95)

# Add cultivation directly (no multiplier applied here — callers scale first).
func add_cultivation(amount: int) -> String:
	var before = cultivation
	cultivation = mini(cultivation + amount, REALM_REQUIRED[realm])
	if cultivation - before < amount:
		return "修为已达上限（" + str(REALM_REQUIRED[realm]) + "），请进入闭关界面尝试突破。"
	return ""

func pass_time(years: int) -> bool:
	lifespan -= years
	age += years
	return lifespan <= 0

# ── 心志/闭关辅助 ────────────────────────────────────────────────

func get_available_retreat_years() -> int:
	return maxi(0, int(floor(mind_max)) - mind_used)

func get_practice_years() -> int:
	return int(ceil(mind_max / 10.0))

func get_mind_display() -> String:
	return "心志：%d" % get_available_retreat_years()

# 闭关请求入口：截断契约在此完成。返回 dict 含 calculate_retreat 结果 + 截断信息。
# 调用方：game.gd RETREAT 流程
func request_retreat(years: int) -> Dictionary:
	var available = get_available_retreat_years()
	if available <= 0:
		return {
			"blocked": true,
			"truncated": false,
			"requested": years,
			"actual_years": 0,
		}
	var actual = mini(years, available)
	var result = calculate_retreat(actual)
	mind_used += actual
	result["blocked"] = false
	result["truncated"] = actual < years
	result["requested"] = years
	result["actual_years"] = actual
	return result

# 出门历练完成回调：仅 story_one EVENTS 历练事件结束时调用
func complete_practice() -> void:
	mind_used = 0
	mind_max += PRACTICE_MIND_GAIN

func add_prestige(amount: int):
	prestige += amount

func add_gold(amount: int):
	gold += amount

func add_item(item_name: String):
	items.append(item_name)

# 气运 = talent_luck；历练事件 qiyun 字段、气运丹消耗均走此入口
func add_qiyun(amount: int) -> void:
	talent_luck += amount

func has_item(item_name: String) -> bool:
	return item_name in items

func remove_item(item_name: String):
	items.erase(item_name)

func use_item(item_name: String) -> String:
	if not has_item(item_name):
		return "你没有【" + item_name + "】。"
	match item_name:
		"延寿丹":
			remove_item(item_name)
			var bonus = maxi(0, 50 - lifespan_pill_used * 10)
			lifespan_pill_used += 1
			if bonus > 0:
				lifespan += bonus
				lifespan_max = maxi(lifespan_max, lifespan)
				var note = "（第%d枚，药效递减）" % lifespan_pill_used if lifespan_pill_used > 1 else ""
				return "服下【延寿丹】，寿命+%d年。%s" % [bonus, note]
			else:
				return "服下【延寿丹】，药效已彻底耗尽，毫无作用。（已服第%d枚）" % lifespan_pill_used
		"一阶破境符", "二阶破境符", "三阶破境符", "四阶破境符", "五阶破境符":
			const FJF_NAMES = ["一阶破境符", "二阶破境符", "三阶破境符", "四阶破境符", "五阶破境符"]
			var tier = FJF_NAMES.find(item_name)
			if realm != tier:
				return "【%s】只能在%s时使用，当前境界不符。" % [item_name, REALMS[tier]]
			if breakthrough_boost > 0.0:
				return "已有破境符在起效，无法叠加，待本次突破后再用。"
			remove_item(item_name)
			breakthrough_boost = 0.20
			var eff = int(get_breakthrough_chance() * 100)
			return "展开【%s】，符文光芒没入识海。\n下次突破成功率+20%%，当前有效成功率：%d%%。\n（无论成败，符文效果一次性消耗）" % [item_name, eff]
		"一阶聚灵丹", "二阶聚灵丹", "三阶聚灵丹", "四阶聚灵丹", "五阶聚灵丹":
			const JLD_DATA = [
				{"realm": 0, "bonus": 20},
				{"realm": 1, "bonus": 160},
				{"realm": 2, "bonus": 400},
				{"realm": 3, "bonus": 1000},
				{"realm": 4, "bonus": 2000},
			]
			const JLD_NAMES = ["一阶聚灵丹", "二阶聚灵丹", "三阶聚灵丹", "四阶聚灵丹", "五阶聚灵丹"]
			var tier = JLD_NAMES.find(item_name)
			var data = JLD_DATA[tier]
			if realm != data["realm"]:
				return "【" + item_name + "】只能在" + REALMS[data["realm"]] + "时服用，当前境界不符。"
			remove_item(item_name)
			var ov = add_cultivation(data["bonus"])
			return "服下【" + item_name + "】，修为+" + str(data["bonus"]) + ("（" + ov + "）" if ov != "" else "") + "。"
		"筑基丹", "金丹", "元婴珠", "化神石":
			return "【" + item_name + "】是突破材料，突破时会自动消耗。"
		"怪味筑基丹", "怪味金丹", "怪味元婴珠", "怪味化神石":
			return "【" + item_name + "】是突破材料，突破时会自动消耗。（此物来路不正，品质有所欠缺）"
		"残缺一阶破境符", "残缺二阶破境符", "残缺三阶破境符", "残缺四阶破境符", "残缺五阶破境符":
			const BROKEN_FJF = ["残缺一阶破境符", "残缺二阶破境符", "残缺三阶破境符", "残缺四阶破境符", "残缺五阶破境符"]
			var tier = BROKEN_FJF.find(item_name)
			if realm != tier:
				return "【%s】只能在%s时使用，当前境界不符。" % [item_name, REALMS[tier]]
			if breakthrough_boost > 0.0:
				return "已有破境符在起效，无法叠加，待本次突破后再用。"
			remove_item(item_name)
			breakthrough_boost = 0.10
			var eff = int(get_breakthrough_chance() * 100)
			return "展开【%s】，符文光芒较正品暗淡，但仍没入识海。\n下次突破成功率+10%%，当前有效成功率：%d%%。\n（无论成败，符文效果一次性消耗）" % [item_name, eff]
		"青木长生诀", "金阙真经", "太上忘情诀", "紫府混元图", "九转化神录":
			const GONGFA_NAMES = ["青木长生诀", "金阙真经", "太上忘情诀", "紫府混元图", "九转化神录"]
			const GONGFA_GAIN  = [1, 2, 3, 5, 8]
			var tier = GONGFA_NAMES.find(item_name)
			var gain = GONGFA_GAIN[tier]
			remove_item(item_name)
			talent_speed += gain
			return "你参悟【%s】，识海中多出一段口诀。\n修行天赋永久 +%d（当前修炼倍率 ×%.1f）。" % [item_name, gain, get_speed_multiplier()]
		"小气运丹", "中气运丹", "大气运丹":
			const QIYUN_NAMES = ["小气运丹", "中气运丹", "大气运丹"]
			const QIYUN_GAIN  = [1, 2, 4]
			var tier = QIYUN_NAMES.find(item_name)
			var gain = QIYUN_GAIN[tier]
			remove_item(item_name)
			add_qiyun(gain)
			return "服下【%s】，体内一股玄妙气息缓缓沉入丹田。\n气运永久 +%d（当前气运 %d）。" % [item_name, gain, talent_luck]
	return "【" + item_name + "】无法直接使用。"

func calculate_retreat(years: int) -> Dictionary:
	var base         = years * 8
	var insight      = false
	var insight_val  = 0
	var danger       = false
	var danger_pen   = 0

	var insight_rate = clampf(0.10 + talent_luck * 0.02, 0.03, 0.30)

	if years >= 10 and randf() < insight_rate:
		insight    = true
		insight_val = int(50 * get_luck_multiplier())

	if years >= 30 and randf() < 0.05:
		danger    = true
		danger_pen = 20

	var cult_gain    = int((base + insight_val) * get_speed_multiplier())
	var overflow_msg = add_cultivation(cult_gain)

	pass_time(years)
	if danger:
		lifespan -= danger_pen

	return {
		"years":         years,
		"cult_gain":     cult_gain,
		"insight":       insight,
		"insight_bonus": int(insight_val * get_speed_multiplier()),
		"danger":        danger,
		"danger_penalty":danger_pen,
		"overflow_msg":  overflow_msg,
		"is_dead":       lifespan <= 0
	}

func can_try_breakthrough() -> String:
	if realm >= REALMS.size() - 1:
		return "你已飞升，无需再突破。"
	if cultivation < REALM_REQUIRED[realm]:
		return "修为尚浅，无法突破。\n（还需 " + str(REALM_REQUIRED[realm] - cultivation) + " 点修为）"
	var required_item = REALM_ITEMS[realm]
	var inferior_item = REALM_ITEMS_INFERIOR[realm]
	if required_item != "" and not has_item(required_item) and not has_item(inferior_item):
		return "突破需要【" + required_item + "】，你尚未持有此宝物。"
	return ""

func try_breakthrough(force_result: int = 0) -> Dictionary:
	# force_result: 0 = roll random, 1 = force success, -1 = force fail
	var required_item  = REALM_ITEMS[realm]
	var inferior_item  = REALM_ITEMS_INFERIOR[realm]
	var using_inferior = required_item != "" and not has_item(required_item) and has_item(inferior_item)
	var consumed_item  = inferior_item if using_inferior else required_item
	var had_boost      = breakthrough_boost > 0.0
	var chance         = get_breakthrough_chance()
	if using_inferior:
		chance = clampf(chance - 0.10, 0.10, 0.95)
	breakthrough_boost = 0.0
	var realm_from = realm
	var success: bool = (force_result == 1) or (force_result == 0 and randf() < chance)
	if success:
		if consumed_item != "":
			remove_item(consumed_item)
		var gain     = REALM_LIFESPAN[realm + 1] - REALM_LIFESPAN[realm]
		realm       += 1
		lifespan    += gain
		lifespan_max = lifespan
		cultivation  = 0
		# mind_max 突破成长：仅在非飞升时增长（飞升即终态，避免 99999/15 ≈ 6666 数值爆炸）
		if realm < REALMS.size() - 1:
			mind_max += float(gain) / MIND_BREAKTHROUGH_DIVISOR
		var insight_chance = 0.20 + talent_luck * 0.02
		var insight: Dictionary = {}
		if randf() < insight_chance:
			add_prestige(10)
			add_item("一阶聚灵丹")
			insight = {"prestige": 10, "item": "一阶聚灵丹"}
		return {
			"success": true, "realm_from": realm_from, "realm_to": realm,
			"lifespan_gain": gain, "item_consumed": consumed_item,
			"had_boost": had_boost, "insight_bonus": insight, "damage": 0,
			"used_inferior": using_inferior,
		}
	else:
		lifespan -= 15
		if consumed_item != "":
			remove_item(consumed_item)
		return {
			"success": false, "realm_from": realm_from, "realm_to": realm,
			"lifespan_gain": 0, "item_consumed": consumed_item,
			"had_boost": had_boost, "insight_bonus": {}, "damage": 15,
			"used_inferior": using_inferior,
		}

func get_detail_text() -> String:
	var item_text = "无" if items.is_empty() else "、".join(items)
	return (
		"【角色】" + player_name + "\n" +
		"【境界】" + get_realm_name() + "\n" +
		"【修为】" + str(cultivation) + " / " + str(REALM_REQUIRED[realm]) + "\n" +
		"【寿命】" + str(lifespan) + " 年\n" +
		"【年纪】" + str(age) + " 岁\n" +
		"【修行年岁】" + str(age - 20) + " 年\n" +
		"【" + get_mind_display() + "】\n" +
		"【灵石】" + str(gold) + " 枚\n" +
		"【声望】" + str(prestige) + "\n" +
		"【持有宝物】" + item_text + "\n" +
		"【突破所需】" + _get_required_item_text() + "\n" +
		"【修炼倍率】×%.1f  【气运】%d" % [get_speed_multiplier(), talent_luck]
	)

# FREE 主面板用简版 — 去 持有宝物 / 突破所需 / 修行年岁（移至宝物背包屏）
func get_free_stats_text() -> String:
	return (
		"【角色】" + player_name + "\n" +
		"【境界】" + get_realm_name() + "\n" +
		"【修为】" + str(cultivation) + " / " + str(REALM_REQUIRED[realm]) + "\n" +
		"【寿命】" + str(lifespan) + " 年\n" +
		"【年纪】" + str(age) + " 岁\n" +
		"【" + get_mind_display() + "】\n" +
		"【灵石】" + str(gold) + " 枚\n" +
		"【声望】" + str(prestige) + "\n" +
		"【修炼倍率】×%.1f  【气运】%d" % [get_speed_multiplier(), talent_luck]
	)

# 宝物背包屏用 — 聚焦 inventory + 修行年岁 + 突破所需
func get_inventory_text() -> String:
	var item_text = "无" if items.is_empty() else "、".join(items)
	return (
		"═══ 宝物背包 ═══\n\n" +
		"【修行年岁】" + str(age - 20) + " 年\n" +
		"【突破所需】" + _get_required_item_text() + "\n" +
		"【持有宝物】" + item_text + "\n"
	)

func _get_required_item_text() -> String:
	var req = REALM_ITEMS[realm]
	var inf = REALM_ITEMS_INFERIOR[realm]
	if req == "":
		return "无需宝物"
	if has_item(req):
		return req
	if inf != "" and has_item(inf):
		return inf + "（将自动使用）"
	if inf != "":
		return req + "（或" + inf + "）"
	return req

func get_stats_text() -> String:
	return "【%s】修为：%d/%d  寿命：%d年  灵石：%d枚" % [
		get_realm_name(), cultivation, REALM_REQUIRED[realm], lifespan, gold
	]
