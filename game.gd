extends Node

enum State {NAME_INPUT, TALENT_ALLOCATE, FACTION_SELECT, FREE, RETREAT_SELECT, STORY, RESULT,
			TASK_LIST, TASK_STORY, TASK_RESULT, STATUS, MARKET, GAMEOVER,
			REINCARNATION_CHOICE, ASCENSION,
			HIDDEN_STORY, HIDDEN_RESULT,
			BREAKTHROUGH_VISION, BREAKTHROUGH_RESULT, BREAKTHROUGH_REACTION,
			EXAM_INTRO, EXAM_Q, EXAM_MINIGAME, EXAM_LOGIC, EXAM_RESULT,
			EXAM_STOPLINE,
			EXAM_GATE_INTRO, EXAM_GATE_Q, EXAM_GATE_ANS,
			EXAM_CAOMEN,
			HEX_DRAW, HEX_RESULT,
			CHRONICLE}
var current_state = State.NAME_INPUT

var player
var story
var task
var talent
var items_node
var reincarnation
var hex
var story_label
var stats_label
var choices_box
var main_root
var overlay_root

var current_story_data = null
var _name_input: LineEdit = null
var _retreat_years: int = 10   # 自定义闭关年数
var _breakthrough_data: Dictionary = {}
var _popup_queue: Array = []
var _practice_active: bool = false   # 出门历练流程标志：当前 STORY 事件结束后调 complete_practice
var _last_retreat_truncated: bool = false   # 上次闭关是否被心志截断（用于结果屏显示）
var _last_retreat_actual: int = 0           # 上次闭关实际年数（截断时显示）
var _last_retreat_requested: int = 0        # 上次闭关请求年数（截断时显示）

# ── 隐藏事件多步骤状态（multi-step-events.md v2.0）───────────────
var _hidden_event: Dictionary = {}
var _hidden_round_id: String = ""
var _hidden_minigame_node: Node = null
var _hidden_minigame_cfg: Dictionary = {}

# ── 宗门考核状态 ──────────────────────────────────────────────
var _exam_faction: String = ""
var _exam_intro_text: String = ""
var _exam_q_data: Array = []
var _exam_threshold: int = 2
var _exam_post_q_fn: Callable
var _exam_score: int = 0
var _exam_q_index: int = 0
var _exam_wave: float = 50.0
var _exam_stable_time: float = 0.0
var _exam_elapsed: float = 0.0
var _exam_bar: ProgressBar = null
var _exam_status_lbl: Label = null
var _exam_time_lbl: Label = null
var _exam_logic_node: MinigameLogic = null
var _exam_stopline_node: MinigameStopline = null
var _exam_logic_pool: String = "easy"
var _exam_stopline_preset: String = ""
var _caomen_elapsed: float = 0.0
var _failed_factions: Array = []
# ── 三道门谜题 ────────────────────────────────────────────────
var _gate_round: int = 0
var _gate_q_chosen: int = -1

# ── 宝物集市商品 ──────────────────────────────────────────────
const BREAKTHROUGH_VISION_TEXT = [
	"灵气自四面八方涌入识海，经脉如焚。你强咬牙关，将狂暴气流压入丹田——",
	"丹田中一团灵液翻涌不休，忽聚忽散，凝丹关头已至。",
	"金丹裂开一道缝隙，一缕婴影若隐若现。此刻走神，便是魂飞魄散。",
	"神念脱壳三寸，天地灵韵扑面。稍一松懈，神识便被天道吞去。",
]

const MARKET_ITEMS = [
	{"name": "延寿丹",    "price": 300,  "desc": "服后寿命+50年（每次递减10年，第6枚起无效）"},
	{"name": "一阶破境符","price": 500,  "desc": "练气期专用，下次突破成功率+20%，一次性消耗"},
	{"name": "二阶破境符","price": 1000, "desc": "筑基期专用，下次突破成功率+20%，一次性消耗"},
	{"name": "三阶破境符","price": 1800, "desc": "金丹期专用，下次突破成功率+20%，一次性消耗"},
	{"name": "四阶破境符","price": 3000, "desc": "元婴期专用，下次突破成功率+20%，一次性消耗"},
	{"name": "五阶破境符","price": 4500, "desc": "化神期专用，下次突破成功率+20%，一次性消耗"},
	{"name": "一阶聚灵丹","price": 200,  "desc": "练气期专用，修为+20"},
	{"name": "二阶聚灵丹","price": 500,  "desc": "筑基期专用，修为+160"},
	{"name": "三阶聚灵丹","price": 1000, "desc": "金丹期专用，修为+400"},
	{"name": "四阶聚灵丹","price": 2000, "desc": "元婴期专用，修为+1000"},
	{"name": "五阶聚灵丹","price": 4000, "desc": "化神期专用，修为+2000"},
	{"name": "筑基丹",    "price": 500,  "desc": "筑基期突破材料"},
	{"name": "金丹",      "price": 1200, "desc": "金丹期突破材料"},
	{"name": "元婴珠",    "price": 2500, "desc": "元婴期突破材料"},
	{"name": "化神石",    "price": 5000, "desc": "化神期突破材料"},
]

const SHOUYI_QUESTIONS: Array = [
	{
		"text": "修炼进入瓶颈，已停滞三年。师兄建议你转修别的法门。你：",
		"options": [
			{"text": "拒绝，继续在原有道路上磨砺。", "score": 2},
			{"text": "多打听几位前辈的意见，再做决定。", "score": 1},
			{"text": "尝试师兄推荐的新法门，也许确实更适合。", "score": 0},
			{"text": "对修仙渐渐失去信心，修炼频率大为降低。", "score": -1},
		]
	},
	{
		"text": "宗门罚你抄写千遍典籍，原因是一次小小失误。你：",
		"options": [
			{"text": "一笔一划抄完，一字不漏，不抱怨。", "score": 2},
			{"text": "抄了七百遍，实在撑不住，向师傅请求宽免。", "score": 1},
			{"text": "前五百遍认真，后五百遍随意应付了事。", "score": 0},
			{"text": "只抄了开头，准备以后找机会糊弄过去。", "score": -1},
		]
	},
	{
		"text": "受了内伤，大夫说需要静养两年不能修炼。你：",
		"options": [
			{"text": "严格遵医嘱，耐心等待两年。", "score": 2},
			{"text": "静养了一年，感觉好些便恢复了修炼。", "score": 1},
			{"text": "休养了三个月便重新修炼，不告诉大夫。", "score": 0},
			{"text": "听都没听进去，第二天就继续修炼。", "score": -1},
		]
	},
	{
		"text": "被安排在边境哨站独立驻守半年，枯燥无聊，几乎无人经过。你：",
		"options": [
			{"text": "老老实实驻守，每天按时巡逻，从不缺岗。", "score": 2},
			{"text": "驻守了四个月，后面悄悄缩短了每日巡逻时间。", "score": 1},
			{"text": "时常打瞌睡，专心巡逻不超过一半时间。", "score": 0},
			{"text": "驻守了两个月便借故回宗门，没有完成任务。", "score": -1},
		]
	},
	{
		"text": "三十年修行，始终未能踏入下一境界。同龄师兄大半已超越你。你：",
		"options": [
			{"text": "接受自身进度，继续修炼，相信功到自然成。", "score": 2},
			{"text": "开始寻找捷径——灵丹、奇遇，能快则快。", "score": 1},
			{"text": "修炼热情大降，主要靠接任务维持生计。", "score": 0},
			{"text": "心灰意冷，开始怀疑修仙是否适合自己。", "score": -1},
		]
	},
]

const XIULUO_QUESTIONS: Array = [
	{
		"text": "与人争夺一颗珍贵灵药，对方已被你击伤倒地，灵药在他手边。你：",
		"options": [
			{"text": "直接取走灵药，对方若挣扎便再补一击。", "score": 2},
			{"text": "取走灵药，趁他清醒时告知缘由。", "score": 1},
			{"text": "只取一半，留一半给他。", "score": 0},
			{"text": "放弃灵药，不愿对倒地之人动手。", "score": -1},
		]
	},
	{
		"text": "宗门交代除掉一个告密者，此人已跪地求饶，声称有妻儿老小。你：",
		"options": [
			{"text": "任务就是任务，手起刀落。", "score": 2},
			{"text": "完成任务，但尽量让他死得痛快。", "score": 1},
			{"text": "向宗门谎报已完成，实际将其放走。", "score": 0},
			{"text": "据实禀报，拒绝执行此类命令。", "score": -1},
		]
	},
	{
		"text": "独行途中发现一名落单的敌对势力弟子，对方尚未发现你。你：",
		"options": [
			{"text": "借此机会将对方解决，少一个潜在威胁。", "score": 2},
			{"text": "试探性接触，若对方态度不善则动手。", "score": 1},
			{"text": "默默绕道离开，不招惹不必要的麻烦。", "score": 0},
			{"text": "主动现身表示无意冲突，各走各路。", "score": -1},
		]
	},
	{
		"text": "有人当众侮辱了你，但对方修为比你高一个大境界。你：",
		"options": [
			{"text": "忍住当场，暗中搜集弱点，日后必报，不惜代价。", "score": 2},
			{"text": "当场还嘴，虽吃了亏，也出了口气。", "score": 1},
			{"text": "选择忍让，避免冲突，毕竟实力不如。", "score": 0},
			{"text": "向宗门或前辈申诉，寻求公道。", "score": -1},
		]
	},
	{
		"text": "此次任务可单独完成也可合作完成，报酬平分。若独吞，需先除掉合作者。你：",
		"options": [
			{"text": "找准时机除掉对方，独吞全部报酬。", "score": 2},
			{"text": "任务完成后以各种理由压低对方的份额。", "score": 1},
			{"text": "平分报酬，合作完成任务。", "score": 0},
			{"text": "放弃此任务，不愿因利益伤及无辜。", "score": -1},
		]
	},
]

const YANGTIAN_QUESTIONS: Array = [
	{
		"text": "有一门秘法，修炼速度可提升三倍，但会损耗容颜，三十年后面如老朽。你：",
		"options": [
			{"text": "毫不犹豫修炼，容颜算什么，修为才是一切。", "score": 2},
			{"text": "研究一番，若副作用可弥补则修炼。", "score": 1},
			{"text": "放弃，修为固然重要，但不愿以容颜换。", "score": 0},
			{"text": "断然拒绝，损耗身体的法门碰都不碰。", "score": -1},
		]
	},
	{
		"text": "一位好友邀你共游名山，需离开修炼三个月。此时你正处于修炼的关键期。你：",
		"options": [
			{"text": "拒绝，关键期不能中断，修为不等人。", "score": 2},
			{"text": "去了一个月，早早返回继续修炼。", "score": 1},
			{"text": "陪好友去了，心里惦记修炼，无心游玩。", "score": 0},
			{"text": "欣然应允，修炼之余人情往来同样重要。", "score": -1},
		]
	},
	{
		"text": "得到一颗能延寿五十年但只够一人服下的灵丹，你的挚友与你同时需要。你：",
		"options": [
			{"text": "自己服下，延寿才能让你修炼更久。", "score": 2},
			{"text": "设法用此丹换取两份较小的延寿药。", "score": 1},
			{"text": "让给挚友，你另寻机缘。", "score": 0},
			{"text": "两人共分，各延二十五年。", "score": -1},
		]
	},
	{
		"text": "长老说：正统道路三百年望化神；旁门左道一百年可至，但此后再无寸进。你：",
		"options": [
			{"text": "选正统道路，修仙求的是无上境界，不能止步于此。", "score": 2},
			{"text": "先走旁门至化神，再寻正途突破。", "score": 1},
			{"text": "选旁门，一百年化神已然知足。", "score": 0},
			{"text": "请长老指点，听从建议。", "score": -1},
		]
	},
	{
		"text": "一位宗门耆老问你：「你修仙的最终目的是什么？」你回答：",
		"options": [
			{"text": "「长生不老，突破一切境界，永无止境。」", "score": 2},
			{"text": "「在有生之年达到最高境界，了无遗憾。」", "score": 1},
			{"text": "「修炼只是手段，真正想要的是自由与安稳。」", "score": 0},
			{"text": "「说实话，只是走上了这条路，还没想清楚。」", "score": -1},
		]
	},
]

