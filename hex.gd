extends Node

# ══════════════════════════════════════════════════════════════
#  海克斯（仿《金铲铲之战》强化机制）
#  · 触发时机：开局（拜入宗门或选择散修后）/ 突破成功后（非飞升）
#  · 三档：彩 30% / 金 35% / 银 35%；每次抽 1 档 3 个不重复选项，无刷新
#  · 类别：灵石 / 修为 / 天赋 / 气运 / 宝物
#  · 数值不引入持续性效果；天赋/气运沿用功法 / 气运丹"一次性消耗永久属性"先例
# ══════════════════════════════════════════════════════════════

const TIERS = ["caihex", "jin", "yin"]
const TIER_LABELS = {"caihex": "彩", "jin": "金", "yin": "银"}
# 抽档累计权重：彩 [0,30) / 金 [30,65) / 银 [65,100)
const TIER_CUTOFF_CAIHEX = 30
const TIER_CUTOFF_JIN = 65

const JLD_NAMES = ["一阶聚灵丹", "二阶聚灵丹", "三阶聚灵丹", "四阶聚灵丹", "五阶聚灵丹"]
const PJF_NAMES = ["一阶破境符", "二阶破境符", "三阶破境符", "四阶破境符", "五阶破境符"]

# 海克斯池 — 每档 10 个
const POOL: Dictionary = {
	"yin": [
		{"id": "S01", "name": "集市余资", "category": "灵石", "blurb": "市集小贩塞来一囊碎银，叮当作响。", "effects": [{"type": "gold", "value": 40}]},
		{"id": "S02", "name": "锦囊薄银", "category": "灵石", "blurb": "路遇老者临别赠囊，内中银钱足够添置几样杂物。", "effects": [{"type": "gold", "value": 80}]},
		{"id": "S03", "name": "经脉小通", "category": "修为", "blurb": "盘膝静坐片刻，气息绕过一处旧塞。", "effects": [{"type": "cult_pct", "value": 10}]},
		{"id": "S04", "name": "灵气微浸", "category": "修为", "blurb": "夜半灵气自袖口渗入丹田，温润绵长。", "effects": [{"type": "cult_pct", "value": 20}]},
		{"id": "S05", "name": "入门感悟", "category": "天赋", "blurb": "翻阅杂记时悟得一缕吐纳口诀。", "effects": [{"type": "talent_speed", "value": 1}]},
		{"id": "S06", "name": "凡尘一念", "category": "天赋", "blurb": "山野偶遇道人留偈，心中福缘悄然萌发。", "effects": [{"type": "talent_luck", "value": 1}]},
		{"id": "S07", "name": "神龛香火", "category": "气运", "blurb": "破庙神龛上一柱香火尚温，叩拜而退。", "effects": [{"type": "qiyun", "value": 1}]},
		{"id": "S08", "name": "卦象初吉", "category": "气运", "blurb": "街边算命摊掷出「上吉」卦象，老瞎子免单送行。", "effects": [{"type": "qiyun", "value": 2}]},
		{"id": "S09", "name": "杂货摊礼", "category": "宝物", "blurb": "杂货摊主见你眼缘合，硬塞来一粒小气运丹。", "effects": [{"type": "item", "value": "小气运丹"}]},
		{"id": "S10", "name": "山野遗符", "category": "宝物", "blurb": "山道旁拾得一枚遗落丹丸，恰合当前境界。", "effects": [{"type": "item_realm_juling", "value": ""}]},
	],
	"jin": [
		{"id": "G01", "name": "商队厚酬", "category": "灵石", "blurb": "护送商队过险地，掌柜慷慨给钱。", "effects": [{"type": "gold", "value": 100}]},
		{"id": "G02", "name": "富商赏赐", "category": "灵石", "blurb": "城中富商感你出手相助，奉上谢礼。", "effects": [{"type": "gold", "value": 180}]},
		{"id": "G03", "name": "灵田丰收", "category": "修为", "blurb": "途经灵田，借田中一缕浓郁灵气调息。", "effects": [{"type": "cult_pct", "value": 25}]},
		{"id": "G04", "name": "灵脉小补", "category": "修为", "blurb": "误入地脉支流，灵气如细泉灌注丹田。", "effects": [{"type": "cult_pct", "value": 35}]},
		{"id": "G05", "name": "顿悟一瞬", "category": "天赋", "blurb": "树下打坐时心神一明，修行之径骤然清晰。", "effects": [{"type": "talent_speed", "value": 2}]},
		{"id": "G06", "name": "福星临顶", "category": "天赋", "blurb": "夜观天象，一颗福星正落己宿。", "effects": [{"type": "talent_luck", "value": 2}]},
		{"id": "G07", "name": "紫气东来", "category": "气运", "blurb": "清晨紫气漫至窗前，心头一阵畅快。", "effects": [{"type": "qiyun", "value": 3}]},
		{"id": "G08", "name": "玄龟献兆", "category": "气运", "blurb": "溪畔遇到一只千年玄龟，背甲纹路恰对己身。", "effects": [{"type": "qiyun", "value": 4}]},
		{"id": "G09", "name": "名师赠经", "category": "宝物", "blurb": "山中老道授你一卷青木长生诀，命你自悟。", "effects": [{"type": "item", "value": "青木长生诀"}]},
		{"id": "G10", "name": "真人指点", "category": "宝物", "blurb": "云游真人慨然赠一枚中气运丹，转身离去。", "effects": [{"type": "item", "value": "中气运丹"}]},
	],
	"caihex": [
		{"id": "P01", "name": "灵石矿脉", "category": "灵石", "blurb": "无意撞入废弃矿洞，矿脉一角灵石密布。", "effects": [{"type": "gold", "value": 500}]},
		{"id": "P02", "name": "天降横财", "category": "灵石", "blurb": "悬崖下捡得前辈遗囊，灵石堆积如山。", "effects": [{"type": "gold", "value": 800}]},
		{"id": "P03", "name": "玄黄灵气", "category": "修为", "blurb": "玄黄之气自天心倾泻而下，本境界灵机骤然圆满。", "effects": [{"type": "cult_pct", "value": 40}]},
		{"id": "P04", "name": "道韵临身", "category": "修为", "blurb": "夜半天道之音回响识海，修为与悟性同时精进。", "effects": [{"type": "cult_pct", "value": 30}, {"type": "talent_speed", "value": 1}]},
		{"id": "P05", "name": "道心圆融", "category": "天赋", "blurb": "云端俯瞰众生，道心一片澄澈，修行天赋大涨。", "effects": [{"type": "talent_speed", "value": 5}]},
		{"id": "P06", "name": "天命所钟", "category": "天赋", "blurb": "天道垂青，福缘汹涌灌顶。", "effects": [{"type": "talent_luck", "value": 5}]},
		{"id": "P07", "name": "紫薇高照", "category": "气运", "blurb": "紫薇主星骤然下移，照彻己身。", "effects": [{"type": "qiyun", "value": 8}]},
		{"id": "P08", "name": "天道垂青", "category": "气运", "blurb": "天道运转中拨出一线生机送入识海。", "effects": [{"type": "qiyun", "value": 12}]},
		{"id": "P09", "name": "真传秘籍", "category": "宝物", "blurb": "古洞深处得太上忘情诀一卷，封皮尚带温度。", "effects": [{"type": "item", "value": "太上忘情诀"}]},
		{"id": "P10", "name": "道祖余泽", "category": "宝物", "blurb": "道祖坐化之处余泽尚存，留下大气运丹与延寿丹各一。", "effects": [{"type": "item", "value": "大气运丹"}, {"type": "item", "value": "延寿丹"}]},
	],
}

