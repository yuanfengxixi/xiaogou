# minigame_logic.gd
# Logic reasoning mini-game — text question + multiple choice.
# One correct answer per question; wrong answer = immediate fail.
# Multi-round mode: all rounds must pass for "pass" result.
#
# Usage:
#   var mg := MinigameLogic.new()
#   mg.configure({"pool": "medium", "rounds": 2, "narrative": "..."})
#   mg.minigame_completed.connect(_on_result)
#   choices_box.add_child(mg)
#
# Result values: "pass" | "fail"

class_name MinigameLogic
extends VBoxContainer

signal minigame_completed(result: String)

# ── Config ────────────────────────────────────────────────────────
var cfg_narrative: String = ""
var cfg_pool:      String = "easy"   # "easy" | "medium" | "hard"
var cfg_rounds:    int    = 1

# ── Runtime ───────────────────────────────────────────────────────
var _round:       int   = 0
var _used_idx:    Array = []  # indices already shown this game

# ── UI refs ───────────────────────────────────────────────────────
var _header_lbl:  Label
var _round_lbl:   Label
var _question_lbl: Label

# ── Question pool ─────────────────────────────────────────────────

const POOL: Dictionary = {
	"easy": [
		{
			"question": "A、B、C三人，每人是骑士（永远真）或无赖（永远假）。\nA说：「我们三人都是无赖。」\n\n仅根据以上信息，能确定哪些人的身份？",
			"options": ["A是无赖，B/C身份无法判断", "A是骑士，B/C无法确定", "三人都是无赖", "A是无赖，B/C也是无赖"],
			"answer": 0,
		},
		{
			"question": "A、B、C、D各拿一个数字（1、2、3、4，每人不同）。\n①A拿的数比B大 ②C拿的数比D小 ③B拿的数比C小\n\n从大到小排序是？",
			"options": ["D(4) > A(3) > C(2) > B(1)", "A(4) > D(3) > C(2) > B(1)", "A > B > C > D", "D > C > A > B"],
			"answer": 0,
		},
		{
			"question": "房间里有3盏白炽灯，门外3个开关各控一盏，对应关系未知，只能进房间一次。\n策略：开关1开几分钟后关掉；开关2保持开着；开关3不动，进入房间观察灯的亮灭和灯泡温度。\n\n这个策略能成功确定全部对应关系吗？",
			"options": ["能，亮灯=开关2，热灯=开关1，冷灯=开关3", "不能，只能区分亮/灭两种状态", "能，但需要进入两次", "不能，余热不可靠"],
			"answer": 0,
		},
		{
			"question": "A、B两人，一个是骑士，一个是无赖。\nA说：「我们两人中，至少有一个是无赖。」\n\nA是骑士还是无赖？",
			"options": ["骑士", "无赖", "无法确定", "两者都有可能"],
			"answer": 0,
		},
		{
			"question": "五人A、B、C、D、E排成一排拍照。\n①A不站最左或最右 ②B紧靠A左边（相邻）③D站最右 ④C和E不相邻 ⑤E站最左\n\n从左到右顺序是？",
			"options": ["E / B / A / C / D", "E / A / B / C / D", "B / E / A / C / D", "E / B / C / A / D"],
			"answer": 0,
		},
		{
			"question": "三个盒子标着「苹果」「橙子」「苹果和橙子」，但三个标签全部贴错了。只能从一个盒子摸出一个水果（不能看）。\n\n摸哪个盒子，才能仅凭这一个水果确定所有盒子内容？",
			"options": ["标着「苹果和橙子」的盒子", "标着「苹果」的盒子", "标着「橙子」的盒子", "哪个都一样"],
			"answer": 0,
		},
		{
			"question": "A、B、C、D四人预测明天是否下雨：\nA说「会」，B说「不会」，C说「A说的对」，D说「我同意C」。\n结果只有一人预测正确。\n\n谁预测正确了？",
			"options": ["B", "A", "C", "D"],
			"answer": 0,
		},
		{
			"question": "五支球队单循环赛（每两队各一场），胜得2分，负得0分，平各得1分。总分20分。\n最终：A=7，B=5，C=4，D=3，E=1。\n\nE的四场比赛结果是？",
			"options": ["0胜1平3负", "0胜0平4负", "1胜0平3负", "0胜2平2负"],
			"answer": 0,
		},
		{
			"question": "A说：「B是无赖。」\nB说：「A和C是同一种人（同为骑士或同为无赖）。」\n（骑士永远真，无赖永远假）\n\nC是什么人？",
			"options": ["无赖", "骑士", "无法确定", "骑士或无赖皆有可能"],
			"answer": 0,
		},
		{
			"question": "7个外观相同的球，6个等重，1个稍轻。只有一架天平（无砝码）。\n\n无论结果如何，最少称几次才能保证一定找出轻球？",
			"options": ["2次", "3次", "1次", "4次"],
			"answer": 0,
		},
	],
	"medium": [
		{
			"question": "修仙者甲从东城出发，向北走三里，再向东走四里。距出发点多远？",
			"options": ["5 里", "7 里", "6 里", "4 里"],
			"answer": 0,
		},
		{
			"question": "五大宗门，每两门之间恰好有一名间谍。共有几名间谍？",
			"options": ["10 名", "5 名", "20 名", "15 名"],
			"answer": 0,
		},
		{
			"question": "甲、乙修炼效率之比为 3:2。甲 10 年筑基，乙需多少年？",
			"options": ["15 年", "20 年", "12 年", "30 年"],
			"answer": 0,
		},
		{
			"question": "「所有正道弟子守戒律，李云是正道弟子。」则以下哪项必然正确？",
			"options": ["李云守戒律", "李云可能不守戒律", "正道弟子都像李云", "无法判断"],
			"answer": 0,
		},
		{
			"question": "一袋灵石分给三人，甲得二分之一，乙得三分之一，丙得剩余。丙得几分之几？",
			"options": ["六分之一", "四分之一", "五分之一", "三分之一"],
			"answer": 0,
		},
		{
			"question": "A、B、C三人：骑士永远说真话，无赖永远说假话，间谍有时真有时假。\nA说：「C是无赖。」\nB说：「A是骑士。」\nC说：「我是间谍。」\n\n谁是骑士、谁是无赖、谁是间谍？",
			"options": ["A骑士 / B间谍 / C无赖", "A骑士 / B无赖 / C间谍", "B骑士 / A间谍 / C无赖", "C骑士 / A无赖 / B间谍"],
			"answer": 0,
		},
		{
			"question": "A、B、C、D四人比赛，名次各不同（第1到第4名）。\n①A不是第一名 ②B比C靠前 ③D不是最后 ④C不是第二名 ⑤A比D靠前\n\n从前到后完整名次是？",
			"options": ["B > A > D > C", "A > B > D > C", "B > D > A > C", "B > A > C > D"],
			"answer": 0,
		},
		{
			"question": "四人夜间过独木桥，桥最多承重2人，只有一支火把。各人所需时间：A=1分，B=2分，C=5分，D=10分，同行以慢者为准。\n\n所有人过桥最少需要多少分钟？",
			"options": ["17 分钟", "20 分钟", "15 分钟", "19 分钟"],
			"answer": 0,
		},
		{
			"question": "Anna、Ben、Chris、Diana分住2/4/6/8楼，各养猫/狗/鸟/鱼。\n①Anna楼层比Ben高 ②养狗者住6楼 ③Chris住最低楼层 ④Diana不养鱼 ⑤Ben养鸟 ⑥Anna住8楼以下\n\nChris住哪层、养什么宠物？",
			"options": ["2楼，鱼", "2楼，猫", "4楼，鸟", "2楼，狗"],
			"answer": 0,
		},
		{
			"question": "岛上只有两种人：永远说真话（诚实者）或永远说假话（说谎者）。\nX说：「我们三人中至少有一个是诚实者。」\nY说：「我们三人中至少有一个是说谎者。」\nZ什么都没说。\n\nX和Y各是什么人？",
			"options": ["X诚实者，Y诚实者", "X说谎者，Y诚实者", "X诚实者，Y说谎者", "X说谎者，Y说谎者"],
			"answer": 0,
		},
		{
			"question": "三人A（后）B（中）C（前）坐成一排，从3白2黑帽中各戴一顶。\nA被问：「知道自己帽子颜色？」→「不知道。」\nB被问：→「不知道。」\nC被问：→「知道！」\n\nC戴的是什么颜色？",
			"options": ["白帽", "黑帽", "无法确定", "白帽或黑帽皆有可能"],
			"answer": 0,
		},
	],
	"hard": [
		{
			"question": "甲说乙在撒谎，乙说丙在撒谎，丙说甲乙都在撒谎。只有一人说真话，是谁？",
			"options": ["乙", "甲", "丙", "无法判断"],
			"answer": 0,
		},
		{
			"question": "一修仙界共 7 人，每人恰好认识其中 4 人（认识是相互的）。共有多少对相互认识的人？",
			"options": ["14 对", "21 对", "28 对", "7 对"],
			"answer": 0,
		},
		{
			"question": "练气→筑基需修为 100，筑基→金丹需 300，金丹→元婴需 900。三段比值规律，元婴→化神需多少？",
			"options": ["2700", "1800", "3600", "1200"],
			"answer": 0,
		},
		{
			"question": "若「无功法则无突破」为真，「有突破」已知，则以下哪项必然为真？",
			"options": ["有功法", "无功法", "可能有也可能没有功法", "功法是充分条件"],
			"answer": 0,
		},
		{
			"question": "甲乙丙三人分别说：甲「我是散修」；乙「甲是宗门弟子」；丙「乙在撒谎」。恰好一人说谎，说谎者是？",
			"options": ["乙", "甲", "丙", "无法确定"],
			"answer": 0,
		},
	],
	"advanced": [
		{
			"question": "五栋房子（红/蓝/绿/黄/白），每户国籍/饮料/宠物/香烟各不同。\n线索：①英→红房 ②瑞典→狗 ③丹麦→茶 ④绿房紧靠白房左边 ⑤绿→咖啡 ⑥PallMall→鸟 ⑦黄→Dunhill ⑧中间位置→牛奶 ⑨挪威→位置1 ⑩Blend→养猫者旁 ⑪养马→Dunhill旁 ⑫BlueMaster→啤酒 ⑬德国→Prince ⑭挪威→蓝房旁 ⑮Blend→有喝水邻居\n\n推断：谁养了鱼？",
			"options": ["挪威人", "丹麦人", "英国人", "德国人", "瑞典人"],
			"answer": 3,
		},
		{
			"question": "A、B、C、D、E五人参加考试，成绩各不相同。\n①A的成绩不是最高也不是最低 ②B比C高，比D低 ③E不是最低分 ④C不是最低分\n\n从高到低完整排名是？",
			"options": ["D > B > A > C > E", "D > A > B > C > E", "B > D > A > C > E", "D > B > C > A > E"],
			"answer": 0,
		},
		{
			"question": "岛上五人A/B/C/D/E，每人是骑士（永远真）或无赖（永远假）。\nA说：「我们五人中恰好有两个骑士。」\nB说：「我们五人中恰好有三个骑士。」\nC说：「A和B中，至少有一个骑士。」\nD说：「C是骑士。」\nE说：「我们五人中没有骑士。」\n\n谁是骑士？",
			"options": ["B、C、D是骑士，A、E是无赖", "A、C、D是骑士，B、E是无赖", "A、B、C是骑士，D、E是无赖", "C、D、E是骑士，A、B是无赖"],
			"answer": 0,
		},
		{
			"question": "骑士永远说真话，无赖永远说假话。陌生人问A「你是骑士还是无赖？」，A回答了但声音太小没听清。\nB说：「A说他是无赖。」\nC说：「别信B，他在撒谎！」\n\nB和C各是什么人？A的身份能否确定？",
			"options": ["B无赖 / C骑士，A无法确定", "B骑士 / C无赖，A无法确定", "B无赖 / C骑士，A是骑士", "B无赖 / C骑士，A是无赖"],
			"answer": 0,
		},
		{
			"question": "100名囚犯关在独立牢房，有一公共房间内一盏灯（初始关）。每天随机一名囚犯进入，可开/关/不动灯后离开。开始前可开一次会，之后不能通信。某囚犯确认所有人都进过房间时可宣告获释；判断错误则全部处死。\n\n最有效的核心策略是？",
			"options": [
				"指定一名计数官：其余人第一次见灯关时开灯（仅一次），计数官见灯开则关灯并计数，数到99即宣告",
				"最先进房间的人记录次数，数到100时宣告",
				"约定进入房间时轮流开关灯，循环100次后宣告",
				"每人进入时若灯关就开灯，由任意一人计数100次后宣告",
			],
			"answer": 0,
		},
	],
}