const QINGYUN_QUESTIONS: Array = [
	{
		"text": "集市中目睹一名同修偷走孤儿的灵石袋。那同修是你下月任务的领队，修为比你高两境界。你：",
		"options": [
			{"text": "当场喝止，要求归还，无论后果。", "score": 2},
			{"text": "私下告知执法堂，不直接出面。", "score": 1},
			{"text": "先记下，等任务结束再考虑。", "score": 0},
			{"text": "装作没看见，此事与你无关。", "score": -1},
		]
	},
	{
		"text": "一位无辜路人被冤枉，正在被人围殴。你能出手相助，但会惹上麻烦。你：",
		"options": [
			{"text": "立即出手，主持公道。", "score": 2},
			{"text": "大声呵斥，制止事态，但不动手。", "score": 1},
			{"text": "绕道而行，此事与你无关。", "score": 0},
			{"text": "默默旁观，人多你一个也改变不了什么。", "score": -1},
		]
	},
	{
		"text": "一项裁决对你有利，但你知道裁决有误——真正的责任在你。你：",
		"options": [
			{"text": "主动如实说明，接受公正裁定。", "score": 2},
			{"text": "私下给受损方补偿，求他不要申诉。", "score": 1},
			{"text": "沉默接受，心存侥幸。", "score": 0},
			{"text": "找理由为裁决辩护，彻底坐实对自己有利的结论。", "score": -1},
		]
	},
	{
		"text": "你的师兄犯了宗规，若你举报他会被重罚，不举报你也违反了连坐制度。你：",
		"options": [
			{"text": "如实上报，规矩就是规矩，情义是情义。", "score": 2},
			{"text": "先私下警告师兄，给他机会主动坦白。", "score": 1},
			{"text": "不举报，暗中补救，希望事情不要扩大。", "score": 0},
			{"text": "完全不管，这是他自己的事。", "score": -1},
		]
	},
	{
		"text": "手边有一份文书，签了能得到一笔可观的好处，但其中条款对第三方不公平。你：",
		"options": [
			{"text": "拒绝签，不参与对他人不公的交易。", "score": 2},
			{"text": "签了，但之后想办法弥补第三方的损失。", "score": 1},
			{"text": "签了，好处归自己，第三方的事与你无干。", "score": 0},
			{"text": "签了，这类条款本就是惯例，没什么大不了。", "score": -1},
		]
	},
]

const GATE_PUZZLE: Dictionary = {
	"intro": (
		"═══ 第三关：古堡三道门 ═══\n\n" +
		"你被带入一座古堡，需通过三道关卡。\n" +
		"每关两扇门——生门通向下一关，死门通向陷阱。\n" +
		"每扇门前各有一名守卫：骑士永远说真话，无赖永远说假话。\n" +
		"你不知道任何守卫的身份。\n\n" +
		"规则：每道关卡只能问一名守卫一个问题，问完必须立刻选门。\n\n" +
		"选错门，即死。"
	),
	"rounds": [
		{
			"scene_text": (
				"第一关\n\n" +
				"两扇门：左门、右门。\n" +
				"守卫甲守左门，守卫乙守右门。\n\n" +
				"甲说：「我们两人中，至少有一个是骑士。」\n" +
				"乙说：「左门是死门。」"
			),
			"guard_name": "守卫甲",
			"questions": [
				{
					"text": "如果我问乙哪扇是生门，他会指哪扇？",
					"answer": "甲沉默片刻，抬手指向左门。",
					"decisive": true,
					"door_hint": "双重否定法：甲指左门→左门是死门，走右门。",
				},
				{
					"text": "左门是生门吗？",
					"answer": "「是。」",
					"decisive": false,
					"door_hint": "你无法判断甲是骑士还是无赖，这个回答没有给你足够信息。",
				},
				{
					"text": "你是骑士吗？",
					"answer": "「是。」",
					"decisive": false,
					"door_hint": "骑士和无赖都会这样回答，这个问题没有给你任何信息。",
				},
				{
					"text": "右门是死门吗？",
					"answer": "「不是。」",
					"decisive": false,
					"door_hint": "你无法判断甲是骑士还是无赖，这个回答没有给你足够信息。",
				},
			],
			"correct_door": 1,
			"pass_text": "右门后是一条石道。地上有一张纸条。\n\n纸条上写着：「丙和丁中，有一个和我是同一种人。」\n\n——乙",
			"fail_death_text": (
				"═══ 死亡 ═══\n\n" +
				"左门轰然开启。\n\n" +
				"你踏入的瞬间，地板塌陷，四面石墙合拢。\n\n" +
				"这是死门。\n\n" +
				"修罗门的考核，从来没有说过会让你安全离开。"
			),
		},
		{
			"scene_text": (
				"第二关\n\n" +
				"【纸条】乙写道：「丙和丁中，有一个和我是同一种人。」\n\n" +
				"两扇门：左门、右门。\n" +
				"守卫丙守左门，守卫丁守右门。\n\n" +
				"丙说：「丁是无赖。」\n" +
				"丁说：「左边是生门。」"
			),
			"guard_name": "守卫丙",
			"questions": [
				{
					"text": "如果我问丁哪扇是生门，他会指哪扇？",
					"answer": "丙停顿了一下，指向右门。",
					"decisive": true,
					"door_hint": "双重否定法：丙指右门→右门是死门，走左门。",
				},
				{
					"text": "你和乙是同一种人吗？",
					"answer": "「不是。」",
					"decisive": false,
					"door_hint": "乙的身份尚未确认，纸条信息存在矛盾，这个问题无法有效推导。",
				},
				{
					"text": "丁是骑士吗？",
					"answer": "「不是。」",
					"decisive": false,
					"door_hint": "丙的身份未知，这个回答无法确认真假。",
				},
				{
					"text": "左门是生门吗？",
					"answer": "「是。」",
					"decisive": false,
					"door_hint": "丙的身份未知，这个回答无法确认真假。",
				},
			],
			"correct_door": 0,
			"pass_text": "左门后，墙上刻着一行字：\n\n「守卫戊是骑士。」\n\n字迹与前两关的风格截然不同。",
			"fail_death_text": (
				"═══ 死亡 ═══\n\n" +
				"右门打开了。\n\n" +
				"陷阱触发在你脚下。\n\n" +
				"你没有来得及叫出声。\n\n" +
				"修罗门的考核，从来不保证出路。"
			),
		},
		{
			"scene_text": (
				"第三关\n\n" +
				"【墙刻】「守卫戊是骑士。」（字迹与前两关截然不同，真实性存疑）\n\n" +
				"只有一名守卫戊，站在两扇门中间。\n\n" +
				"戊说：「左门是生门。」\n" +
				"戊又说：「我刚才说的是真话。」\n\n" +
				"不依赖墙上刻字，只根据戊的两句话——"
			),
			"guard_name": "守卫戊",
			"questions": [
				{
					"text": "如果我问你右门是不是死门，你会说是吗？",
					"answer": "戊不动声色地说：「是。」",
					"decisive": true,
					"door_hint": "自指问法：戊答「是」→右门是死门，走左门。",
				},
				{
					"text": "左门是生门吗？",
					"answer": "「是。」\n\n他说得平静。",
					"decisive": false,
					"door_hint": "戊的两句话对骑士和无赖均自洽，这个问题无法锁定他的身份。",
				},
				{
					"text": "你是骑士吗？",
					"answer": "「是。」",
					"decisive": false,
					"door_hint": "骑士和无赖都会这样回答，无效。",
				},
				{
					"text": "墙上的字是真的吗？",
					"answer": "戊斜了你一眼，没有回答。",
					"decisive": false,
					"door_hint": "守卫没有义务回答这个问题，你浪费了提问权。",
				},
			],
			"correct_door": 0,
			"pass_text": "左门之后，没有更多的关卡。\n\n一位修罗门长老在等你，手里拿着一块令牌。",
			"fail_death_text": (
				"═══ 死亡 ═══\n\n" +
				"右门开了，声音很轻。\n\n" +
				"然后什么都没有了。\n\n" +
				"修罗门考核，终。"
			),
		},
	],
}

func setup(p, s, t, tal, itm, rein, hx, story_lb, stats_lb, choices_b, main_r = null, overlay_r = null):
	player       = p
	story        = s
	task         = t
	talent       = tal
	items_node   = itm
	reincarnation = rein
	hex          = hx
	story_label  = story_lb
	stats_label  = stats_lb
	choices_box  = choices_b
	main_root    = main_r
	overlay_root = overlay_r
	_show_name_input()

# ── 工具函数 ──────────────────────────────────────────────────

func _clear_choices():
	for child in choices_box.get_children():
		child.queue_free()

func _add_button(text: String, callback: Callable, disabled: bool = false):
	var btn = Button.new()
	btn.text = text
	btn.disabled = disabled
	btn.custom_minimum_size = Vector2(0, UITheme.BTN_H)
	btn.add_theme_font_size_override("font_size", UITheme.FONT_BTN)
	btn.pressed.connect(callback)
	choices_box.add_child(btn)

func _add_label(text: String):
	var lbl = Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices_box.add_child(lbl)

func _add_separator():
	choices_box.add_child(HSeparator.new())

func _update_stats():
	stats_label.text = player.get_stats_text()

func _stats_footer() -> String:
	return (
		"\n【当前境界】" + player.get_realm_name() +
		"\n【修为进度】" + str(player.cultivation) + " / " + str(player.REALM_REQUIRED[player.realm]) +
		"\n【剩余寿命】" + str(player.lifespan) + " 年" +
		"\n【年纪】" + str(player.age) + " 岁" +
		"\n【" + player.get_mind_display() + "】" +
		"\n【持有灵石】" + str(player.gold) + " 枚"
	)

# 寿命归零时，若持有延寿丹则给予续命选项
func _handle_death_or_continue():
	if player.has_item("延寿丹"):
		var bonus = player.get_lifespan_pill_bonus()
		_add_separator()
		if bonus > 0:
			_add_label("⚠️ 寿命耗尽！背囊中尚有【延寿丹】，是否服下续命？（当前药效：+%d年）" % bonus)
			_add_button("🔴 服下延寿丹，续命%d年" % bonus, _on_emergency_lifespan)
		else:
			_add_label("⚠️ 寿命耗尽！背囊中尚有【延寿丹】，但药效已彻底耗尽，服下亦无济于事。")
			_add_button("🔴 服下延寿丹（药效已尽）", _on_emergency_lifespan)
		_add_button("接受命运，寿终正寝", _show_gameover)
	else:
		_show_gameover()

func _on_emergency_lifespan():
	var msg = player.use_item("延寿丹")
	story_label.text += "\n\n" + msg
	_update_stats()
	_clear_choices()
	if player.lifespan > 0:
		_add_button("继续修行 →", _continue_or_popup.bind(show_free))
	else:
		_handle_death_or_continue()

# ── STATE: NAME_INPUT 角色命名 ────────────────────────────────

func _show_name_input():
	current_state = State.NAME_INPUT
	story_label.text = (
		"═══ 踏入修仙界 ═══\n\n" +
		"修仙之路，从一个名字开始。\n" +
		"你叫什么？"
	)
	_clear_choices()
	_name_input = LineEdit.new()
	_name_input.placeholder_text = "输入道号"
	_name_input.custom_minimum_size = Vector2(0, UITheme.BTN_H)
	_name_input.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_input.text_submitted.connect(func(_t): _on_name_confirm())
	choices_box.add_child(_name_input)
	_add_button("确认道号 →", _on_name_confirm)

func _on_name_confirm():
	var name_text = _name_input.text.strip_edges()
	if name_text != "":
		player.player_name = name_text
	_name_input = null
	# 编年史：起手记一条
	player.add_life_entry(player.age, player.age, "birth",
		"睁眼便已二十岁，身在修仙世界，灵根普通，身上四十枚灵石。五家宗门开着大门，路在脚下。")
	# 转世铭印：仅当存在累计天赋点时进入分配屏；否则直接选宗
	if reincarnation != null and reincarnation.bonus_talent_points > 0:
		_show_talent_allocate()
	else:
		_show_faction_select()

# ── STATE: TALENT_ALLOCATE 来世铭印分配 ───────────────────────

func _show_talent_allocate():
	current_state = State.TALENT_ALLOCATE
	_refresh_talent_allocate()

func _refresh_talent_allocate():
	var remain: int = talent.get_remaining()
	var text = "═══ 来世铭印 ═══\n\n"
	text += "前世魂魄留下印记，分予今生。\n"
	text += "（来源：转世遗赠 — 累计天赋点 +%d）\n\n" % reincarnation.bonus_talent_points
	text += "【修炼天赋】%d　→　%s\n" % [talent.talent_speed, talent.get_speed_desc()]
	text += "【气运】%d　→　%s\n\n" % [talent.talent_luck, talent.get_luck_desc()]
	text += "剩余天赋点：%d" % remain
	story_label.text = text
	_clear_choices()
	_add_button("修炼天赋 +1", _on_talent_add.bind("speed"), remain <= 0)
	_add_button("气运 +1", _on_talent_add.bind("luck"), remain <= 0)
	_add_button("修炼天赋 -1", _on_talent_remove.bind("speed"), talent.talent_speed <= 0)
	_add_button("气运 -1", _on_talent_remove.bind("luck"), talent.talent_luck <= 0)
	_add_separator()
	_add_button("分配完毕，启程 →", _on_talent_confirm, remain > 0)

