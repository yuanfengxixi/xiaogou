extends Node

# ══════════════════════════════════════════════════════════════
#  困难任务 handler (Rev 4 透明报酬制)
#  执行流程：接取 → 多步情境 → 玩家逐步选择 → 各步 modifier 累加进 _acc_mod_*
#  finish: final = base_reward + Σ chosen.modifier，一次性发放并 pass_time(years)
#  无 outcome 三档评分。无 score / thresholds 概念。
#  数据 schema: TASKS[i].base_reward + TASKS[i].steps[j].choices[k].modifier
#  小游戏 Phase 1 全空（minigame=""）。Phase 2 接入。
# ══════════════════════════════════════════════════════════════

const TASKS: Array = [
	# ── 衍天宗 ── 化神师叔之劫（金丹，3 步，base 1300/16）─────────
	{
		"id":             "th_xt_jindan",
		"text":           "化神师叔之劫",
		"desc":           "师叔冲击化神之劫，命你执掌护法阵眼。雷威如海，阵眼如针。",
		"source":         "宗门任务",
		"realm_required": 2,
		"years":          20,
		"base_reward":    {"gold": 1300, "prestige": 16, "cultivation": 0, "lifespan": 0, "item": ""},
		"steps": [
			{
				"text":     "雷劫将至，护法阵眼有十二处。师叔扫了你一眼，意思是：你自己挑。靠风口的位置压力最大，但也最显能力；外围位最安稳，但事后没人记你的功劳。",
				"minigame": "",
				"choices": [
					{"text": "立在最靠风口的位置。", "result": "你站在阵眼第一线。师叔难得点了点头：『有种。』雷劫开始前的两个时辰，你已经能感受到雷气如刀刮面。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
					{"text": "立外围位，安稳第一，闲时偷修。", "result": "你站在外围阵眼。雷劫起前的几个月里清修不辍，金丹中期门径稳固了几分。师叔走过看了你一眼，没说话。", "modifier": {"gold": 0, "prestige": -7, "cultivation": 90, "lifespan": 0, "item": ""}},
					{"text": "立次位，但悄悄在阵盘下藏一道盗气符。", "result": "你站在中等阵眼。盗气符布得隐蔽，雷劫开始前没有被发现。但你心里清楚——师叔事后若起疑，第一个查的就是你这种位置。", "modifier": {"gold": 40, "prestige": -12, "cultivation": 0, "lifespan": 0, "item": ""}}
				]
			},
			{
				"text":     "九霄之雷落下时，三道偏雷直奔你的方位。师叔分身乏术，无暇顾及外围。",
				"minigame": "",
				"choices": [
					{"text": "上前接雷，硬扛。", "result": "三道偏雷你接下了两道，第三道偏出阵外。代价是肩头一道焦痕，咳了三个月血。但师叔回头看了你一眼，那一眼分量很重。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": -3, "item": ""}},
					{"text": "用储物符化形撤离阵眼三息。", "result": "三道偏雷无人接，自行散去，所幸未伤要害。你回到阵眼时师叔余光扫了一下，没说话——但他记下了。", "modifier": {"gold": 0, "prestige": -7, "cultivation": 0, "lifespan": 0, "item": ""}},
					{"text": "趁阵眼混乱抢一缕雷威炼入丹田。", "result": "你抢到一缕雷威，灼伤经脉但收益不小。三道偏雷全部偏出阵外伤了一名同门。事后他没说话，但他也记下了。", "modifier": {"gold": 40, "prestige": -12, "cultivation": 0, "lifespan": -2, "item": ""}}
				]
			},
			{
				"text":     "师叔渡劫成功，回身扫视阵眼。雷劫余威之中，几面阵盘已经损毁。",
				"minigame": "",
				"choices": [
					{"text": "如实整理阵盘，损毁一一上交。", "result": "师叔点头：『这次的事我记下了。』他递给你一面破境符，是衍天宗炼制的好货。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": "三阶破境符"}},
					{"text": "悄悄将一面尚可使用的破阵盘藏入袖中。", "result": "你私藏的阵盘，回去后炼化成了一道残缺破境符。师叔事后清点似乎察觉，但未深究。", "modifier": {"gold": 140, "prestige": -10, "cultivation": 0, "lifespan": 0, "item": "残缺三阶破境符"}},
					{"text": "向师叔哭诉『差点死了』，求一份额外赏赐。", "result": "师叔皱了皱眉，递给你一袋灵石，话只一句：『下次别哭。』", "modifier": {"gold": 100, "prestige": -7, "cultivation": 0, "lifespan": 0, "item": ""}}
				]
			}
		]
	},

	# ── 修罗门 ── 屠灭叛门支系（金丹，3 步，base 2400/9，base.gold ×1.5 vs 守一同境界 1600）
	{
		"id":             "th_xl_jindan",
		"text":           "屠灭叛门支系",
		"desc":           "修罗门一支外门叛投正道。门主递黑铁刀给你，话只一句：『一个不留。』",
		"source":         "宗门任务",
		"realm_required": 2,
		"years":          22,
		"base_reward":    {"gold": 2400, "prestige": 9, "cultivation": 0, "lifespan": 0, "item": ""},
		"steps": [
			{
				"text":     "你带队抵达叛门所在的山头。叛门约二十余修士，金丹一名，余皆筑基。山门紧闭，气氛紧绷。",
				"minigame": "",
				"choices": [
					{"text": "正面破门，直接攻入。", "result": "你一脚踹开山门，黑铁刀光过处血溅三步。叛门金丹首领反应过来时已经晚了。代价是肩头被一道符箓划伤，三月才愈。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": -3, "item": ""}},
					{"text": "围而不攻，子夜偷袭。期间血气炼入功法。", "result": "三日围困，子夜出手。叛门弟子大半在睡梦中被斩杀。期间血气炼入修罗门功法，金丹中期境界稳了不少。", "modifier": {"gold": 0, "prestige": -5, "cultivation": 90, "lifespan": 0, "item": ""}},
					{"text": "围困三日，宣告『投降则不杀』。", "result": "六个外门弟子率先出降。剩余顽抗者全数枭首，金丹首领被擒。门主对你的处理方式没有褒贬，但收编六人入修罗门外门，是实实在在的好处。", "modifier": {"gold": 0, "prestige": -2, "cultivation": 0, "lifespan": 0, "item": ""}}
				]
			},
			{
				"text":     "叛门金丹首领被擒。你看着他跪在你面前，他口中犹自咒骂修罗门。",
				"minigame": "",
				"choices": [
					{"text": "黑铁刀过去，了断。", "result": "一刀过去，事干净。门主对你的处理方式很满意：『修罗门的人，就该这样。』", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
					{"text": "拷问三日，逼出更多隐秘。", "result": "三日下来，你从他嘴里挖出了正道方面的两条暗线。门主当夜便堵上。这种事在修罗门——不奖也不罚。", "modifier": {"gold": 0, "prestige": -3, "cultivation": 0, "lifespan": 0, "item": ""}},
					{"text": "索其身上财宝放他一条生路。", "result": "他递了一袋灵石给你，悄悄从后山遁走。你回报『已了结』。但江湖太小——他若有一日再现身，门主第一个查的就是你。", "modifier": {"gold": 50, "prestige": -10, "cultivation": 0, "lifespan": 0, "item": ""}}
				]
			},
			{
				"text":     "山头的事了。班师回门时，叛门积攒的灵材、丹药、法器堆了几车。",
				"minigame": "",
				"choices": [
					{"text": "一切按规矩呈报，分毫不留。", "result": "门主翻看清单，眉毛动了动：『你这种人在修罗门里少。』他递给你一面破境符。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": "三阶破境符"}},
					{"text": "私吞首领的几件珍宝，账上写『已毁于战火』。", "result": "你私吞了一件半成品破境符。门主验账时没有当场翻脸——但修罗门里这种事，门主的脾气你早就该知道。", "modifier": {"gold": 50, "prestige": -10, "cultivation": 0, "lifespan": 0, "item": "残缺三阶破境符"}},
					{"text": "顺路灭口几个目击此事的散修。", "result": "三个散修无声无息消失在江湖里。账面上比你预期多了五十枚灵石。但江湖里这种事会传——只是慢一些。", "modifier": {"gold": 0, "prestige": -6, "cultivation": 0, "lifespan": 0, "item": ""}}
				]
			}
		]
	},

	# ── 青云宗 ── 仙凡瘟疫救济（元婴，3 步，base 4000/27）────────
	{
		"id":             "th_qy_yuanying",
		"text":           "仙凡瘟疫救济",
		"desc":           "仙凡交界的县城爆发瘟疫，连修士都未能幸免。青云宗派你前去查源。",
		"source":         "宗门任务",
		"realm_required": 3,
		"years":          25,
		"base_reward":    {"gold": 4000, "prestige": 27, "cultivation": 0, "lifespan": 0, "item": ""},
		"steps": [
			{
				"text":     "你抵达县城。城门紧闭，街上只有几个戴口罩的差役。瘟疫已经蔓延半年，死者两千余，其中包括三个筑基期散修。",
				"minigame": "",
				"choices": [
					{"text": "公开身份入城调查，与县衙合作。", "result": "你与县衙一起设立隔离区，调查源头。县衙调集所有人手协助你，效率极高，但你也吸入了一些瘟疫之气，元婴本元受了一点伤。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": -2, "item": ""}},
					{"text": "暗中调查，潜入下水道与坟场追踪源头。期间静修。", "result": "你查到瘟疫源头一线，但耗费时日不少。期间在城郊野地静修，元婴中期境界长进不少。", "modifier": {"gold": 0, "prestige": -11, "cultivation": 250, "lifespan": 0, "item": ""}},
					{"text": "请求县衙强制隔离全城。", "result": "强制隔离令下，疫情蔓延减缓，但百姓怨言不少。县令扛了骂名，事后却给青云宗送了感谢状。", "modifier": {"gold": 0, "prestige": -4, "cultivation": 0, "lifespan": 0, "item": ""}}
				]
			},
			{
				"text":     "瘟疫源头查到了——一名邪修在城郊废宅圈养十二个孩童作灵蛊母体。每个月放出一只蛊虫，借瘟疫之名收魂。",
				"minigame": "",
				"choices": [
					{"text": "降服邪修，孩童送官救治。", "result": "邪修被你封印送回宗门处置。十二个孩童救活了九个。县城瘟疫一月内消散。这是你修仙以来最干净的一次了断。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
					{"text": "杀邪修，封灵蛊为己用。", "result": "你将那十二只灵蛊封入符箓。邪修被斩于阵前。九个孩童救活，但其中三个永久残疾。封蛊符你藏在袖中，没让人看见——但你心里清楚。", "modifier": {"gold": 40, "prestige": -16, "cultivation": 0, "lifespan": 0, "item": "残缺四阶破境符"}},
					{"text": "通报宗门请援，留待处置。", "result": "青云宗派来三位元婴长老共同处置。邪修被擒，孩童全部救活。功劳由长老们均分，你只得了寻常一份——但安稳。", "modifier": {"gold": 0, "prestige": -3, "cultivation": 0, "lifespan": 0, "item": ""}}
				]
			},
			{
				"text":     "瘟疫平息。县城一片狼藉。死者两千余，孤儿数百。",
				"minigame": "",
				"choices": [
					{"text": "留下一年安抚百姓，资助孤儿入药堂。", "result": "县城百姓为青云宗立了一座生祠。长老听闻颇为满意，给你递来一面破境符。一年的功夫不算亏。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": "四阶破境符"}},
					{"text": "事毕回门述职，不留下。", "result": "你按时回门述职。长老看了报告：『还行。』话不多。", "modifier": {"gold": 0, "prestige": -11, "cultivation": 0, "lifespan": 0, "item": ""}},
					{"text": "接受当地几个家族的感谢『仪程』。", "result": "三家大族各送来一袋灵石，加起来四十枚。事情压住没声张，但县城里有人开始嘀咕青云宗的弟子。", "modifier": {"gold": 40, "prestige": -16, "cultivation": 0, "lifespan": 0, "item": ""}}
				]
			}
		]
	},

	# ── 草门 ── 寻访失踪长老（元婴，4 步，base 4000/36）──────────
	{
		"id":             "th_cm_yuanying",
		"text":           "寻访失踪长老",
		"desc":           "草门一位元婴长老十年前下山起卦，至今未归。门主给你一个旧布袋，让你去找。",
		"source":         "宗门任务",
		"realm_required": 3,
		"years":          30,
		"base_reward":    {"gold": 4000, "prestige": 36, "cultivation": 0, "lifespan": 0, "item": ""},
		"steps": [
			{
				"text":     "门主递的旧布袋里有几片龟甲、一卷残破签筒、一封写了一半的信。门主说：『起卦自己定方位。』他向来不解释。",
				"minigame": "",
				"choices": [
					{"text": "正经起卦三日三夜。", "result": "卦象指向千里之外某座废观。卦象之准让你自己都觉得心惊。门内长老见你卦法精进，赞了一句。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
					{"text": "随便摇了摇签就出门，路上自己琢磨方位。期间偷修。", "result": "卦象不准，你绕了千里弯路。但途中偷修元婴功法摸到一线大成。", "modifier": {"gold": 0, "prestige": -11, "cultivation": 250, "lifespan": 0, "item": ""}},
					{"text": "拜请同门帮算，自己跟着走。", "result": "同门给你卜了一卦，方位准确。你按卦象出门，事半功倍。但同门事后向你索了二十枚灵石作酬。", "modifier": {"gold": 20, "prestige": -12, "cultivation": 0, "lifespan": 0, "item": ""}}
				]
			},
			{
				"text":     "卦象指向的方位附近有座小城。要找十年前的踪迹，得从茶馆酒肆里翻。",
				"minigame": "",
				"choices": [
					{"text": "逐家茶馆听闻三个月，慢工细活。", "result": "你听到了三件相关线索，拼起来指向城外一座旧观。茶馆掌柜们都念你客气，临行还有人送你一坛酒。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
					{"text": "找几个酒鬼套话，灌他们三天。", "result": "醉话里夹了一点真东西，方位虽然差了一些但大体对。酒鬼们后来传说草门的弟子很会喝。", "modifier": {"gold": 0, "prestige": -10, "cultivation": 0, "lifespan": 0, "item": ""}},
					{"text": "雇当地地痞代为打探。", "result": "地痞拿了你三十灵石，给你拼凑了几条真假参半的消息。能用，但有水分。", "modifier": {"gold": 30, "prestige": -14, "cultivation": 0, "lifespan": 0, "item": ""}}
				]
			},
			{
				"text":     "线索指向城外一座旧观。观中阴气甚重，似乎有元婴级别的禁制余痕。",
				"minigame": "",
				"choices": [
					{"text": "单身入观。", "result": "观内确有阴邪之物盘踞，被你以草门玄法降服。你在地宫角落找到了长老的遗骨，怀中还揣着一张未画完的卦图。途中受了一道伤，咳了两个月血。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": -3, "item": ""}},
					{"text": "邀同门策应，分队入观。", "result": "三人入观，配合默契。阴邪降服得干净利落。同门各得一份功劳，你也省了不少力气。", "modifier": {"gold": 0, "prestige": -4, "cultivation": 0, "lifespan": 0, "item": ""}},
					{"text": "派同门入观自己殿后。", "result": "同门入观时折了一条胳膊。你殿后无伤，事后他没说什么。但草门里这种事——同门记你，长老也记你。", "modifier": {"gold": 30, "prestige": -14, "cultivation": 0, "lifespan": 0, "item": ""}}
				]
			},
			{
				"text":     "长老遗骨找到了，怀中还有一卷未完之卦、一面半残的草门法器。",
				"minigame": "",
				"choices": [
					{"text": "完整带回宗门。", "result": "门主接过遗骨良久无言。半残法器后来被门主炼为聚灵丹一颗赠你。门内对你刮目相看。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": "四阶聚灵丹"}},
					{"text": "带回部分遗骨，私藏长老的法器。", "result": "你私藏的法器后来炼成一道残缺破境符。门主接过遗骨眼神微动，但未点破。草门里这种事——门主从不当场翻脸。", "modifier": {"gold": 40, "prestige": -16, "cultivation": 0, "lifespan": 0, "item": "残缺四阶破境符"}},
					{"text": "假报『遍寻不获』，遗骨就地葬了。", "result": "你回门复命，门主只问了一句『真的没有？』你说没有。他没追问。但草门里这种事，瞒得过初一瞒不过十五。", "modifier": {"gold": 0, "prestige": -12, "cultivation": 0, "lifespan": 0, "item": ""}}
				]
			}
		]
	},

	# ── 守一门 ── 祖传大阵修复（金丹，3 步，base 1600/27）────────
	{
		"id":             "th_sy_jindan",
		"text":           "祖传大阵修复",
		"desc":           "守一门祖传大阵年久失修，需金丹修士主持十八年的镇守与修复。",
		"source":         "宗门任务",
		"realm_required": 2,
		"years":          18,
		"base_reward":    {"gold": 1600, "prestige": 27, "cultivation": 0, "lifespan": 0, "item": ""},
		"steps": [
			{
				"text":     "守一门祖传大阵铺设在宗门正下方的灵脉之上。年代久远，许多阵基隐患难以肉眼分辨。",
				"minigame": "",
				"choices": [
					{"text": "一寸一寸排查阵基，整三年不出地宫。", "result": "三年下来，你查出十七处隐患，全部标记上呈。账房师叔少见地说了一句：『有用心。』", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
					{"text": "大致看过即修，期间偷修自己功法。", "result": "查出五处明显隐患，余下未察。期间偷修金丹后期门径稳了几分。账房师叔翻了翻你的记录册，没说话。", "modifier": {"gold": 0, "prestige": -11, "cultivation": 90, "lifespan": 0, "item": ""}},
					{"text": "找凡人工匠帮忙排查阵基。", "result": "工匠们认真排查了几月，但凡人毕竟不识阵理。最后查出六处，付了工匠三十灵石。", "modifier": {"gold": 35, "prestige": -16, "cultivation": 0, "lifespan": 0, "item": ""}}
				]
			},
			{
				"text":     "阵纹补刻是细活。每一笔都关系到未来百年的稳定。",
				"minigame": "",
				"choices": [
					{"text": "一笔一笔精刻，七年成。", "result": "阵纹补刻完毕，账房师叔验阵时点头：『这就是守一门的样子。』他难得多说了一句话。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
					{"text": "按旧迹大致刻，五年完工。", "result": "阵纹补完，能用，但有几处刻痕略浅。账房师叔验过：『也行。』话很短。", "modifier": {"gold": 0, "prestige": -10, "cultivation": 0, "lifespan": 0, "item": ""}},
					{"text": "偷工，刻一半留一半，账面上写『已完工』。", "result": "三十五枚灵石省下来入袋。账房师叔表面验过没问题——但他事后悄悄又让人查了一遍。你不知道。", "modifier": {"gold": 35, "prestige": -15, "cultivation": 0, "lifespan": 0, "item": ""}}
				]
			},
			{
				"text":     "大阵开运是最后一步。运转期间灵脉之力如奔流，处置不当就是毁阵。",
				"minigame": "",
				"choices": [
					{"text": "谨慎开运三日三夜，亲自坐镇阵心。", "result": "大阵稳稳启动，灵脉之力流转通顺。账房师叔送来一面破境符：『这是门主的意思。』", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": "三阶破境符"}},
					{"text": "一开了之，让阵自行调整。", "result": "大阵能用，灵脉运转有几处不畅，但不影响日常。账房师叔验阵后皱眉，没说话。", "modifier": {"gold": 0, "prestige": -10, "cultivation": 0, "lifespan": 0, "item": ""}},
					{"text": "私运一段灵脉之力分到自家洞府。", "result": "你的洞府灵气浓度上升了一截。账房师叔验阵时似乎察觉异样，又似乎没察觉。守一门里这种事——你心里清楚不会善了。", "modifier": {"gold": 30, "prestige": -16, "cultivation": 0, "lifespan": 0, "item": "残缺三阶破境符"}}
				]
			}
		]
	},
]

# ── Runtime 状态 (Rev 4) ─────────────────────────────────────

var _current_task:         Dictionary = {}
var _current_step:         int        = 0
var _acc_mod_gold:         int        = 0
var _acc_mod_prestige:     int        = 0
var _acc_mod_cultivation:  int        = 0
var _acc_mod_lifespan:     int        = 0
var _acc_mod_item_list:    Array[String] = []
var _step_results:         Array      = []
var awaiting_minigame:     bool       = false
var current_minigame_id:   String     = ""
var _dispatcher: Node

# ── 接口 ─────────────────────────────────────────────────────

func get_available(player) -> Array:
	if _dispatcher == null:
		return []
	return TASKS.filter(func(t): return _dispatcher.is_eligible(t, player))

func start(id: String) -> void:
	_reset()
	for t in TASKS:
		if t["id"] == id:
			_current_task = t.duplicate(true)
			return

func make_choice(index: int) -> Dictionary:
	if _current_task.is_empty():
		return {}
	if awaiting_minigame:
		push_warning("TaskHard: make_choice called while awaiting minigame")
		return {}

	var steps: Array = _current_task["steps"] as Array
	if _current_step >= steps.size():
		return {}
	var step: Dictionary = steps[_current_step] as Dictionary
	var choices: Array = step["choices"] as Array
	if index < 0 or index >= choices.size():
		return {}

	var choice: Dictionary = choices[index] as Dictionary
	var raw_mod: Dictionary = (choice.get("modifier", {}) as Dictionary).duplicate(true)
	var mod: Dictionary = _normalize_modifier(raw_mod)

	# 累加 modifier 字段（lifespan 累加进 _acc_mod_lifespan 仅作记录；game.gd 即时扣 player.lifespan）
	var step_gold:        int    = mod["gold"] as int
	var step_prestige:    int    = mod["prestige"] as int
	var step_cultivation: int    = mod["cultivation"] as int
	var step_lifespan:    int    = mod["lifespan"] as int
	var step_item:        String = mod["item"] as String

	_acc_mod_gold        += step_gold
	_acc_mod_prestige    += step_prestige
	_acc_mod_cultivation += step_cultivation
	_acc_mod_lifespan    += step_lifespan
	if step_item != "":
		_acc_mod_item_list.append(step_item)

	_step_results.append({
		"step":     _current_step + 1,
		"choice":   choice["text"],
		"result":   choice.get("result", ""),
		"modifier": mod.duplicate(true),
	})
	_current_step += 1

	var is_last: bool = _current_step >= steps.size()

	# 检查下一步是否有小游戏（Phase 1 全空，不触发）
	if not is_last:
		var next_step: Dictionary = steps[_current_step] as Dictionary
		var mg: String = next_step.get("minigame", "") as String
		if mg != "":
			awaiting_minigame   = true
			current_minigame_id = mg

	return {
		"step":     _current_step,
		"result":   choice.get("result", "") as String,
		"modifier": mod.duplicate(true),
		"is_last":  is_last,
	}

func on_minigame_result(passed: bool) -> void:
	if not awaiting_minigame:
		return
	# Phase 1 minigame=="" 不触发此函数。Phase 2 重新设计累加规则。
	# 当前实现：仅推进 step，不累加 modifier（占位）
	var zero_mod: Dictionary = {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}
	_step_results.append({
		"step":     _current_step + 1,
		"choice":   "[小游戏]",
		"result":   "通过" if passed else "失败",
		"modifier": zero_mod,
	})
	_current_step      += 1
	awaiting_minigame   = false
	current_minigame_id = ""

func finish(player) -> Dictionary:
	if _current_task.is_empty():
		return {}
	var task_data := _current_task
	var base: Dictionary = _normalize_base((task_data["base_reward"] as Dictionary).duplicate(true))
	var years: int = task_data["years"] as int

	var gold_b: int = base["gold"] as int
	var pres_b: int = base["prestige"] as int
	# task_hard: base.cultivation / base.lifespan / base.item 恒 0/0/""

	var final_gold: int = gold_b + _acc_mod_gold
	var final_pres: int = pres_b + _acc_mod_prestige
	var final_cult: int = _acc_mod_cultivation  # base.cultivation 恒 0

	player.pass_time(years)

	if final_gold > 0:
		player.add_gold(final_gold)
	if final_pres != 0:
		player.add_prestige(final_pres)

	var cult_overflow_msg: String = ""
	if final_cult > 0:
		cult_overflow_msg = player.add_cultivation(final_cult)

	var items_arr: Array[String] = []
	for it in _acc_mod_item_list:
		player.add_item(it)
		items_arr.append(it)

	var result := {
		"task_text":         task_data["text"],
		"difficulty":        "hard",
		"years":             years,
		"base_reward":       {"gold": gold_b, "prestige": pres_b, "cultivation": 0, "lifespan": 0, "item": ""},
		"modifier_total":    {"gold": _acc_mod_gold, "prestige": _acc_mod_prestige, "cultivation": _acc_mod_cultivation, "lifespan": _acc_mod_lifespan, "items": _acc_mod_item_list.duplicate()},
		"rewards":           {"gold": final_gold, "prestige": final_pres, "cultivation": final_cult, "items": items_arr},
		"step_results":      _step_results.duplicate(true),
		"cult_overflow_msg": cult_overflow_msg,
		"is_dead":           player.lifespan <= 0,
	}
	_reset()
	return result

# ── 内部 ─────────────────────────────────────────────────────

func get_current_step_data() -> Dictionary:
	if _current_task.is_empty():
		return {}
	var steps: Array = _current_task["steps"] as Array
	if _current_step >= steps.size():
		return {}
	return {
		"task_text":   _current_task["text"],
		"step_index":  _current_step,
		"total_steps": steps.size(),
		"step":        steps[_current_step],
	}

func _reset() -> void:
	_current_task         = {}
	_current_step         = 0
	_acc_mod_gold         = 0
	_acc_mod_prestige     = 0
	_acc_mod_cultivation  = 0
	_acc_mod_lifespan     = 0
	_acc_mod_item_list    = []
	_step_results         = []
	awaiting_minigame     = false
	current_minigame_id   = ""

func _normalize_modifier(m: Dictionary) -> Dictionary:
	return {
		"gold":        m.get("gold", 0) as int,
		"prestige":    m.get("prestige", 0) as int,
		"cultivation": m.get("cultivation", 0) as int,
		"lifespan":    m.get("lifespan", 0) as int,
		"item":        m.get("item", "") as String,
	}

func _normalize_base(b: Dictionary) -> Dictionary:
	return {
		"gold":        b.get("gold", 0) as int,
		"prestige":    b.get("prestige", 0) as int,
		"cultivation": b.get("cultivation", 0) as int,
		"lifespan":    b.get("lifespan", 0) as int,
		"item":        b.get("item", "") as String,
	}