# ── Setup ─────────────────────────────────────────────────────────

func configure(d: Dictionary) -> void:
	if d.has("narrative"): cfg_narrative = d["narrative"]
	if d.has("pool"):      cfg_pool      = d["pool"]
	if d.has("rounds"):    cfg_rounds    = d["rounds"]

func _ready() -> void:
	add_theme_constant_override("separation", 14)

	if cfg_narrative != "":
		_header_lbl = Label.new()
		_header_lbl.text = cfg_narrative
		_header_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		_header_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		add_child(_header_lbl)

	if cfg_rounds > 1:
		_round_lbl = Label.new()
		_round_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		add_child(_round_lbl)

	add_child(HSeparator.new())

	_question_lbl = Label.new()
	_question_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_question_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	add_child(_question_lbl)

	_show_question()

# ── Question display ──────────────────────────────────────────────

func _show_question() -> void:
	# Remove old option buttons (everything after _question_lbl)
	var q_idx := _question_lbl.get_index()
	var children := get_children()
	for i in range(children.size() - 1, q_idx, -1):
		children[i].queue_free()

	if _round_lbl:
		_round_lbl.text = "第 %d / %d 题" % [_round + 1, cfg_rounds]

	var q := _pick_question()
	_question_lbl.text = q["question"]

	for i in range(q["options"].size()):
		var btn := Button.new()
		btn.text = q["options"][i]
		btn.custom_minimum_size = Vector2(0, UITheme.BTN_H)
		btn.add_theme_font_size_override("font_size", UITheme.FONT_BTN)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.pressed.connect(_on_option.bind(i, q["answer"]))
		add_child(btn)

func _pick_question() -> Dictionary:
	var pool: Array = POOL.get(cfg_pool, POOL["easy"])
	# Build list of unused indices
	var available: Array = []
	for i in range(pool.size()):
		if i not in _used_idx:
			available.append(i)
	# If exhausted, reset
	if available.is_empty():
		_used_idx.clear()
		available = range(pool.size())
	var chosen_idx: int = available[randi() % available.size()]
	_used_idx.append(chosen_idx)
	return pool[chosen_idx]

# ── Answer handling ───────────────────────────────────────────────

func _on_option(chosen: int, correct: int) -> void:
	_disable_all_buttons()

	if chosen != correct:
		minigame_completed.emit("fail")
		return

	_round += 1
	if _round >= cfg_rounds:
		minigame_completed.emit("pass")
	else:
		await get_tree().create_timer(0.3).timeout
		_show_question()

func _disable_all_buttons() -> void:
	for child in get_children():
		if child is Button:
			child.disabled = true