func _on_talent_add(t: String):
	talent.add_point(t)
	_refresh_talent_allocate()

func _on_talent_remove(t: String):
	talent.remove_point(t)
	_refresh_talent_allocate()

func _on_talent_confirm():
	# 分配结果累加到 player（reincarnation 已注入 talent_luck = bonus_start_luck）
	player.talent_speed += talent.talent_speed
	player.talent_luck  += talent.talent_luck
	_show_faction_select()

# ── STATE: FACTION_SELECT 宗门选择 ────────────────────────────

const FACTIONS = [
	{
		"name": "衍天宗",
		"prestige": 60,
		"blurb": "「本宗只收天才，蠢材免进。根骨不够别来丢人，来了也是自讨苦吃。有真本事的，考核见真章。」"
	},
	{
		"name": "修罗门",
		"prestige": -30,
		"blurb": "「本门不问来历，不讲仁义。考核有死亡风险，入门后江湖名声全毁。觉得值的，来。」"
	},
	{
		"name": "青云宗",
		"prestige": 30,
		"blurb": "「青云宗广纳正道弟子，规矩繁多，庇护是真的。入门声誉上涨，江湖行走便利。考核严格，通过者皆是自己人。」"
	},
	{
		"name": "草门",
		"prestige": 0,
		"blurb": "「本门无甚要求，考核全看天意。进来之后机缘颇多——也可能什么都没有。来不来，随缘。」"
	},
	{
		"name": "守一门",
		"prestige": 0,
		"blurb": "「考核简单，待遇一般，没什么了不起的。但稳，不坑人，养得活弟子。」"
	},
]

func _show_faction_select():
	current_state = State.FACTION_SELECT
	# 灵石起手 = 40 + 转世累计 bonus_start_gold
	player.gold = reincarnation.START_GOLD_BASE + reincarnation.bonus_start_gold
	story_label.text = (
		"═══ " + player.player_name + " ═══\n\n" +
		"练气初成，身上四十枚灵石，站在路口。\n" +
		"五家宗门开着大门。也可以转身，做散修。\n\n" +
		"选一条路走下去。"
	)
	_update_stats()
	_clear_choices()
	for f in FACTIONS:
		if f["name"] in _failed_factions:
			continue
		_add_label("【" + f["name"] + "】" + f["blurb"])
		var pres_hint = ""
		if f["prestige"] > 0:
			pres_hint = "  入宗声望+" + str(f["prestige"])
		elif f["prestige"] < 0:
			pres_hint = "  入宗声望" + str(f["prestige"])
		_add_button("拜入" + f["name"] + pres_hint, _on_faction_chosen.bind(f["name"], f["prestige"]))
		_add_separator()
	_add_button("转身离开，做散修", _on_choose_rogue)

func _on_faction_chosen(faction_name: String, prestige_change: int):
	player.faction = faction_name
	match faction_name:
		"守一门": _start_shouyi_exam(); return
		"修罗门": _start_xiuluo_exam(); return
		"衍天宗": _start_yangtian_exam(); return
		"青云宗": _start_qingyun_exam(); return
		"草门":   _start_caomen_exam(); return
	if prestige_change != 0:
		player.add_prestige(prestige_change)
	story_label.text = (
		"═══ 入门 ═══\n\n" +
		player.player_name + " 走进了" + faction_name + "的大门。\n" +
		"从今天起，你是这里的人了。"
	)
	_update_stats()
	_clear_choices()
	_add_button("开始修行 →", func(): _start_hex_draw("start", show_free))

func _on_choose_rogue():
	player.faction = "散修"
	player.join_year = -1   # 散修无入宗年纪
	# 编年史
	player.add_life_entry(player.age, player.age, "rogue",
		"转身离开五家宗门，做了散修。天地任走，资源靠自己。")
	story_label.text = (
		"═══ 散修 ═══\n\n" +
		player.player_name + " 转身离开。\n" +
		"天地任你走，资源靠自己，危险也靠自己。\n" +
		"没有庇护，没有约束。"
	)
	_update_stats()
	_clear_choices()
	_add_button("开始修行 →", func(): _start_hex_draw("start", show_free))

# ── STATE: EXAM 宗门考核（守一门）────────────────────────────────

func _show_exam_intro() -> void:
	current_state = State.EXAM_INTRO
	story_label.text = _exam_intro_text
	_update_stats()
	_clear_choices()
	_add_button("明白了，开始考核", _show_exam_question)
	_add_button("再想想，回路口", _on_exam_intro_leave)

func _on_exam_intro_leave() -> void:
	# 玩家未尝试，不计入 _failed_factions，可重选
	player.faction = ""
	_show_faction_select()

func _show_exam_question() -> void:
	current_state = State.EXAM_Q
	var q: Dictionary = _exam_q_data[_exam_q_index]
	story_label.text = "第一关  第%d题（共%d题）\n\n%s" % [_exam_q_index + 1, _exam_q_data.size(), q["text"]]
	_update_stats()
	_clear_choices()
	for opt in q["options"]:
		_add_button(opt["text"], _on_exam_answer.bind(opt["score"]))

func _on_exam_answer(score: int) -> void:
	_exam_score += score
	_exam_q_index += 1
	if _exam_q_index < _exam_q_data.size():
		_show_exam_question()
	elif _exam_score >= _exam_threshold:
		_exam_post_q_fn.call()
	else:
		_show_exam_result(false, "part1")

func _show_exam_minigame() -> void:
	current_state = State.EXAM_MINIGAME
	story_label.text = (
		"第二关：守元功\n\n" +
		"将灵力波动条维持在平稳区间（35-65）内。\n" +
		"累计平稳满20秒通过；区间外超10秒判定失败。"
	)
	_update_stats()
	_clear_choices()
	_exam_wave = 50.0
	_exam_stable_time = 0.0
	_exam_elapsed = 0.0

	_exam_bar = ProgressBar.new()
	_exam_bar.min_value = 0.0
	_exam_bar.max_value = 100.0
	_exam_bar.value = 50.0
	_exam_bar.custom_minimum_size = Vector2(0, 24)
	_exam_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices_box.add_child(_exam_bar)

	_exam_status_lbl = Label.new()
	_exam_status_lbl.text = "▮ 灵力平稳"
	_exam_status_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	choices_box.add_child(_exam_status_lbl)

	_exam_time_lbl = Label.new()
	_exam_time_lbl.text = "平稳：0.0s / 需20s   剩余：30.0s"
	_exam_time_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	choices_box.add_child(_exam_time_lbl)

	var btn := Button.new()
	btn.text = "稳住"
	btn.custom_minimum_size = Vector2(0, UITheme.BTN_H)
	btn.add_theme_font_size_override("font_size", UITheme.FONT_BTN)
	btn.pressed.connect(_on_exam_wave_nudge)
	choices_box.add_child(btn)

func _on_exam_wave_nudge() -> void:
	_exam_wave = lerp(_exam_wave, 50.0, 0.16)

func _cleanup_exam_wave_ui() -> void:
	for node in [_exam_bar, _exam_status_lbl, _exam_time_lbl]:
		if is_instance_valid(node):
			node.queue_free()
	_exam_bar = null
	_exam_status_lbl = null
	_exam_time_lbl = null

func _show_exam_logic() -> void:
	current_state = State.EXAM_LOGIC
	var narrative := "最后一道推理题，答对方可入门。"
	match _exam_faction:
		"衍天宗": narrative = "第三关：高阶推理。以下为一道高难度推理题，答对方可入门。"
		"青云宗": narrative = "第三关：推理验心。以下为一道推理题，答对方可入门。"
	story_label.text = "第三关：推理验心"
	_update_stats()
	_clear_choices()
	_exam_logic_node = MinigameLogic.new()
	_exam_logic_node.configure({
		"pool": _exam_logic_pool,
		"rounds": 1,
		"narrative": narrative,
	})
	_exam_logic_node.minigame_completed.connect(_on_exam_logic_done)
	choices_box.add_child(_exam_logic_node)

func _on_exam_logic_done(result: String) -> void:
	if is_instance_valid(_exam_logic_node):
		_exam_logic_node.queue_free()
		_exam_logic_node = null
	_show_exam_result(result == "pass", "part3")

func _show_exam_result(passed: bool, failed_part: String = "") -> void:
	current_state = State.EXAM_RESULT
	_clear_choices()
	if passed:
		match _exam_faction:
			"守一门":
				story_label.text = (
					"长老在册子上盖了一个印章，递给你：「你过了。」\n\n" +
					"你就这样成了守一门的弟子。没有仪式，没有宣誓，就是一个印章。\n\n" +
					"——但这是真的。"
				)
			"修罗门":
				story_label.text = (
					"长老从暗处走出，把一块令牌扔给你。\n\n" +
					"「活着进来了。进来。」\n\n" +
					"没有仪式，没有宣誓。\n\n" +
					"修罗门的声望随之跌落，但这里的门向你开了。"
				)
				player.add_prestige(-30)
			"衍天宗":
				story_label.text = (
					"考官审视了你良久，终于开口：\n\n" +
					"「你算是通过了。」\n\n" +
					"衍天宗不举行入门仪式。\n\n" +
					"一枚令牌落在桌上，后面再无言语。\n\n" +
					"——衍天宗声望随之攀升。"
				)
				player.add_prestige(60)
			"青云宗":
				story_label.text = (
					"执法长老在案册上盖了一枚青云印，抬头看你：\n\n" +
					"「青云宗的弟子，须正身、守规、不徇私。\n 记住今日所答，往后也如此行事。」\n\n" +
					"你成了青云宗的弟子。\n\n" +
					"声誉随之上涨，江湖行走便利了许多。"
				)
				player.add_prestige(30)
			"草门":
				story_label.text = (
					"不知何时，一位老者出现在你旁边。\n\n" +
					"「你过了。」\n\n" +
					"你还没来得及问他是谁，他已不见踪影。\n\n" +
					"——草门的考核，就这样结束了。"
				)
		_update_stats()
		_add_button("踏入" + _exam_faction, _on_exam_passed)
	else:
		match _exam_faction:
			"守一门":
				match failed_part:
					"part1":
						story_label.text = "守一门的弟子看了看你的答卷，沉默了一会儿。\n\n「你可以再想想。」\n\n他没有多说，就转身走了。"
					"part2":
						story_label.text = "波动条一路飘到了边界，灵力散逸殆尽。\n\n负责考核的师兄摆了摆手：「这一次没过，本局不再受理。」\n\n他语气平静，没有嘲讽。"
					"part3":
						story_label.text = "推理题答错了。\n\n长老合上册子：「脑子还需磨练。本局不再受理。」"
			"修罗门":
				match failed_part:
					"part1":
						story_label.text = "使者把契书收了回去。\n\n「软了。走吧。」\n\n三个字，没有嘲讽，没有遗憾。"
					"part2":
						story_label.text = "刀势没有停在通过区。\n\n「本局不再受理。」"
			"衍天宗":
				match failed_part:
					"part1":
						story_label.text = "考官放下你的答卷，没有表情。\n\n「不够。」\n\n两个字，转身离开。"
					"part2":
						story_label.text = "衍天宗不留没有速度天赋的人。\n\n「本局不再受理。」"
					"part3":
						story_label.text = "推理题答错了。\n\n考官合上册子：「思维尚不到位。本局不再受理。」"
			"青云宗":
				match failed_part:
					"part1":
						story_label.text = "执法长老翻了翻你的答卷，慢慢摇了摇头。\n\n「青云宗的弟子，需要比这更清晰的道义判断。本局不再受理。」"
					"part2":
						story_label.text = "灵力波动超出了允许范围。\n\n「心性未到，规矩难守。本局不再受理。」"
					"part3":
						story_label.text = "推理题答错了。\n\n「本局不再受理。」"
		_update_stats()
		_failed_factions.append(_exam_faction)
		_add_button("离开", _show_faction_select)

func _on_exam_passed() -> void:
	# 入宗写入：affinity + join_year（与 origin-mechanism.md / faction-system.md 对齐）
	player.faction_affinity[player.faction] = 50
	player.join_year = player.age
	# 编年史
	player.add_life_entry(player.age, player.age, "join",
		"通过考核，拜入" + player.faction + "，从此为门下弟子。")
	_start_hex_draw("start", show_free)

# ── 考核入口 — 按宗门分流 ──────────────────────────────────────