# ── 抽档（彩 30% / 金 35% / 银 35%）─────────────────────────────
func draw_tier() -> String:
	var r: int = randi() % 100
	if r < TIER_CUTOFF_CAIHEX:
		return "caihex"
	elif r < TIER_CUTOFF_JIN:
		return "jin"
	return "yin"

# 从指定档抽 3 个不重复且适用于当前 player 的海克斯
func draw_options(tier: String, player) -> Array:
	var pool: Array = POOL[tier].duplicate()
	var applicable: Array = []
	for h in pool:
		if is_applicable(h, player):
			applicable.append(h)
	applicable.shuffle()
	return applicable.slice(0, mini(3, applicable.size()))

# 检查海克斯是否在当前境界可应用（境界专属宝物需校验）
func is_applicable(hex: Dictionary, player) -> bool:
	if player.realm >= player.REALMS.size() - 1:
		return false  # 飞升不再抽海克斯，保险起见
	for e in hex["effects"]:
		match e["type"]:
			"item_realm_juling", "item_realm_pojing":
				if player.realm < 0 or player.realm >= JLD_NAMES.size():
					return false
	return true

# 应用海克斯效果，返回结果文本数组（每条一行）
# items_node 可为 null（测试用）；非 null 时调用 on_item_collected 用于宝物图鉴解锁
func apply(hex: Dictionary, player, items_node) -> Array:
	var msgs: Array = []
	for e in hex["effects"]:
		match e["type"]:
			"gold":
				player.add_gold(int(e["value"]))
				msgs.append("灵石 +%d（当前 %d 枚）" % [int(e["value"]), player.gold])
			"cult_pct":
				var cap: int = int(player.REALM_REQUIRED[player.realm])
				var amt: int = int(cap * int(e["value"]) / 100.0)
				var ov: String = player.add_cultivation(amt)
				var note: String = "（" + ov + "）" if ov != "" else ""
				msgs.append("修为 +%d（本境界 %d%%）%s" % [amt, int(e["value"]), note])
			"talent_speed":
				player.talent_speed += int(e["value"])
				msgs.append("修行天赋 +%d（当前修炼倍率 ×%.1f）" % [int(e["value"]), player.get_speed_multiplier()])
			"talent_luck":
				player.talent_luck += int(e["value"])
				msgs.append("气运 +%d（当前气运 %d）" % [int(e["value"]), player.talent_luck])
			"qiyun":
				player.add_qiyun(int(e["value"]))
				msgs.append("气运 +%d（当前气运 %d）" % [int(e["value"]), player.talent_luck])
			"item":
				var item_name: String = e["value"]
				player.add_item(item_name)
				if items_node != null:
					items_node.on_item_collected(item_name)
				msgs.append("获得【%s】" % item_name)
			"item_realm_juling":
				var jname: String = JLD_NAMES[player.realm]
				player.add_item(jname)
				if items_node != null:
					items_node.on_item_collected(jname)
				msgs.append("获得【%s】" % jname)
			"item_realm_pojing":
				var pname: String = PJF_NAMES[player.realm]
				player.add_item(pname)
				if items_node != null:
					items_node.on_item_collected(pname)
				msgs.append("获得【%s】" % pname)
			_:
				push_warning("hex.apply: unknown effect type '%s' on hex %s" % [e["type"], hex.get("id", "?")])
	# 记录已抽中海克斯
	if not hex["id"] in player.hex_log:
		player.hex_log.append(hex["id"])
	return msgs