func _start_shouyi_exam() -> void:
	_exam_faction = "守一门"
	_exam_score = 0
	_exam_q_index = 0
	_exam_q_data = SHOUYI_QUESTIONS
	_exam_threshold = 6
	_exam_post_q_fn = _show_exam_minigame
	_exam_intro_text = (
		"═══ 守一门入门考核 ═══\n\n" +
		"「不考天赋，不考根骨。\n 考的只有一件事——\n 你撑不撑得住。」\n\n" +
		"考核失败不扣声望，但本局不可再考。\n\n" +
		"按下「开始考核」，听凭天意。"
	)
	_show_exam_intro()

func _start_xiuluo_exam() -> void:
	_exam_faction = "修罗门"
	_exam_score = 0
	_exam_q_index = 0
	_exam_q_data = XIULUO_QUESTIONS
	_exam_threshold = 6
	_exam_post_q_fn = _show_exam_stopline
	_exam_stopline_preset = "xiuluo"
	_exam_logic_pool = "easy"
	_exam_intro_text = (
		"═══ 修罗门入门考核 ═══\n\n" +
		"「本门不问来历，不讲仁义。\n 考核有死亡风险——\n 这不是警告，是事实。」\n\n" +
		"入宗声望-30。考核失败不扣声望，死亡游戏结束。\n\n" +
		"按下「开始考核」，无法回头。"
	)
	_show_exam_intro()

func _start_yangtian_exam() -> void:
	_exam_faction = "衍天宗"
	_exam_score = 0
	_exam_q_index = 0
	_exam_q_data = YANGTIAN_QUESTIONS
	_exam_threshold = 6
	_exam_post_q_fn = _show_exam_stopline
	_exam_stopline_preset = "yangtian_skill"
	_exam_logic_pool = "advanced"
	_exam_intro_text = (
		"═══ 衍天宗入门考核 ═══\n\n" +
		"「本宗只收有志于长生者。\n 修为可练，道心不可装。」\n\n" +
		"入宗声望+60。考核失败不扣声望，本局不可再考。\n\n" +
		"按下「开始考核」，是骡子是马，自见分晓。"
	)
	_show_exam_intro()

func _start_qingyun_exam() -> void:
	_exam_faction = "青云宗"
	_exam_score = 0
	_exam_q_index = 0
	_exam_q_data = QINGYUN_QUESTIONS
	_exam_threshold = 6
	_exam_post_q_fn = _show_exam_stopline
	_exam_stopline_preset = "qingyun"
	_exam_logic_pool = "medium"
	_exam_intro_text = (
		"═══ 青云宗入门考核 ═══\n\n" +
		"「青云宗广纳正道弟子，规矩繁多，庇护是真的。\n 考核严格，通过者皆是自己人。」\n\n" +
		"入宗声望+30。考核失败不扣声望，本局不可再考。\n\n" +
		"按下「开始考核」，循规蹈矩，依次而行。"
	)
	_show_exam_intro()

func _start_caomen_exam() -> void:
	_exam_faction = "草门"
	_caomen_elapsed = 0.0
	_show_caomen_exam()

func _show_caomen_exam() -> void:
	current_state = State.EXAM_CAOMEN
	_caomen_elapsed = 0.0
	story_label.text = (
		"═══ 草门入门考核 ═══\n\n" +
		"本门无甚要求。\n\n" +
		"请根据实际情况，按流程完成考核。"
	)
	_update_stats()
	_clear_choices()
	_add_button("Step 1：确认报名意向", _on_caomen_fake_btn)
	_add_button("Step 2：阅读考核须知（共48条）", _on_caomen_fake_btn)
	_add_button("Step 3：填写基本信息", _on_caomen_fake_btn)
	_add_button("Step 4：提交考核申请", _on_caomen_fake_btn)
	_add_separator()
	var btn := Button.new()
	btn.text = "随缘"
	btn.custom_minimum_size = Vector2(0, UITheme.BTN_H)
	btn.add_theme_font_size_override("font_size", UITheme.FONT_BTN)
	btn.pressed.connect(_on_caomen_random)
	choices_box.add_child(btn)

func _on_caomen_fake_btn() -> void:
	current_state = State.EXAM_RESULT
	story_label.text = (
		"考官在旁边看了你一眼。\n\n" +
		"「今天的考核已经结束了。」\n\n" +
		"你没能通过。"
	)
	_update_stats()
	_clear_choices()
	_failed_factions.append("草门")
	_add_button("离开", _show_faction_select)

func _on_caomen_random() -> void:
	_show_exam_result(true)

# ── 修罗门 Part2：止刀试炼 ──────────────────────────────────────

func _show_exam_stopline() -> void:
	current_state = State.EXAM_STOPLINE
	match _exam_faction:
		"修罗门": story_label.text = "第二关：止刀试炼\n\n控制飞刀停在通过区，落入中央死区即死。"
		"衍天宗": story_label.text = "第二关：速知试炼\n\n飞刀高速滑动，精准停在通过区内。"
		"青云宗": story_label.text = "第二关：法度稳心\n\n将灵力稳定在青云宗允许的区间内。"
	_update_stats()
	_clear_choices()
	_exam_stopline_node = MinigameStopline.new()
	var preset: Dictionary
	match _exam_stopline_preset:
		"xiuluo":         preset = MinigameStopline.preset_xiuluo()
		"yangtian_skill": preset = MinigameStopline.preset_yangtian_skill()
		"qingyun":        preset = MinigameStopline.preset_qingyun()
		_:                preset = MinigameStopline.preset_shouyi()
	_exam_stopline_node.configure(preset)
	_exam_stopline_node.minigame_completed.connect(_on_exam_stopline_done)
	choices_box.add_child(_exam_stopline_node)

func _on_exam_stopline_done(result: String) -> void:
	if is_instance_valid(_exam_stopline_node):
		_exam_stopline_node.queue_free()
		_exam_stopline_node = null
	match result:
		"death":
			if _exam_faction == "修罗门":
				_show_xiuluo_exam_death(
					"═══ 死亡 ═══\n\n" +
					"飞刀停在了死区。\n\n" +
					"冲击转瞬即至，你没有时间反应。\n\n" +
					"修罗门的考核，从来没有承诺过安全。"
				)
			else:
				_show_exam_result(false, "part2")
		"fail": _show_exam_result(false, "part2")
		"pass":
			match _exam_faction:
				"修罗门": _show_exam_gate_intro()
				_: _show_exam_logic()

func _show_xiuluo_exam_death(death_text: String) -> void:
	current_state = State.GAMEOVER
	# 编年史：死亡 entry
	player.add_life_entry(player.age, player.age, "death",
		"魂断" + player.faction + "考核。")
	story_label.text = (
		death_text + "\n\n" +
		_build_life_summary() +
		"─── 最终成就 ───\n\n" +
		player.get_detail_text() + "\n\n" +
		items_node.get_collection_text(player)
	)
	_update_stats()
	_clear_choices()
	_add_button("重新转世", _on_restart)

# ── 修罗门 Part3：古堡三道门 ────────────────────────────────────

func _show_exam_gate_intro() -> void:
	current_state = State.EXAM_GATE_INTRO
	_gate_round = 0
	story_label.text = GATE_PUZZLE["intro"]
	_update_stats()
	_clear_choices()
	_add_button("进入第一关 →", _show_exam_gate_question)

func _show_exam_gate_question() -> void:
	current_state = State.EXAM_GATE_Q
	var rd: Dictionary = GATE_PUZZLE["rounds"][_gate_round]
	story_label.text = rd["scene_text"]
	_update_stats()
	_clear_choices()
	_add_label("向%s提问：" % rd["guard_name"])
	for i in rd["questions"].size():
		_add_button(rd["questions"][i]["text"], _on_exam_gate_question.bind(i))

func _on_exam_gate_question(q_index: int) -> void:
	_gate_q_chosen = q_index
	current_state = State.EXAM_GATE_ANS
	var rd: Dictionary = GATE_PUZZLE["rounds"][_gate_round]
	var q: Dictionary = rd["questions"][q_index]
	story_label.text = (
		"你问%s：「%s」\n\n%s回答：%s\n\n%s" % [
			rd["guard_name"], q["text"],
			rd["guard_name"], q["answer"],
			q["door_hint"]
		]
	)
	_update_stats()
	_clear_choices()
	_add_label("选择门：")
	_add_button("走左门", _on_exam_gate_door.bind(0))
	_add_button("走右门", _on_exam_gate_door.bind(1))

func _on_exam_gate_door(door: int) -> void:
	var rd: Dictionary = GATE_PUZZLE["rounds"][_gate_round]
	if door != rd["correct_door"]:
		_show_xiuluo_exam_death(rd["fail_death_text"])
		return
	_gate_round += 1
	if _gate_round >= GATE_PUZZLE["rounds"].size():
		_show_exam_result(true)
	else:
		story_label.text = rd["pass_text"]
		_update_stats()
		_clear_choices()
		_add_button("继续前行 →", _show_exam_gate_question)

# ── STATE: FREE 主界面 ─────────────────────────────────────────

func show_free():
	current_state = State.FREE
	story_label.text = player.get_free_stats_text()
	_update_stats()
	_clear_choices()

	var cult_full   = player.cultivation >= player.REALM_REQUIRED[player.realm]
	var available   = player.get_available_retreat_years()
	var mind_blocked = available <= 0
	var retreat_text: String
	if mind_blocked:
		retreat_text = "🏔 闭关修炼（心智不坚，需出门历练）"
	elif cult_full:
		retreat_text = "🏔 闭关修炼（可突破，剩余 %d 年）" % available
	else:
		retreat_text = "🏔 闭关修炼（剩余 %d 年）" % available

	var task_locked  = player.prestige < -50
	var market_label = "⚫ 黑市" if player.prestige < -100 else "🏪 宝物集市"
	_add_button(retreat_text,  _on_retreat, mind_blocked)
	_add_button("🚶 出门历练",  _on_practice)
	_add_button("📜 门派任务（声名狼藉）" if task_locked else "📜 门派任务", _on_task_list, task_locked)
	_add_button(market_label,  _on_market)
	_add_button("📦 宝物背包",  _on_status)
	_add_button("📖 编年史",   _on_chronicle)
	_add_separator()

# ── STATE: RETREAT_SELECT 闭关（自定义年数）────────────────────

func _on_retreat():
	_show_retreat_select()

func _show_retreat_select():
	current_state = State.RETREAT_SELECT
	var cap  = player.REALM_REQUIRED[player.realm]
	var mult = player.get_speed_multiplier()
	var available = player.get_available_retreat_years()
	var actual = mini(_retreat_years, available)
	var est  = int(actual * 8 * mult)
	var cult_full = player.cultivation >= cap
	var is_flying = player.realm >= player.REALMS.size() - 1
	var truncated = _retreat_years > available

	var tips = ""
	if actual >= 30:
		tips = "💡 顿悟概率提升   ⚠️ 有走火入魔风险"
	elif actual >= 10:
		tips = "💡 有顿悟机会（额外修为）"

	# 突破信息面板
	var bt_info = ""
	if not is_flying:
		var realm_base = int(player.REALM_BASE_CHANCE[mini(player.realm, player.REALM_BASE_CHANCE.size()-1)] * 100)
		var base_pct   = int(player.get_base_breakthrough_chance() * 100)
		var eff_pct    = int(player.get_breakthrough_chance() * 100)
		var req_item   = player.REALM_ITEMS[player.realm]
		bt_info = "\n── 突破 " + player.REALMS[player.realm + 1] + " ──\n"
		if player.breakthrough_boost > 0.0:
			bt_info += "成功率：%d%% → %d%%（基础%d%% · 气运%d · 破境符+20%%）\n" % [base_pct, eff_pct, realm_base, player.talent_luck]
		else:
			bt_info += "成功率：%d%%（基础%d%% · 气运%d）\n" % [base_pct, realm_base, player.talent_luck]
		if req_item != "":
			bt_info += "突破材料：【%s】%s\n" % [req_item, "✓ 已持有" if player.has_item(req_item) else "✗ 尚未持有"]
		else:
			bt_info += "突破材料：无需\n"
		if not cult_full:
			bt_info += "（修为未满，还差 %d 点）\n" % (cap - player.cultivation)

	var mind_line = "可闭关年数：%d 年\n" % available
	var trunc_line = ""
	if truncated:
		trunc_line = "⚠️ 心志不足，本次实际仅闭关 %d 年（输入 %d）\n" % [actual, _retreat_years]
	story_label.text = (
		"═══ 闭关修炼 ═══\n\n" +
		"当前修为：" + str(player.cultivation) + " / " + str(cap) + "\n" +
		"修炼倍率：×%.1f\n" % mult +
		mind_line +
		trunc_line +
		"\n预计收益：修为 +" + str(est) + "  寿命 -" + str(actual) + " 年\n" +
		(tips + "\n" if tips != "" else "") +
		bt_info
	)
	_update_stats()
	_clear_choices()

	# 年数调整行
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for delta in [-10, -5, -1]:
		var b = Button.new()
		b.text = str(delta)
		b.custom_minimum_size = Vector2(UITheme.BTN_SMALL_W, UITheme.BTN_H)
		b.add_theme_font_size_override("font_size", UITheme.FONT_BTN)
		b.disabled = (_retreat_years + delta < 1)
		b.pressed.connect(_on_retreat_adjust.bind(delta))
		hbox.add_child(b)
	var lbl = Label.new()
	lbl.text = "  %d 年  " % _retreat_years
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", UITheme.FONT_EMPHASIS)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)
	for delta in [1, 5, 10]:
		var b2 = Button.new()
		b2.text = "+" + str(delta)
		b2.custom_minimum_size = Vector2(UITheme.BTN_SMALL_W, UITheme.BTN_H)
		b2.add_theme_font_size_override("font_size", UITheme.FONT_BTN)
		b2.pressed.connect(_on_retreat_adjust.bind(delta))
		hbox.add_child(b2)
	choices_box.add_child(hbox)

	_add_separator()
	_add_button("确认闭关", _on_retreat_confirm, cult_full or is_flying)

	# 突破按钮（修为满 + 非飞升）
	if cult_full and not is_flying:
		var bt_btn = Button.new()
		bt_btn.text = "⚡ 尝试突破 " + player.REALMS[player.realm + 1]
		bt_btn.custom_minimum_size = Vector2(0, UITheme.BTN_H)
		bt_btn.add_theme_font_size_override("font_size", UITheme.FONT_BTN)
		bt_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		bt_btn.pressed.connect(_on_try_breakthrough)
		choices_box.add_child(bt_btn)

	_add_button("返回", show_free)

func _on_retreat_adjust(delta: int):
	_retreat_years = max(1, _retreat_years + delta)
	call_deferred("_show_retreat_select")

func _on_retreat_confirm():
	var age_before = player.age
	var r = player.request_retreat(_retreat_years)
	if r["blocked"]:
		# 入口已禁用，理论上不应到达此处；保护性处理
		_show_result("═══ 闭关 ═══\n\n心智不坚，无法闭关。请先出门历练。" + _stats_footer(), false)
		return

	# 编年史：闭关 entry
	var actual: int = r["actual_years"]
	var entry_text = "闭关修炼 %d 年，修为 +%d" % [actual, r["cult_gain"]]
	if r["truncated"]:
		entry_text += "（心志不坚，原计划 %d 年）" % r["requested"]
	if r["insight"]:
		entry_text += "。其间顿悟，额外得修为 +%d" % r["insight_bonus"]
	if r["danger"]:
		entry_text += "。走火入魔，寿元 -%d" % r["danger_penalty"]
	player.add_life_entry(age_before, age_before + actual, "retreat", entry_text)

	var text = "═══ 闭关结束 ═══\n\n"
	if r["truncated"]:
		text += "心智不坚，本次闭关止步于 %d 年（原计划 %d 年）。\n\n" % [r["actual_years"], r["requested"]]
	if r["insight"]:
		text += "💡 顿悟！额外修为+" + str(r["insight_bonus"]) + "\n"
	if r["danger"]:
		text += "⚠️ 走火入魔！寿命-" + str(r["danger_penalty"]) + "\n"
	if r["insight"] or r["danger"]:
		text += "\n"

	text += "修为 +" + str(r["cult_gain"])
	if r["overflow_msg"] != "": text += "（已达上限）"
	text += "\n寿命 -" + str(r["years"]) + " 年"
	if r["danger"]: text += "（额外 -" + str(r["danger_penalty"]) + "）"

	text += _stats_footer()
	_show_result(text, r["is_dead"])

# ── STATE: STORY 出门历练（含隐藏机缘抽取 + 完成恢复心志）─────
func _on_practice():
	_practice_active = true
	_show_story()

func _show_story():
	var is_evil_prestige = player.prestige < -100
	var effective_chance: float
	if is_evil_prestige:
		var depth = float(mini(abs(player.prestige + 100), 200))
		effective_chance = depth / (depth + 100.0)
	else:
		effective_chance = player.get_hidden_event_chance() * player.get_luck_multiplier()
	# 尝试触发隐藏机缘/恶行事件（多轮多结局）
	var has_events = story.has_evil_events() if is_evil_prestige else story.has_hidden_events()
	if has_events and randf() < effective_chance:
		var event = story.get_hidden_event(is_evil_prestige)
		if not event.is_empty():
			_show_hidden_story(event)
			return
	# 普通历练事件
	current_state = State.STORY
	current_story_data = story.get_random_event(0.0)
	var crush_diff = player.realm - current_story_data.get("suggested_realm", 0)
	if crush_diff >= 2:
		var crush = story.get_crush_choices(current_story_data, player.realm)
		current_story_data = current_story_data.duplicate()
		current_story_data["choices"] = crush
	story_label.text   = current_story_data["text"]
	_update_stats()
	_clear_choices()
	var s_indices = range(current_story_data["choices"].size())
	s_indices.shuffle()
	for i in s_indices:
		var choice    = current_story_data["choices"][i]
		var gold_cost = choice.get("gold", 0)
		var can_afford = gold_cost >= 0 or player.gold >= abs(gold_cost)
		var btn = Button.new()
		btn.text = choice["text"] + ("  （灵石不足）" if not can_afford else "")
		btn.disabled = not can_afford
		btn.custom_minimum_size = Vector2(0, UITheme.BTN_H)
		btn.add_theme_font_size_override("font_size", UITheme.FONT_BTN)
		btn.pressed.connect(_on_choice_pressed.bind(i))
		choices_box.add_child(btn)

func _on_choice_pressed(index: int):
	if current_state != State.STORY:
		return
	var c      = current_story_data["choices"][index]

	# 离开/转身离去：跳过 pass_time、跳过 complete_practice、不应用任何字段
	# 玩家可继续触发历练（_practice_active 保留 true，mind_used 不恢复 → 防刷）
	if c.get("leave", false):
		var leave_text = "═══ 转身离去 ═══\n\n" + c.get("result", "你未涉足此事，转身归山。") + "\n\n"
		leave_text += _stats_footer()
		_show_result(leave_text, false)
		return

	# 境界门槛检查：低于 min_realm 走重伤/致命分支，不发放奖励
	if c.has("min_realm") and player.realm < c["min_realm"]:
		var low_life   = c["low_realm_lifespan"]
		var low_result = c.get("low_realm_result", "你的境界远不足以应对此事，付出了惨重代价。")
		var is_dead    = player.pass_time(abs(low_life))
		var text       = "═══ 时光流逝 ═══\n\n" + low_result + "\n\n"
		text += "寿命 %d 年\n" % low_life
		# 历练完成回调（即使选错走重伤分支，仍算"经历"完成）
		if _practice_active:
			player.complete_practice()
			_practice_active = false
			text += "心志已恢复，心力可继续闭关。\n"
		text += _stats_footer()
		_update_stats()
		_show_result(text, is_dead)
		return

	var cult   = c["cultivation"]
	var life   = c["lifespan"]
	var pres   = c.get("prestige", 0)
	var gold_d = c.get("gold", 0)
	var item   = c.get("item", "")
	var qiyun  = c.get("qiyun", 0)
	var result = c.get("result", "")

	var age_before = player.age
	var overflow = player.add_cultivation(cult)
	var is_dead  = player.pass_time(abs(life))
	player.add_prestige(pres)
	if gold_d != 0: player.add_gold(gold_d)
	if item   != "":
		player.add_item(item)
		if items_node.on_item_collected(item):
			_popup_queue.append({"type": "item", "name": item,
				"desc": items_node.ITEM_META.get(item, {}).get("desc", "")})
	if qiyun > 0:
		player.add_qiyun(qiyun)

	# 编年史：历练 entry（用 result 全文，age 段从 pass_time 前到后）
	if result != "":
		player.add_life_entry(age_before, player.age, "story", result)

	var text = "═══ 时光流逝 ═══\n\n"
	if result != "": text += result + "\n\n"
	if cult > 0:
		text += "修为 +" + str(cult)
		if overflow != "": text += "（已达上限）"
		text += "\n"
	text += "寿命 " + str(life) + " 年\n"
	if gold_d != 0:
		text += "灵石 " + ("+" if gold_d > 0 else "") + str(gold_d) + "\n"
	if item != "": text += "获得：" + item + "\n"
	if pres != 0:
		text += "声望 " + ("+" if pres > 0 else "") + str(pres) + "\n"
	if qiyun > 0:
		text += "气运 +" + str(qiyun) + "\n"

	# 历练完成回调：mind_used=0 + mind_max+=0.25
	if _practice_active:
		player.complete_practice()
		_practice_active = false
		text += "心志已恢复，心力可继续闭关。\n"

	text += _stats_footer()
	_show_result(text, is_dead)

# ── STATE: HIDDEN_STORY 隐藏机缘事件（multi-step-events.md v2.0）──
# 选项三种走向：next（跳 round）/ ending（直接结算）/ minigame（小游戏判定）

func _show_hidden_story(event: Dictionary):
	_hidden_event = event
	# 兼容性：旧 schema rounds 为 Array → 跳过该事件
	if _hidden_event.get("rounds", null) is Array:
		push_warning("hidden event uses legacy Array schema; skipped: " + str(_hidden_event.get("title", "")))
		show_free()
		return
	_hidden_round_id = str(_hidden_event.get("start", ""))
	if _hidden_round_id == "":
		var keys: Array = (_hidden_event["rounds"] as Dictionary).keys()
		if keys.is_empty():
			show_free()
			return
		_hidden_round_id = str(keys[0])
	_show_hidden_round()

func _show_hidden_round():
	current_state = State.HIDDEN_STORY
	var rounds: Dictionary = _hidden_event["rounds"]
	if not rounds.has(_hidden_round_id):
		push_warning("hidden round_id missing: " + _hidden_round_id)
		_finish_hidden_event_safe()
		return
	var round_data: Dictionary = rounds[_hidden_round_id]
	# 不暴露 meta 标签（"✨ 【机缘事件】"）；title 作纯文本叙事 header，与普通历练视觉对齐
	story_label.text = (
		str(_hidden_event["title"]) + "\n\n" +
		str(round_data.get("text", ""))
	)
	_update_stats()
	_clear_choices()
	var choices: Array = round_data.get("choices", [])
	var indices := range(choices.size())
	indices.shuffle()
	for i in indices:
		_add_button(str(choices[i].get("text", "")), _on_hidden_choice.bind(i))

func _on_hidden_choice(index: int):
	if current_state != State.HIDDEN_STORY:
		return
	var round_data: Dictionary = _hidden_event["rounds"][_hidden_round_id]
	var choice: Dictionary = round_data["choices"][index]
	# 显示即时 result + "继续 →" 按钮
	story_label.text = (
		str(_hidden_event["title"]) + "\n\n" +
		str(choice.get("result", ""))
	)
	_update_stats()
	_clear_choices()
	# 优先级：minigame > ending > next
	if choice.has("minigame"):
		_add_button("迎接挑战 →", _start_hidden_minigame.bind(choice["minigame"]))
	elif choice.has("ending"):
		_add_button("查看结局 →", _finish_hidden_event.bind(str(choice["ending"])))
	elif choice.has("next"):
		_hidden_round_id = str(choice["next"])
		_add_button("继续 →", _show_hidden_round)
	else:
		push_warning("hidden choice missing next/ending/minigame; safety end")
		_add_button("结束机缘 →", _finish_hidden_event_safe)

func _start_hidden_minigame(cfg: Dictionary):
	_hidden_minigame_cfg = cfg
	current_state = State.HIDDEN_STORY
	story_label.text = str(_hidden_event.get("title", ""))
	_update_stats()
	_clear_choices()
	var node: Node = _create_hidden_minigame_node(str(cfg.get("type", "")), str(cfg.get("preset", "")))
	if node == null:
		push_warning("unknown hidden minigame type/preset: " + str(cfg))
		_handle_hidden_minigame_done(cfg, "fail")
		return
	_hidden_minigame_node = node
	node.minigame_completed.connect(_on_hidden_minigame_done.bind(cfg))
	choices_box.add_child(node)

func _on_hidden_minigame_done(result: String, cfg: Dictionary):
	if is_instance_valid(_hidden_minigame_node):
		_hidden_minigame_node.queue_free()
		_hidden_minigame_node = null
	_handle_hidden_minigame_done(cfg, result)

func _handle_hidden_minigame_done(cfg: Dictionary, result: String):
	var target: String
	if result == "pass":
		target = str(cfg.get("on_pass", ""))
	else:
		target = str(cfg.get("on_fail", ""))
	var endings: Dictionary = _hidden_event.get("endings", {})
	if endings.has(target):
		_finish_hidden_event(target)
		return
	var rounds: Dictionary = _hidden_event.get("rounds", {})
	if rounds.has(target):
		_hidden_round_id = target
		_show_hidden_round()
		return
	push_warning("hidden minigame target missing: " + target)
	_finish_hidden_event_safe()

func _create_hidden_minigame_node(type_str: String, preset_str: String) -> Node:
	match type_str:
		"stopline":
			var n: MinigameStopline = MinigameStopline.new()
			var preset: Dictionary = {}
			match preset_str:
				"xiuluo":           preset = MinigameStopline.preset_xiuluo()
				"yangtian_skill":   preset = MinigameStopline.preset_yangtian_skill()
				"yangtian_talent":  preset = MinigameStopline.preset_yangtian_talent()
				"qingyun":          preset = MinigameStopline.preset_qingyun()
				"caomen":           preset = MinigameStopline.preset_caomen()
				"shouyi":           preset = MinigameStopline.preset_shouyi()
				_:                  return null
			n.configure(preset)
			return n
		"oddone":
			var n: MinigameOddOne = MinigameOddOne.new()
			var preset: Dictionary = {}
			match preset_str:
				"qiqi":   preset = MinigameOddOne.preset_qiqi()
				"zhuji":  preset = MinigameOddOne.preset_zhuji()
				"jindan": preset = MinigameOddOne.preset_jindan()
				_:        return null
			n.configure(preset)
			return n
		"logic":
			var n: MinigameLogic = MinigameLogic.new()
			n.configure({"pool": preset_str})   # easy / medium / advanced
			return n
		_:
			return null

func _finish_hidden_event(ending_id: String):
	var endings: Dictionary = _hidden_event.get("endings", {})
	if not endings.has(ending_id):
		push_warning("hidden ending missing: " + ending_id)
		_finish_hidden_event_safe()
		return
	var ending: Dictionary = endings[ending_id]
	var gold_d: int = int(ending.get("gold", 0))
	var pres: int = int(ending.get("prestige", 0))
	var item: String = str(ending.get("item", ""))
	var life: int = int(ending.get("lifespan", 0))

	var is_dead: bool = false
	if life < 0:
		is_dead = player.pass_time(abs(life))
	elif life > 0:
		player.lifespan += life
	player.add_prestige(pres)
	if gold_d != 0:
		player.add_gold(gold_d)
	if item != "":
		player.add_item(item)
		if items_node.on_item_collected(item):
			_popup_queue.append({"type": "item", "name": item,
				"desc": items_node.ITEM_META.get(item, {}).get("desc", "")})

	current_state = State.HIDDEN_RESULT
	# 标题与普通历练对齐（"═══ 时光流逝 ═══"），不暴露 hidden 池来源
	var text: String = "═══ 时光流逝 ═══\n\n"
	text += str(_hidden_event["title"]) + "\n\n"
	text += str(ending.get("text", "")) + "\n\n"
	text += "── 奖励 ──\n"
	if life != 0:
		text += "寿命 " + ("+" if life > 0 else "") + str(life) + " 年\n"
	if gold_d != 0:
		text += "灵石 " + ("+" if gold_d > 0 else "") + str(gold_d) + "\n"
	if pres != 0:
		text += "声望 " + ("+" if pres > 0 else "") + str(pres) + "\n"
	if item != "":
		text += "获得：" + item + "\n"

	if _practice_active:
		player.complete_practice()
		_practice_active = false
		text += "\n心志已恢复，心力可继续闭关。\n"

	text += _stats_footer()
	story_label.text = text
	_update_stats()
	_clear_choices()

	if is_dead:
		_handle_death_or_continue()
	else:
		_add_button("继续修行 →", _continue_or_popup.bind(show_free))

func _finish_hidden_event_safe():
	current_state = State.HIDDEN_RESULT
	story_label.text = "═══ 时光流逝 ═══\n\n（事过境迁，未起波澜）" + _stats_footer()
	_update_stats()
	_clear_choices()
	if _practice_active:
		player.complete_practice()
		_practice_active = false
	_add_button("继续修行 →", show_free)

# ── STATE: TASK_LIST 门派任务列表 ─────────────────────────────

func _on_task_list():
	_show_task_list()

func _show_task_list():
	current_state = State.TASK_LIST
	var header := "═══ 任务委托 ═══\n\n宗门任务报酬稳定；江湖悬赏全员可接。"
	if player.prestige < -50:
		header += "\n⚠ 声名狼藉（声望 %d），宗门任务暂不可接。" % player.prestige
	story_label.text = header
	_update_stats()
	_clear_choices()

	var available: Dictionary = task.get_available_tasks(player)
	var realm_tag     := ["【练气】", "【筑基】", "【金丹】", "【元婴】", "【化神】"]
	var diff_sections := [
		{"key": "easy",   "label": "── 简单委托 ──"},
		{"key": "normal", "label": "── 普通任务 ──"},
		{"key": "hard",   "label": "── 艰难任务 ──"},
	]
	var any_task := false
	for section in diff_sections:
		var diff: String = section["key"]
		var tasks: Array = available[diff]
		if tasks.is_empty():
			continue
		any_task = true
		_add_label(section["label"])
		for t in tasks:
			var realm: int = t.get("realm_required", 0) as int
			var realm_str: String = realm_tag[realm] if realm < realm_tag.size() else ""
			var src_str: String   = "【宗门】" if t.get("source", "") == "宗门任务" else "【悬赏】"
			_add_label(realm_str + src_str + t["text"] + "  耗时 " + str(t["years"]) + " 年\n" + _task_reward_summary(t, diff))
			_add_button("接取任务", _on_task_start.bind(t["id"], diff))
			_add_separator()
	if not any_task:
		_add_label("（暂无适合当前境界的任务）")
	_add_button("返回", show_free)

func _task_reward_summary(t: Dictionary, _difficulty: String) -> String:
	# Rev 4：透明报酬制 — 仅显示 base_reward.gold（保底灵石）
	# 声望、修为、道具、modifier 浮动均不预览（玩家点开任务后在选项按钮上看 modifier）
	var base: Dictionary = t.get("base_reward", {}) as Dictionary
	var g: int = base.get("gold", 0) as int
	return "  灵石 +" + str(g)

func _format_modifier_inline(mod: Dictionary) -> String:
	# Rev 4：选项按钮 / 步内提示用 — 拼接 modifier 五字段非零项
	var parts := PackedStringArray()
	var g: int    = mod.get("gold", 0) as int
	var p: int    = mod.get("prestige", 0) as int
	var c: int    = mod.get("cultivation", 0) as int
	var l: int    = mod.get("lifespan", 0) as int
	var i: String = mod.get("item", "") as String
	if g != 0:
		parts.append("灵石%s%d" % ["+" if g > 0 else "", g])
	if p != 0:
		parts.append("声望%s%d" % ["+" if p > 0 else "", p])
	if c > 0:
		parts.append("修为+%d" % c)
	if l < 0:
		parts.append("寿命%d年" % l)
	if i != "":
		parts.append("获得：" + i)
	if parts.is_empty():
		return ""
	return "  [" + " | ".join(parts) + "]"

func _on_task_start(id: String, difficulty: String):
	# 接取门派任务即恢复心志（mind_used 重置；不增 mind_max — 任务非历练）
	player.mind_used = 0
	task.start_task(id, difficulty)
	match difficulty:
		"easy":
			var final: Dictionary = task.finish_task(player)
			_show_task_result(final)
		"normal": _show_normal_task_situation()
		"hard":   _show_task_step()

# ── STATE: TASK_STORY 任务进行中 ──────────────────────────────

func _show_normal_task_situation():
	current_state = State.TASK_STORY
	var data: Dictionary = task.get_normal_situation_data()
	if data.is_empty():
		show_free()
		return
	story_label.text = "【%s】\n\n%s" % [data["task_text"], data["situation"]]
	_update_stats()
	_clear_choices()
	var choices := data["choices"] as Array
	var indices := range(choices.size())
	indices.shuffle()
	for i in indices:
		var choice := choices[i] as Dictionary
		var mod:  Dictionary = choice.get("modifier", {}) as Dictionary
		var hint: String     = _format_modifier_inline(mod)
		_add_button(choice["text"] + hint, _on_task_choice.bind(i))

func _show_task_step():
	current_state = State.TASK_STORY
	var data: Dictionary = task.get_hard_step_data()
	if data.is_empty():
		show_free()
		return
	var step := data["step"] as Dictionary
	story_label.text = "【%s】\n第 %d / %d 关\n\n%s" % [
		data["task_text"], data["step_index"] + 1, data["total_steps"], step["text"]
	]
	_update_stats()
	_clear_choices()
	var indices := range((step["choices"] as Array).size())
	indices.shuffle()
	for i in indices:
		var choice := (step["choices"] as Array)[i] as Dictionary
		var mod:  Dictionary = choice.get("modifier", {}) as Dictionary
		var hint: String     = _format_modifier_inline(mod)
		_add_button(choice["text"] + hint, _on_task_choice.bind(i))

func _on_task_choice(index: int):
	if current_state != State.TASK_STORY:
		return
	var step_result: Dictionary = task.make_choice(index)
	if step_result.is_empty():
		return
	# Rev 4：lifespan 在 step_result.modifier 嵌套 dict 中
	var mod: Dictionary = step_result.get("modifier", {}) as Dictionary
	var life_cost: int = mod.get("lifespan", 0) as int
	if life_cost < 0:
		player.lifespan += life_cost
		if player.lifespan <= 0:
			current_state = State.TASK_RESULT
			story_label.text = (
				"═══ 任务中断 ═══\n\n" +
				step_result.get("result", "") +
				"\n\n寿命 " + str(life_cost) + " 年\n\n寿命耗尽，任务被迫中止。"
			)
			_update_stats()
			_clear_choices()
			task.abort_current_task()
			_handle_death_or_continue()
			return
	if step_result["is_last"]:
		var final: Dictionary = task.finish_task(player)
		_show_task_result(final)
	else:
		_show_step_transition(step_result)

func _show_step_transition(step_result: Dictionary):
	current_state = State.TASK_STORY
	# Rev 4：本步浮动 = step_result.modifier（嵌套 dict）
	var step_no: int = step_result.get("step", 0) as int
	var mod: Dictionary = step_result.get("modifier", {}) as Dictionary
	var lines := PackedStringArray()
	lines.append("第 %d 关结果" % step_no)
	lines.append("")
	lines.append(step_result.get("result", "") as String)
	lines.append("")
	var earn := PackedStringArray()
	var sg: int    = mod.get("gold", 0) as int
	var sp: int    = mod.get("prestige", 0) as int
	var sc: int    = mod.get("cultivation", 0) as int
	var sl: int    = mod.get("lifespan", 0) as int
	var si: String = mod.get("item", "") as String
	if sg != 0:
		earn.append("灵石 %s%d" % ["+" if sg > 0 else "", sg])
	if sp != 0:
		earn.append("声望 %s%d" % ["+" if sp > 0 else "", sp])
	if sc > 0:
		earn.append("修为 +%d" % sc)
	if si != "":
		earn.append("获得：%s" % si)
	if sl < 0:
		earn.append("寿命 %d 年" % sl)
	if earn.is_empty():
		lines.append("（本步无浮动）")
	else:
		lines.append("本步浮动：" + " | ".join(earn))
	story_label.text = "\n".join(lines)
	_update_stats()
	_clear_choices()
	_add_button("继续下一关 →", _show_task_step)

# ── STATE: TASK_RESULT 任务结算 ───────────────────────────────

func _show_task_result(final: Dictionary):
	current_state = State.TASK_RESULT
	# Rev 4：分三段显示「基础报酬 / 选择浮动 / 总计」
	var base    := final.get("base_reward",    {}) as Dictionary
	var mod_tot := final.get("modifier_total", {}) as Dictionary
	var rewards := final.get("rewards",        {}) as Dictionary

	var text := "═══ 任务结算 ═══\n\n"
	text += "【" + str(final["task_text"]) + "】\n"

	# ─── 基础报酬 ───
	text += "\n─── 基础报酬 ───\n"
	var bg: int    = base.get("gold", 0) as int
	var bp: int    = base.get("prestige", 0) as int
	var bi: String = base.get("item", "") as String
	var has_base := false
	if bg != 0:
		text += "灵石 %s%d\n" % ["+" if bg > 0 else "", bg]
		has_base = true
	if bp != 0:
		text += "声望 %s%d\n" % ["+" if bp > 0 else "", bp]
		has_base = true
	if bi != "":
		text += "保底道具：%s\n" % bi
		has_base = true
	if not has_base:
		text += "（无）\n"

	# ─── 选择浮动 ───
	var mg: int    = mod_tot.get("gold", 0) as int
	var mp: int    = mod_tot.get("prestige", 0) as int
	var mc: int    = mod_tot.get("cultivation", 0) as int
	var ml: int    = mod_tot.get("lifespan", 0) as int
	var mitems: Array = mod_tot.get("items", []) as Array
	var has_mod := mg != 0 or mp != 0 or mc != 0 or ml < 0 or not mitems.is_empty()
	if has_mod:
		text += "\n─── 选择浮动 ───\n"
		if mg != 0:
			text += "灵石 %s%d\n" % ["+" if mg > 0 else "", mg]
		if mp != 0:
			text += "声望 %s%d\n" % ["+" if mp > 0 else "", mp]
		if mc > 0:
			text += "修为 +%d\n" % mc
		if ml < 0:
			text += "寿命 %d 年（步内已即时扣）\n" % ml
		for it in mitems:
			var mri: String = it as String
			if mri != "":
				text += "获得：%s\n" % mri

	# ─── 总计 ───（rewards = base + modifier_total）
	text += "\n─── 总计 ───\n"
	var rg: int = rewards.get("gold", 0) as int
	var rp: int = rewards.get("prestige", 0) as int
	var rc: int = rewards.get("cultivation", 0) as int
	if rg != 0:
		text += "灵石 %s%d\n" % ["+" if rg > 0 else "", rg]
	if rp != 0:
		text += "声望 %s%d\n" % ["+" if rp > 0 else "", rp]
	if rc > 0:
		text += "修为 +%d\n" % rc

	# 道具图鉴登记（不重复输出文本，道具行已在基础/浮动段显示）
	var items_arr: Array = rewards.get("items", []) as Array
	for it in items_arr:
		var ri: String = it as String
		if ri == "":
			continue
		if items_node.on_item_collected(ri):
			_popup_queue.append({"type": "item", "name": ri,
				"desc": items_node.ITEM_META.get(ri, {}).get("desc", "")})

	text += "\n消耗寿命：-%d 年\n" % (final.get("years", 0) as int)

	var cult_overflow: String = final.get("cult_overflow_msg", "") as String
	if cult_overflow != "":
		text += "\n" + cult_overflow + "\n"

	text += _stats_footer()
	story_label.text = text
	_update_stats()
	_clear_choices()
	if final.get("is_dead", false):
		_handle_death_or_continue()
	else:
		_add_button("继续修行 →", _continue_or_popup.bind(show_free))

# ── STATE: MARKET 宝物集市 ────────────────────────────────────

func _on_market():
	if player.prestige < -100:
		_show_black_market()
	else:
		_show_market()

func _show_market():
	current_state = State.MARKET
	story_label.text = (
		"═══ 宝物集市 ═══\n\n" +
		"以灵石兑换宝物，包括消耗品与突破材料。\n" +
		"当前持有：" + str(player.gold) + " 灵石"
	)
	_update_stats()
	_clear_choices()
	for m in MARKET_ITEMS:
		var can_buy = player.gold >= m["price"]
		_add_label("【" + m["name"] + "】" + m["desc"] + "  — " + str(m["price"]) + " 灵石")
		_add_button(
			"购买" + ("" if can_buy else "（灵石不足）"),
			_on_buy_item.bind(m["name"], m["price"]),
			not can_buy
		)
		_add_separator()
	_add_button("返回", show_free)

func _on_buy_item(item_name: String, price: int):
	if player.gold < price:
		return
	player.add_gold(-price)
	player.add_item(item_name)
	items_node.on_item_collected(item_name)
	call_deferred("_show_market")

# ── 黑市 ──────────────────────────────────────────────────────

func _show_black_market():
	current_state = State.MARKET
	story_label.text = (
		"═══ 黑  市 ═══\n\n" +
		"来路不明的货物，价高质劣。\n" +
		"当前持有：" + str(player.gold) + " 灵石\n" +
		"【声望 %d，正规集市已不欢迎你】" % player.prestige
	)
	_update_stats()
	_clear_choices()
	for m in _get_black_market_items():
		var can_buy = player.gold >= m["price"]
		_add_label("【" + m["name"] + "】" + m["desc"] + "  — " + str(m["price"]) + " 灵石")
		_add_button(
			"购买" + ("" if can_buy else "（灵石不足）"),
			_on_buy_black_market_item.bind(m),
			not can_buy
		)
		_add_separator()
	_add_button("返回", show_free)

func _get_black_market_items() -> Array:
	const INFERIOR_PRICES = [0, 400, 800, 1500, 3000, 0]
	const BROKEN_SEALS    = ["", "残缺一阶破境符", "残缺二阶破境符", "残缺三阶破境符", "残缺四阶破境符", "残缺五阶破境符"]
	const BROKEN_PRICES   = [0, 400, 800, 1500, 3000, 5000]
	var bm: Array = [
		{"name": "延寿丹",     "price": 500, "desc": "寿命+50年（价格虚高）",               "instant": false},
		{"name": "劣质延寿丹", "price": 150, "desc": "寿命+15年，服后体质受损（声望-10）",  "instant": true, "lifespan": 15, "prestige": -10},
	]
	var r = player.realm
	var inf = player.REALM_ITEMS_INFERIOR
	if r < inf.size() and inf[r] != "":
		bm.append({"name": inf[r], "price": INFERIOR_PRICES[r],
			"desc": "色泽暗淡，有股怪味。可替代正品突破材料。", "instant": false})
	if r < BROKEN_SEALS.size() and BROKEN_SEALS[r] != "":
		bm.append({"name": BROKEN_SEALS[r], "price": BROKEN_PRICES[r],
			"desc": "符文残缺，突破成功率+10%（正品+20%）。", "instant": false})
	return bm

func _on_buy_black_market_item(m: Dictionary):
	if player.gold < m["price"]:
		return
	player.add_gold(-m["price"])
	if m["instant"]:
		if m.get("lifespan", 0) > 0:
			player.lifespan += m["lifespan"]
			player.lifespan_max = maxi(player.lifespan_max, player.lifespan)
		if m.get("prestige", 0) != 0:
			player.add_prestige(m["prestige"])
	else:
		player.add_item(m["name"])
		items_node.on_item_collected(m["name"])
	call_deferred("_show_black_market")

# ── STATE: STATUS 查看状态 ────────────────────────────────────

func _on_status():
	_show_status()

func _show_status():
	current_state = State.STATUS
	story_label.text = player.get_inventory_text()
	_update_stats()
	_rebuild_status_buttons()

func _rebuild_status_buttons():
	_clear_choices()
	_add_label(items_node.get_collection_text(player))
	_add_separator()
	var usable = ["延寿丹", "一阶破境符", "二阶破境符", "三阶破境符", "四阶破境符", "五阶破境符",
				  "残缺一阶破境符", "残缺二阶破境符", "残缺三阶破境符", "残缺四阶破境符", "残缺五阶破境符",
				  "一阶聚灵丹", "二阶聚灵丹", "三阶聚灵丹", "四阶聚灵丹", "五阶聚灵丹",
				  "青木长生诀", "金阙真经", "太上忘情诀", "紫府混元图", "九转化神录",
				  "小气运丹", "中气运丹", "大气运丹"]
	for item_name in usable:
		if player.has_item(item_name):
			_add_button("使用【" + item_name + "】", _on_use_item.bind(item_name))
	_add_button("返回", show_free)

func _on_use_item(item_name: String):
	var msg = player.use_item(item_name)
	story_label.text = "═══ 宝物图鉴 ═══\n\n" + msg
	_update_stats()
	_rebuild_status_buttons()

# ── 尝试突破 ──────────────────────────────────────────────────

func _on_try_breakthrough():
	var err = player.can_try_breakthrough()
	if err != "":
		_show_result("═══ 突破尝试 ═══\n\n" + err + _stats_footer(), false)
		return
	_show_breakthrough_vision()

func _show_breakthrough_vision():
	current_state = State.BREAKTHROUGH_VISION
	var idx = mini(player.realm, BREAKTHROUGH_VISION_TEXT.size() - 1)
	var next_realm = player.REALMS[player.realm + 1] if player.realm + 1 < player.REALMS.size() else "飞升"
	story_label.text = "═══ 冲击 %s ═══\n\n%s" % [next_realm, BREAKTHROUGH_VISION_TEXT[idx]]
	_update_stats()
	_clear_choices()
	_add_button("凝神应劫 →", _show_breakthrough_minigame)

func _pick_breakthrough_minigame() -> Node:
	var tier: String = "qiqi"
	if player.realm > 2:
		tier = "jindan"
	elif player.realm > 0:
		tier = "zhuji"
	var kind: int = randi() % 5   # 0=memory, 1=minesweeper, 2=sudoku, 3=numchain, 4=oddone
	var preset: Dictionary
	var mg: Node
	match kind:
		0:
			preset = MinigameMemory.preset_qiqi() if tier == "qiqi" else (MinigameMemory.preset_zhuji() if tier == "zhuji" else MinigameMemory.preset_jindan())
			mg = MinigameMemory.new()
		1:
			preset = MinigameMinesweeper.preset_qiqi() if tier == "qiqi" else (MinigameMinesweeper.preset_zhuji() if tier == "zhuji" else MinigameMinesweeper.preset_jindan())
			mg = MinigameMinesweeper.new()
		2:
			preset = MinigameSudoku.preset_qiqi() if tier == "qiqi" else (MinigameSudoku.preset_zhuji() if tier == "zhuji" else MinigameSudoku.preset_jindan())
			mg = MinigameSudoku.new()
		3:
			preset = MinigameNumChain.preset_qiqi() if tier == "qiqi" else (MinigameNumChain.preset_zhuji() if tier == "zhuji" else MinigameNumChain.preset_jindan())
			mg = MinigameNumChain.new()
		_:
			preset = MinigameOddOne.preset_qiqi() if tier == "qiqi" else (MinigameOddOne.preset_zhuji() if tier == "zhuji" else MinigameOddOne.preset_jindan())
			mg = MinigameOddOne.new()
	mg.configure(preset)
	return mg

func _show_breakthrough_minigame():
	var next_realm = player.REALMS[player.realm + 1] if player.realm + 1 < player.REALMS.size() else "飞升"
	# 进入独立全屏界面
	if main_root != null and overlay_root != null:
		main_root.visible = false
		_clear_overlay()
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", UITheme.VBOX_SEP)
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var title := Label.new()
		title.text = "═══ %s 之劫 ═══" % next_realm
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", UITheme.FONT_EMPHASIS)
		vbox.add_child(title)
		vbox.add_child(HSeparator.new())
		var scroll := ScrollContainer.new()
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		var center := CenterContainer.new()
		center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		center.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var mg = _pick_breakthrough_minigame()
		mg.minigame_completed.connect(_on_breakthrough_logic)
		center.add_child(mg)
		scroll.add_child(center)
		vbox.add_child(scroll)
		overlay_root.add_child(vbox)
		overlay_root.visible = true
	else:
		# fallback：旧路径，保险起见
		story_label.text = "═══ %s 之劫 ═══" % next_realm
		stats_label.visible = false
		_clear_choices()
		var mg = _pick_breakthrough_minigame()
		mg.minigame_completed.connect(_on_breakthrough_logic)
		choices_box.add_child(mg)

func _clear_overlay() -> void:
	if overlay_root == null:
		return
	for child in overlay_root.get_children():
		child.queue_free()

func _on_breakthrough_logic(result: String) -> void:
	# 退出独立界面
	if overlay_root != null:
		overlay_root.visible = false
		_clear_overlay()
	if main_root != null:
		main_root.visible = true
	stats_label.visible = true
	var force = 1 if result == "pass" else -1
	_breakthrough_data = player.try_breakthrough(force)
	_show_breakthrough_result()

func _do_breakthrough():
	_breakthrough_data = player.try_breakthrough()
	_show_breakthrough_result()

func _show_breakthrough_result():
	current_state = State.BREAKTHROUGH_RESULT
	var d = _breakthrough_data
	var text = "═══ 突破结果 ═══\n\n"
	if d["success"]:
		var note = "（破境符加持）" if d["had_boost"] else ""
		if d.get("used_inferior", false): note += "（怪味材料，险中求胜）"
		text += "✨ 突破成功！晋升%s！%s\n寿命+%d 年（当前寿命 %d 年）！\n" % [
			player.REALMS[d["realm_to"]], note, d["lifespan_gain"], player.lifespan
		]
		if not d["insight_bonus"].is_empty():
			var ib = d["insight_bonus"]
			text += "\n✨ 此番突破另有所得：声望+%d，获得【%s】\n" % [ib["prestige"], ib["item"]]
		# 编年史：突破成功 entry
		player.add_life_entry(player.age, player.age, "breakthrough",
			"突破至%s境界，寿元 +%d 年。" % [player.REALMS[d["realm_to"]], d["lifespan_gain"]])
	else:
		var note = "破境符效果随之消散。" if d["had_boost"] else ""
		if d["item_consumed"] != "":
			text += "💀 突破失败！走火入魔，寿命-15年，【%s】随之损毁。%s\n" % [d["item_consumed"], note]
		else:
			text += "💀 突破失败！走火入魔，寿命-15年。%s\n" % note
	text += _stats_footer()
	story_label.text = text
	_update_stats()
	_clear_choices()
	var is_dead = player.lifespan <= 0
	if is_dead:
		_handle_death_or_continue()
	elif d["success"] and d["realm_to"] >= player.REALMS.size() - 1:
		# 突破至飞升 — 走专属飞升结局，绕过常规反应屏
		_add_button("撕开虚空，飞升 →", _show_ascension)
	elif d["success"]:
		_add_button("世人皆知 →", _show_breakthrough_reaction)
	else:
		_add_button("舔舐伤口 →", _continue_or_popup.bind(show_free))

func _show_breakthrough_reaction():
	current_state = State.BREAKTHROUGH_REACTION
	var text = "═══ 四方反应 ═══\n\n"
	if player.prestige >= 80:
		text += "你的名号早已在坊市间传开，邻峰某散修听闻此讯，登门拜贺，寒暄一番，颇为恭敬。\n"
	elif player.prestige >= 0:
		text += "坊市间你的名号悄悄流传，旁人提及时语气里多了几分敬意，但也仅此而已。\n"
	else:
		text += "你境界已成，外界却无人来贺。坊市里偶有提及，多是一句\"那家伙居然没死\"，便不再多言。\n"
	text += _stats_footer()
	story_label.text = text
	_update_stats()
	_clear_choices()
	_add_button("继续修行 →", func(): _continue_or_popup(func(): _start_hex_draw("breakthrough", show_free)))

# ── STATE: HEX_DRAW / HEX_RESULT 海克斯抽取 ────────────────────
#  触发：开局拜入宗门 / 选择散修后；突破成功（非飞升）后
#  无刷新；3 个选项必选其一
func _start_hex_draw(timing: String, next_cb: Callable):
	if hex == null:
		next_cb.call()
		return
	if player.realm >= player.REALMS.size() - 1:
		# 飞升状态保险：不抽海克斯，直走 next
		next_cb.call()
		return
	var tier: String = hex.draw_tier()
	var options: Array = hex.draw_options(tier, player)
	if options.is_empty():
		next_cb.call()
		return
	_show_hex_options(tier, options, timing, next_cb)

func _show_hex_options(tier: String, options: Array, timing: String, next_cb: Callable):
	current_state = State.HEX_DRAW
	var tier_label: String = hex.TIER_LABELS.get(tier, tier)
	var timing_label: String = "突破之后" if timing == "breakthrough" else "踏入修行之初"
	var text = "═══ 海克斯 · " + tier_label + "档 ═══\n\n"
	text += "（" + timing_label + "天地垂下一线机缘，三选其一，无法刷新）\n\n"
	for h in options:
		text += "▸【" + tier_label + "】" + h["name"] + "  · " + h["category"] + "类\n"
		text += "    " + h["blurb"] + "\n\n"
	story_label.text = text
	_update_stats()
	_clear_choices()
	for h in options:
		var btn_text: String = "选【" + h["name"] + "】 — " + _hex_effect_brief(h)
		_add_button(btn_text, _on_hex_pick.bind(h, next_cb))

func _hex_effect_brief(h: Dictionary) -> String:
	var parts: Array = []
	for e in h["effects"]:
		match e["type"]:
			"gold":               parts.append("灵石+" + str(int(e["value"])))
			"cult_pct":           parts.append("修为+本境界" + str(int(e["value"])) + "%")
			"talent_speed":       parts.append("修行天赋+" + str(int(e["value"])))
			"talent_luck":        parts.append("气运+" + str(int(e["value"])))
			"qiyun":              parts.append("气运+" + str(int(e["value"])))
			"item":               parts.append("获得【" + str(e["value"]) + "】")
			"item_realm_juling":  parts.append("获得当前境界聚灵丹")
			"item_realm_pojing":  parts.append("获得当前境界破境符")
	return "，".join(parts)

func _on_hex_pick(h: Dictionary, next_cb: Callable):
	var msgs: Array = hex.apply(h, player, items_node)
	_show_hex_result(h, msgs, next_cb)

func _show_hex_result(h: Dictionary, msgs: Array, next_cb: Callable):
	current_state = State.HEX_RESULT
	var text = "═══ 海克斯铭刻 ═══\n\n"
	text += "你选择了【" + h["name"] + "】。\n"
	text += h["blurb"] + "\n\n"
	for m in msgs:
		text += "  · " + m + "\n"
	text += _stats_footer()
	story_label.text = text
	_update_stats()
	_clear_choices()
	_add_button("继续修行 →", _continue_or_popup.bind(next_cb))

# ── STATE: RESULT 结算界面 ────────────────────────────────────

func _show_result(text: String, is_dead: bool):
	current_state = State.RESULT
	story_label.text = text
	_update_stats()
	_clear_choices()
	if is_dead:
		_handle_death_or_continue()
	else:
		_add_button("继续修行 →", _continue_or_popup.bind(show_free))

# ── STATE: GAMEOVER 寿终界面 ──────────────────────────────────

# ── 解锁弹窗队列 ─────────────────────────────────────────────────

func _continue_or_popup(next_cb: Callable):
	if _popup_queue.is_empty():
		next_cb.call()
		return
	var popup = _popup_queue.pop_front()
	current_state = State.RESULT
	var name = popup.get("name", "")
	var desc = popup.get("desc", "")
	story_label.text = "★★★ 首得宝物 ★★★\n\n【%s】\n%s" % [name, desc]
	_clear_choices()
	_add_button("铭记于心 →", _continue_or_popup.bind(next_cb))

func _show_gameover():
	current_state = State.GAMEOVER
	# 编年史：死亡 entry
	player.add_life_entry(player.age, player.age, "death",
		"寿元耗尽于" + player.get_realm_name() + "，化作一缕青烟。")
	story_label.text = (
		"═══ 寿终正寝 ═══\n\n" +
		"你在" + player.get_realm_name() + "境界耗尽了最后的寿元，\n" +
		"化作一缕青烟，飘散于天地之间。\n\n" +
		_build_life_summary() +
		"─── 最终成就 ───\n\n" +
		player.get_detail_text() + "\n\n" +
		items_node.get_collection_text(player)
	)
	_clear_choices()
	_add_button("回望来世遗赠 →", _show_reincarnation_choice)

# ── STATE: REINCARNATION_CHOICE 死亡后的来世遗赠分支选择 ─────

func _show_reincarnation_choice():
	current_state = State.REINCARNATION_CHOICE
	var opts: Dictionary = reincarnation.get_death_options(player)
	var text = "═══ 来世遗赠 ═══\n\n"
	text += "你死于【%s】，可在此生功业中铭刻一道印记，传予来世。\n" % opts["realm_name"]
	text += "（每次死亡仅可选一项；累加跨局；放弃则保留原状）\n\n"
	text += reincarnation.get_status_text() + "\n\n"
	text += "─── 此次可选 ───"
	story_label.text = text
	_clear_choices()
	var pts: int = int(opts["points"])
	var gld: int = int(opts["gold"])
	var lck: int = int(opts["luck"])
	_add_button("天赋点 +%d" % pts, _on_reincarnation_pick.bind("talent", opts), pts <= 0)
	_add_button("灵石继承 +%d　（死亡灵石 ×10%%）" % gld, _on_reincarnation_pick.bind("gold", opts), gld <= 0)
	_add_button("气运 +%d" % lck, _on_reincarnation_pick.bind("luck", opts), lck <= 0)
	_add_separator()
	_add_button("放弃遗赠，清白转世", _on_reincarnation_pick.bind("skip", opts))

func _on_reincarnation_pick(choice: String, opts: Dictionary):
	reincarnation.commit_death_choice(choice, opts)
	_on_restart()

# ── STATE: ASCENSION 飞升结局（化神 → 飞升突破成功专属）─────

func _show_ascension():
	current_state = State.ASCENSION
	# 编年史：飞升 entry（覆盖普通 breakthrough 记录的语气）
	player.add_life_entry(player.age, player.age, "breakthrough",
		"化神圆满之际破碎虚空，飞升仙界。")
	var grant: Dictionary = reincarnation.get_ascension_grant(player)
	var text = "═══ 飞升 ═══\n\n"
	text += "化神圆满，天劫降临。你迎着九重雷火撕开虚空，\n"
	text += "踏出此界。一念万年，再回首已是仙人之姿。\n\n"
	text += _build_life_summary()
	text += "─── 大道功成 ───\n\n"
	text += player.get_detail_text() + "\n\n"
	text += items_node.get_collection_text(player) + "\n"
	text += "─── 来世遗赠（飞升全拿）───\n"
	text += "【天赋点】+%d\n" % int(grant["points"])
	text += "【灵石继承】+%d　（灵石 ×100%%）\n" % int(grant["gold"])
	text += "【气运】+%d\n\n" % int(grant["luck"])
	text += reincarnation.get_status_text() + "\n（飞升后转世计数重置）"
	story_label.text = text
	_clear_choices()
	_add_button("一并铭刻，重启轮回", _on_ascension_commit.bind(grant))

func _on_ascension_commit(grant: Dictionary):
	reincarnation.commit_ascension(grant)
	_on_restart()

# ── 编年史辅助 ────────────────────────────────────────────────

func _format_life_log() -> String:
	if player.life_log.is_empty():
		return "═══ 编年史 ═══\n\n（暂无记载）"
	var s: String = "═══ " + str(player.player_name) + " 的编年史 ═══\n\n"
	for e in player.life_log:
		var age_str: String
		if int(e["age_start"]) == int(e["age_end"]):
			age_str = "%d 岁" % int(e["age_start"])
		else:
			age_str = "%d-%d 岁" % [int(e["age_start"]), int(e["age_end"])]
		s += "▸ %s：%s\n\n" % [age_str, str(e["text"])]
	return s

func _build_life_summary() -> String:
	if player.life_log.is_empty():
		return ""
	var s: String = "─── 此生 ───\n\n"
	for e in player.life_log:
		var age_str: String
		if int(e["age_start"]) == int(e["age_end"]):
			age_str = "%d 岁" % int(e["age_start"])
		else:
			age_str = "%d-%d 岁" % [int(e["age_start"]), int(e["age_end"])]
		s += "▸ %s：%s\n" % [age_str, str(e["text"])]
	return s + "\n"

func _on_chronicle() -> void:
	current_state = State.CHRONICLE
	story_label.text = _format_life_log()
	_update_stats()
	_clear_choices()
	_add_button("返回", show_free)

func _on_restart():
	get_tree().reload_current_scene()

func _process(delta: float) -> void:
	if current_state == State.EXAM_CAOMEN:
		_caomen_elapsed += delta
		if _caomen_elapsed >= 30.0:
			_show_exam_result(true)
		return
	if current_state != State.EXAM_MINIGAME:
		return
	_exam_elapsed += delta
	_exam_wave += sin(_exam_elapsed * 1.3) * 2.5 * delta
	_exam_wave += randf_range(-1.5, 1.5) * 20.0 * delta
	_exam_wave = clamp(_exam_wave, 0.0, 100.0)
	var in_zone: bool = _exam_wave >= 35.0 and _exam_wave <= 65.0
	if in_zone:
		_exam_stable_time += delta
	if is_instance_valid(_exam_bar):
		_exam_bar.value = _exam_wave
	if is_instance_valid(_exam_status_lbl):
		_exam_status_lbl.text = "▮ 灵力平稳" if in_zone else "▯ 灵力波动！"
	if is_instance_valid(_exam_time_lbl):
		_exam_time_lbl.text = "平稳：%.1fs / 需20s   剩余：%.1fs" % [_exam_stable_time, 30.0 - _exam_elapsed]
	var unstable: float = _exam_elapsed - _exam_stable_time
	if unstable > 10.0:
		_cleanup_exam_wave_ui()
		_show_exam_result(false, "part2")
		return
	if _exam_elapsed >= 30.0:
		_cleanup_exam_wave_ui()
		if _exam_stable_time >= 20.0:
			_show_exam_logic()
		else:
			_show_exam_result(false, "part2")
