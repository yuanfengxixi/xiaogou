extends Node

# ══════════════════════════════════════════════════════════════
#  普通任务 handler (Rev 4 透明报酬制)
#  执行流程：接取 → 展示情境 → 玩家选一次 → finish: final = base_reward + chosen.modifier
#  每选项均视为"完成任务"。无 outcome 三档评分。
#  数据 schema: TASKS[i].base_reward (任务保底) + TASKS[i].choices[j].modifier (选项浮动)
# ══════════════════════════════════════════════════════════════

const TASKS: Array = [
	# ── 通用宗门任务（5 境界 各 1 条）──────────────────────────────
	{
		"id":             "tn_qi",
		"text":           "外门库房盘点",
		"desc":           "随师兄整理库房账目，账物不符。",
		"source":         "宗门任务",
		"realm_required": 0,
		"years":          5,
		"situation":      "外门库房深处，烛火不亮。师兄翻账本翻得头大，转头看你：『漏了三册典籍。你看着办。』他摆摆手出门去了，把烂摊子留给最年轻的那个——也就是你。",
		"base_reward":    {"gold": 50, "prestige": 6, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "一册一册仔细盘清，照实呈报执事堂。", "result": "你花了月余把账理清，连漏的三册典籍都标了来去。执事堂师叔点了点头：『后辈里还有用心做事的。』话不多，意思到了。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "装作没看见，把账本合上回禀『一切如常』。剩下的日子翻翻典籍偷修。", "result": "师兄没追问，事就过去了。库房守了五年，闲时翻典籍倒摸出点门道，不多，但聊胜于无。", "modifier": {"gold": 0, "prestige": -8, "cultivation": 4, "lifespan": 0, "item": ""}},
			{"text": "把对不上的典籍悄悄拿出去，找坊市换灵石。", "result": "三册典籍卖了八十灵石。账本盖一个『盘点完毕』的印就糊弄过去。但执事堂师叔事后查出来了——没有动你，但宗门里看你的眼神变了。", "modifier": {"gold": 35, "prestige": -13, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},
	{
		"id":             "tn_zhuji",
		"text":           "百年灵参轮值",
		"desc":           "草药园几株百年灵参临近抽穗，需要看守。",
		"source":         "宗门任务",
		"realm_required": 1,
		"years":          8,
		"situation":      "草药园里那几株灵参看着不起眼，但抽穗后任何一株都值百枚灵石。八年轮值，期间可能遇到偷采的修士，可能遇到为根而来的灵兽，也可能什么都没有，只有八年的雨打风吹。",
		"base_reward":    {"gold": 150, "prestige": 9, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "每日巡园，警戒符日日重画，宵小一律驱赶。", "result": "八年下来，灵参全数成熟。执事长老查阅你的记录册，眉毛动了动：『有心了。』后来那几株灵参炼丹时让你分了一点。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "设几道警戒符就走，每月象征性来一次。守护期偷修自己的功法。", "result": "八年里灵参少了两株，警戒符报了几次都被你掐灭。但你的功法摸到了一点筑基中期的门槛。", "modifier": {"gold": 0, "prestige": -11, "cultivation": 35, "lifespan": 0, "item": ""}},
			{"text": "监守自盗，把次等灵参偷偷送去坊市换灵石。", "result": "三株次等参换了三十五枚灵石。剩下的灵参也成熟了，账面上糊得过去。但同门师弟看你时眼神有点怪。", "modifier": {"gold": 35, "prestige": -17, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},
	{
		"id":             "tn_jindan",
		"text":           "押送弟子赴盟友宗门",
		"desc":           "金丹修士押送一批弟子千里赴会。",
		"source":         "宗门任务",
		"realm_required": 2,
		"years":          12,
		"situation":      "千里之外的盟友宗门办大典，门内挑了二十名外门弟子前去观礼，由你押送。十二年路程算不算长全看你怎么走。途中可能遇到邪修截杀，可能遇到旧识叙旧，也可能什么都没有，只有车马辘辘。",
		"base_reward":    {"gold": 400, "prestige": 9, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "全程不离弟子左右，事无巨细均记文册。", "result": "二十名弟子毫发无损送到。归途路过县城，有一支邪修暗中盯了你三日，被你以金丹威压震退。师门档案上写：『谨慎稳重，可托大事。』", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "弟子们筑基修为各有自保，你只盯着大方向。空时盘膝清修。", "result": "途中走脱两个弟子，一个死于山匪，一个不知所踪。但你的金丹境界稳了不少。师门虽不悦，未追究。", "modifier": {"gold": 0, "prestige": -11, "cultivation": 90, "lifespan": 0, "item": ""}},
			{"text": "借机替几位长老办私事，沿途收些『程仪』。", "result": "你揣着九位长老递的私函在江湖里走了一遭，弟子们没人少，灵石倒进账三十五枚。回来后某长老的脸有点冷。", "modifier": {"gold": 35, "prestige": -17, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},
	{
		"id":             "tn_yuanying",
		"text":           "秘境前哨轮值",
		"desc":           "宗门外围秘境前哨需元婴修士轮值十八年。",
		"source":         "宗门任务",
		"realm_required": 3,
		"years":          18,
		"situation":      "秘境吐纳已经持续千年。每隔几年它会吐出一些气运碎片，也会喷出一两只域外凶物。前哨的阵图繁复得像一篇上古经文，长老说『每一笔都不能错』。",
		"base_reward":    {"gold": 1000, "prestige": 9, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "严格按阵图昼夜巡检，凶物一现即镇。", "result": "十八年间镇住七只域外凶物，气运碎片悉数封存上交。长老视察时只说了一句：『有元婴的样子。』这话从他嘴里说出来，比奖赏珍贵。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "大事化小，小凶物放它自去，自己日常坐镇偷修。", "result": "前哨没出大事，气运碎片也封了几枚。但长老来视察时阵图三处差池，他没说话，眉毛动了一下。你的元婴中期突破倒是稳了。", "modifier": {"gold": 0, "prestige": -11, "cultivation": 220, "lifespan": 0, "item": ""}},
			{"text": "气运碎片悄悄留几枚，转手出给修罗门暗线。", "result": "三十五枚灵石的额外进账。十八年后哨所交接，账面上的碎片数比阵图自动记录的少四枚。事后无人深究，但宗门里看你的眼神再没那么干净。", "modifier": {"gold": 35, "prestige": -17, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},
	{
		"id":             "tn_huashen",
		"text":           "长老座下助讲",
		"desc":           "化神长老座下助讲，外门授课二十五年。",
		"source":         "宗门任务",
		"realm_required": 4,
		"years":          25,
		"situation":      "长老挑剔得出名，外门后辈又个个心高气傲。二十五年讲台站下来，能讲出真东西的不到三成，能听进真东西的更少。但宗门规矩如此。",
		"base_reward":    {"gold": 2500, "prestige": 9, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "一日不缺，问有所答；偶尔顶撞长老偏见。", "result": "二十五年讲下来，外门里走出三个能在四方榜挂号的后辈。长老虽说你『顶撞太过』，临走还是把一本旧讲义送了你。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "课讲一半，余下时间自己闭关。", "result": "外门弟子私下叫你『摆烂师叔』。但你这二十五年化神中期境界稳了不少。功过相抵，宗门没罚你。", "modifier": {"gold": 0, "prestige": -11, "cultivation": 480, "lifespan": 0, "item": ""}},
			{"text": "把长老内部讲义偷抄一份，半夜卖给富家后辈。", "result": "四十枚灵石入账。讲义流出后长老很快发现端倪，但你已经把痕迹抹得干净。他没明说，从此不再单独传你。", "modifier": {"gold": 40, "prestige": -17, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},

	# ── 衍天宗特色任务 ────────────────────────────────────────────
	{
		"id":             "tn_xt_qi",
		"text":           "推演秘法疑难",
		"desc":           "师叔丢给你一道秘法演算疑难。",
		"source":         "宗门任务",
		"realm_required": 0,
		"years":          6,
		"situation":      "师叔丢了一卷推演稿在你案头，连话都不多说：『想不通就是没天分，不必勉强。』他这话不算激，但你心里咽不下。卷子上密密麻麻的符篆，一看就是宗门核心秘法的旁支。",
		"base_reward":    {"gold": 50, "prestige": 9, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "数月不眠，反复演算，最终找出关节呈上。", "result": "师叔看完你的解法盯了你三息，把卷子一卷收进袖中：『你姓什么？』他记住了你的名字。这在衍天宗，已经是难得的事。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "抄了师兄的旧解，掺点自己的小聪明搪塞过去。", "result": "师叔扫了一眼，没夸也没贬，只『嗯』了一声。卷子从此再没出现。但你抄解时确实摸到了点门道，自己功法上小补了一点。", "modifier": {"gold": 0, "prestige": -11, "cultivation": 4, "lifespan": 0, "item": ""}},
			{"text": "拉师兄一起做，做完只署你的名。", "result": "卷子上交，师叔点头。师兄过几天才反应过来——他没声张，但从此再不替你出力。", "modifier": {"gold": 25, "prestige": -15, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},
	{
		"id":             "tn_xt_zhuji",
		"text":           "雷劫秘境护法",
		"desc":           "师叔渡九霄雷劫，命你执掌护法阵眼。",
		"source":         "宗门任务",
		"realm_required": 1,
		"years":          10,
		"situation":      "师叔七百年的功夫，凝结于一场雷劫之中。你被指定执掌护法阵眼。这不是托付，是测试。雷威落下来不分敌我，阵眼一刻不能离人。",
		"base_reward":    {"gold": 150, "prestige": 9, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "阵眼一刻不离，三次接下偏雷。", "result": "师叔渡劫成功，回过头看了你一眼：『阵眼三处偏雷你都接住了。我记下了。』衍天宗的『记下了』，分量不轻。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": "二阶破境符"}},
			{"text": "阵眼运转后离去清修。", "result": "师叔自己运转余威接住了偏雷，渡劫还是成了。回来扫了你一眼：『下次记得，雷劫不挑人。』你这十年功法长进不少，但他再没让你护过法。", "modifier": {"gold": 0, "prestige": -12, "cultivation": 38, "lifespan": 0, "item": ""}},
			{"text": "趁雷劫余威盗炼一炉护身丹。", "result": "你炼出了三颗护身丹，价值约莫二十五枚灵石。师叔渡劫成功，未察觉异样。但你心里清楚——师叔若有一日察觉，这事不会善了。", "modifier": {"gold": 25, "prestige": -16, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},

	# ── 修罗门特色任务（base.gold 数据填充阶段 ×1.5）──────────────
	{
		"id":             "tn_xl_qi",
		"text":           "下山讨保护费",
		"desc":           "山下三家商铺欠着半年的保护费，门主限你三月内讨回。",
		"source":         "宗门任务",
		"realm_required": 0,
		"years":          4,
		"situation":      "门主把账册往你手里一塞：『三家。半年没交。三个月，你看着办。』修罗门做事不讲废话——三个月，意味着第四个月没结果，下个上门讨账的就讨你了。",
		"base_reward":    {"gold": 75, "prestige": 3, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "一家一家上门，话先说清，不通就动手。", "result": "三家商铺，半月清账。其中一家不开窍，被你卸了一条胳膊，第二天乖乖把欠款送来。门主看了账本，没多说，往你手里塞了一袋灵石。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "砸两个铺面立威，剩余主动送来。途中顺手刨了几座新坟练血气。", "result": "三个月内全清。回程路上挖了几具尸首，血气炼了几日，居然摸到一点门道。门主看着账本：『还有点修罗门的样子。』", "modifier": {"gold": 0, "prestige": -6, "cultivation": 4, "lifespan": 0, "item": ""}},
			{"text": "多收三成，自己留下差额。", "result": "三家共多缴二十五枚灵石入袋。账面上写的还是原数。门主没查账——但修罗门里这种事，被发现是迟早的。", "modifier": {"gold": 35, "prestige": -10, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},
	{
		"id":             "tn_xl_zhuji",
		"text":           "处置告密者",
		"desc":           "外门弟子向正道宗门走漏布阵情报。门主递你一柄黑铁刀。",
		"source":         "宗门任务",
		"realm_required": 1,
		"years":          8,
		"situation":      "门主把黑铁刀放在你手里，没多说。那个外门弟子已经跪在地下牢狱里十几日了。修罗门的规矩你早就知道——告密者不许活到下个月。",
		"base_reward":    {"gold": 225, "prestige": 3, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "当场了断，刀干净利落。", "result": "一刀过去，事干净。门主点了点头：『不拖泥带水，好。』他把告密者藏的灵石取出，你分了三成。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "先逼问还泄露了什么，再杀。期间将剩余血气炼入功法。", "result": "你从他嘴里挖出三条额外漏洞，门主当夜就堵上。他再想多说时，刀已经下来。期间血气炼入功法，筑基中期摸到一线门径。", "modifier": {"gold": 0, "prestige": -5, "cultivation": 36, "lifespan": 0, "item": ""}},
			{"text": "假死放走，悄悄把他的家底变卖。", "result": "三十五枚灵石入袋。告密者跑了，你回报『已了结』。但修罗门里这种谎，迟早是要还的——你心里清楚。", "modifier": {"gold": 35, "prestige": -11, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},

	# ── 青云宗特色任务 ────────────────────────────────────────────
	{
		"id":             "tn_qy_qi",
		"text":           "山下启蒙堂授课",
		"desc":           "山下小镇启蒙堂请来青云宗弟子讲修仙入门。",
		"source":         "宗门任务",
		"realm_required": 0,
		"years":          5,
		"situation":      "山下小镇有一座启蒙堂，招收平民家根骨稍可的孩子。教孩子认字、辨灵气、识凡药，三年一期。镇民们看你的眼神比看县官还郑重——青云宗的弟子，到底是不一样的。",
		"base_reward":    {"gold": 50, "prestige": 9, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "每堂不偷工，挑几个根骨好的暗中点拨。", "result": "三年下来，三个孩子拜入青云宗外门。镇上百姓念你的好，每年捎来山货。长老听闻，给你记了一笔。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "念稿了事，留时间自己修炼。", "result": "孩子们也学了点皮毛。你这五年功法长进了一点，镇民们对青云宗的印象也淡了一点。长老听了，皱眉但没说话。", "modifier": {"gold": 0, "prestige": -11, "cultivation": 4, "lifespan": 0, "item": ""}},
			{"text": "课中夹卖宗门旧典籍给富家子弟。", "result": "三十枚灵石入账。富家子弟拿到典籍后到处显摆，传到长老耳里时已经是半年后。长老叫你过去，问你为什么。你说不出话来。", "modifier": {"gold": 30, "prestige": -17, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},
	{
		"id":             "tn_qy_zhuji",
		"text":           "调解修仙家族纠纷",
		"desc":           "两家修仙家族为灵田边界争执，长老指你前去调停。",
		"source":         "宗门任务",
		"realm_required": 1,
		"years":          8,
		"situation":      "两家小修仙家族为一片灵田边界争得险些动刀。长老说『你去把这事按下』，没说怎么按。青云宗素来公正，但公正不是没有代价。",
		"base_reward":    {"gold": 150, "prestige": 9, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "实地丈量，依宗门律法划界，得罪两方。", "result": "界线清清楚楚，两家都不满意，但都不敢造次。长老看了你的判词，点了点头：『青云宗的规矩，就该这么用。』", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "各方说几句场面话，让他们自行了结。期间清修。", "result": "两家暂时偃旗息鼓，半年后又打起来。长老再差人去时已经晚了——但这八年你筑基功法长进不少。", "modifier": {"gold": 0, "prestige": -11, "cultivation": 35, "lifespan": 0, "item": ""}},
			{"text": "收两边的『茶水钱』，判一个无关痛痒的折中。", "result": "三十五枚灵石入袋。两家各退一步，事情压住了。但其中一家事后觉得不对，悄悄向长老递了状子。长老没追，看你的眼神有点不一样了。", "modifier": {"gold": 35, "prestige": -16, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},

	# ── 草门特色任务 ──────────────────────────────────────────────
	{
		"id":             "tn_cm_qi",
		"text":           "下山摆摊代占",
		"desc":           "草门传统：弟子下山给凡人占卜，看你能不能从凡人嘴里听出门道。",
		"source":         "宗门任务",
		"realm_required": 0,
		"years":          4,
		"situation":      "门主递给你一面卦旗一筒签：『下山去。卦灵卦不灵都不重要，重要的是你听不听得出门道。』草门的师承，玄得很——但门主向来不解释。",
		"base_reward":    {"gold": 55, "prestige": 8, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "逐家逐户认真听卦，记录世情。", "result": "四年下来，你记了三本厚厚的市井杂记。门主翻了翻：『有了。』他也不说有了什么。但你升了一阶内门资格。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "随便起卦说几句，余下时间自己琢磨。", "result": "卦倒也准了几次，多是凑巧。空余时间你琢磨到一点旁门玄理，功法小补。", "modifier": {"gold": 0, "prestige": -9, "cultivation": 4, "lifespan": 0, "item": ""}},
			{"text": "半真半假糊弄，多收几枚铜板。", "result": "三十枚灵石的额外进账。但有个老妇人按你的卦白等了三年儿子，直到死也没等到。这事你不知道——但草门那边的老者眼神，已经变了。", "modifier": {"gold": 30, "prestige": -14, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},
	{
		"id":             "tn_cm_zhuji",
		"text":           "拣选废丹",
		"desc":           "草门坊市后院堆着十几年废丹，门主说『也许有遗漏好货』。",
		"source":         "宗门任务",
		"realm_required": 1,
		"years":          7,
		"situation":      "废丹堆得有半人高，颜色五花八门，气味更是各种各样。门主看你一眼：『七年。能挑出多少算多少。』他说话向来不解释，但你听出他没什么期待。",
		"base_reward":    {"gold": 160, "prestige": 8, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "一颗颗辨识，捡出几枚还算可用的。", "result": "七年下来挑出十一枚仍可入药的丹丸，其中三枚意外地是低阶补元丹。门主点头：『眼力还行。』赏了你三十灵石。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "大致筛过算数。期间偷修自己的功法。", "result": "挑出五枚可用，余下都堆回原处。期间偷修筑基功法摸到点门道。门主翻了翻你的成绩单：『勉强。』", "modifier": {"gold": 0, "prestige": -10, "cultivation": 37, "lifespan": 0, "item": ""}},
			{"text": "真好货留自己偷着用，废货上交。", "result": "你私吞了两枚补元丹，账上只交了几枚下下品。门主验货时眯了眯眼，没说破。但草门里这种事，门主从不当场翻脸。", "modifier": {"gold": 35, "prestige": -15, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},

	# ── 守一门特色任务 ────────────────────────────────────────────
	{
		"id":             "tn_sy_qi",
		"text":           "寒玉灵田守值",
		"desc":           "门下两亩寒玉灵田，需要弟子轮值守护。",
		"source":         "宗门任务",
		"realm_required": 0,
		"years":          5,
		"situation":      "守一门的灵田规矩你早就知道——值守不是站着，是真要下田。除草、翻土、引水、驱兽。五年下来，手上都是老茧。但灵米成熟时那股清气，闻一回值一回。",
		"base_reward":    {"gold": 50, "prestige": 9, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "五年不缺一日。亩田收成翻倍。", "result": "五年下来灵米丰收，门内老厨送来一坛灵米酒：『拿去喝。』守一门嘴笨，但心实。长老在功劳簿上记了你的名字。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "不耽误大事就行。空时偷修。", "result": "灵米收成稍逊，但也算交差。你这五年偷偷摸摸的修炼摸到一点门径。守一门长老什么也没说——但他什么也不必说。", "modifier": {"gold": 0, "prestige": -11, "cultivation": 4, "lifespan": 0, "item": ""}},
			{"text": "盗了一些灵米下山换钱。", "result": "三十枚灵石的额外进账。你想着不会有人发现——直到长老来交接时只看了你一眼。守一门的眼神有时候比刀还锋利。", "modifier": {"gold": 30, "prestige": -17, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},
	{
		"id":             "tn_sy_zhuji",
		"text":           "账房抄账",
		"desc":           "门下八年收支需要从粗本誊到正本。",
		"source":         "宗门任务",
		"realm_required": 1,
		"years":          8,
		"situation":      "账房里的灯要点八年。蝇头小字一笔一笔抄过去，眼睛瞎了不算工伤——这是守一门的玩笑话。但守一门的玩笑话，往往是真的。",
		"base_reward":    {"gold": 150, "prestige": 9, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "一字不漏，发现两笔旧账漏记，主动报上。", "result": "正本誊清，旧账补记。账房师叔难得露出笑容：『你这眼力，可以。』他往你手里塞了一袋灵石。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "错就错，反正没人查。期间清修。", "result": "正本抄完了，几处错没人发现。八年里你的筑基功法稳了不少。账房师叔合上账本：『也算交差。』", "modifier": {"gold": 0, "prestige": -11, "cultivation": 37, "lifespan": 0, "item": ""}},
			{"text": "故意算错让某些账少一两枚灵石，差额入袋。", "result": "三十五枚灵石入袋。账面上没人当场发现。守一门的账房师叔从来不当场翻脸——但他记性比账本还好。", "modifier": {"gold": 35, "prestige": -16, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},

	# ── 江湖悬赏（base 取中性 choice[1]，final.prestige ∈ [-3,+3]，cultivation=0）─
	{
		"id":             "tn_jh_low",
		"text":           "押镖过山",
		"desc":           "城中商行的悬赏。押一队药材去临县。",
		"source":         "江湖悬赏",
		"realm_required": 0,
		"years":          4,
		"situation":      "商行掌柜把契书递给你，话说在前：『路上遇匪不算我的事，但药材少一车，从你工钱里扣。』半路果然遇到山贼，几个练气期的小贼，眼里只有车上的药材。",
		"base_reward":    {"gold": 60, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "横剑挡前，硬碰硬。", "result": "三个山贼见你出剑就跑了。药材一车未失，到县衙交差。掌柜把工钱多给了二十枚：『下回还来。』", "modifier": {"gold": 15, "prestige": 3, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "丢三车换平安。", "result": "山贼拿了三车药材就走。剩余的押到县衙。掌柜照原工钱发，没夸也没骂——但下回的镖单没再给你。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "见势不妙先溜，回去说没遇上。", "result": "整队药材丢光。掌柜知道你撒谎，但没办法证明，工钱照发。江湖里这种事多了，但你的名字也开始有人嘀咕。", "modifier": {"gold": -10, "prestige": -3, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},
	{
		"id":             "tn_jh_mid",
		"text":           "替百姓打抱不平",
		"desc":           "县城里某修仙世家欺人太甚。三五百姓凑了点积蓄请你出手。",
		"source":         "江湖悬赏",
		"realm_required": 1,
		"years":          6,
		"situation":      "几个老人捧着一个褪色的钱袋找到你。袋子里两百多枚铜钱，零碎得很。他们说：『修士老爷，您给评评理。』你听完了那家修仙世家的事，叹了口气——这不是钱不钱的事。",
		"base_reward":    {"gold": 200, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "直接登门，给那家修士留点教训。", "result": "你登门时家主以为你是来谈判的，结果你一掌拍碎了他家厅堂的玉柱。他没敢还手——筑基对筑基，你是后期他是中期。从此那家收敛了不少。百姓凑的二百枚铜你退了回去，但县城里多了一个名号。", "modifier": {"gold": 20, "prestige": 3, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "见家主，拿钱了事。", "result": "家主额外给了你两百枚灵石让你『以后多多关照』。事情压住了，但那家修仙世家照旧欺人。百姓再没找过你——但他们的眼神你这辈子都记得。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "收了百姓的钱，不办事。", "result": "二百枚铜钱入袋，事情你没办。百姓后来托人捎话来骂你，话很难听。江湖里你的名字开始与一些不那么干净的事情连在一起。", "modifier": {"gold": -40, "prestige": -3, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},
	{
		"id":             "tn_jh_high",
		"text":           "商行八年护卫",
		"desc":           "某大商行雇你做八年护卫。三国之地，刺客不少。",
		"source":         "江湖悬赏",
		"realm_required": 2,
		"years":          8,
		"situation":      "大商行的东主递契书时直接写：『你只管护我家小公子的命，事成八百枚灵石。中途若死或弃，分文不给。』八年里要走三国，途经的修仙势力个个不省心。",
		"base_reward":    {"gold": 500, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""},
		"choices": [
			{"text": "八年寸步不离，化解三次刺杀。", "result": "小公子活到了第八年。东主额外给了你两枚百年灵参。临走时小公子拜你为半师——这名头你不在意，但东主家在江湖上替你说了话。", "modifier": {"gold": 60, "prestige": 3, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "该做的做，不多管闲事。", "result": "小公子活下来了，但少了一根手指。东主按契书付了五百枚灵石，话不多说。江湖里这种交易司空见惯。", "modifier": {"gold": 0, "prestige": 0, "cultivation": 0, "lifespan": 0, "item": ""}},
			{"text": "替对家通几次风，拿双份酬劳。", "result": "对家给了你一百五十枚灵石。小公子受了两次重伤但都没死，东主疑心重重却查无实据，照付五百。但江湖里这种事走一次就是一次记号。", "modifier": {"gold": 150, "prestige": -3, "cultivation": 0, "lifespan": 0, "item": ""}}
		]
	},
]

var _current_task:      Dictionary = {}
var _chosen_modifier:   Dictionary = {}
var _dispatcher: Node

# ── 接口 ─────────────────────────────────────────────────────

func get_available(player) -> Array:
	if _dispatcher == null:
		return []
	return TASKS.filter(func(t): return _dispatcher.is_eligible(t, player))

func start(id: String) -> void:
	_current_task     = {}
	_chosen_modifier  = {}
	for t in TASKS:
		if t["id"] == id:
			_current_task = t.duplicate(true)
			return

func make_choice(index: int) -> Dictionary:
	if _current_task.is_empty():
		return {}
	var choices: Array = _current_task["choices"] as Array
	if index < 0 or index >= choices.size():
		return {}
	var choice: Dictionary = choices[index] as Dictionary
	var raw_mod: Dictionary = (choice.get("modifier", {}) as Dictionary).duplicate(true)
	_chosen_modifier = _normalize_modifier(raw_mod)
	return {
		"result":   choice.get("result", "") as String,
		"modifier": _chosen_modifier.duplicate(true),
		"is_last":  true,
	}

func finish(player) -> Dictionary:
	if _current_task.is_empty() or _chosen_modifier.is_empty():
		return {}
	var task_data: Dictionary = _current_task
	var base: Dictionary = _normalize_base((task_data["base_reward"] as Dictionary).duplicate(true))
	var years: int = task_data["years"] as int

	var gold_b: int = base.get("gold", 0) as int
	var pres_b: int = base.get("prestige", 0) as int
	# task_normal: base.cultivation / base.lifespan / base.item 恒 0/0/""

	var gold_m: int    = _chosen_modifier.get("gold", 0) as int
	var pres_m: int    = _chosen_modifier.get("prestige", 0) as int
	var cult_m: int    = _chosen_modifier.get("cultivation", 0) as int
	var life_m: int    = _chosen_modifier.get("lifespan", 0) as int
	var item_m: String = _chosen_modifier.get("item", "") as String

	var final_gold: int = gold_b + gold_m
	var final_pres: int = pres_b + pres_m
	var final_cult: int = cult_m  # base.cultivation 恒 0

	player.pass_time(years)

	if final_gold > 0:
		player.add_gold(final_gold)
	if final_pres != 0:
		player.add_prestige(final_pres)
	var items_arr: Array[String] = []
	if item_m != "":
		player.add_item(item_m)
		items_arr.append(item_m)

	var cult_overflow_msg: String = ""
	if final_cult > 0:
		cult_overflow_msg = player.add_cultivation(final_cult)

	var result := {
		"task_text":         task_data["text"],
		"difficulty":        "normal",
		"years":             years,
		"base_reward":       {"gold": gold_b, "prestige": pres_b, "cultivation": 0, "lifespan": 0, "item": ""},
		"modifier_total":    {"gold": gold_m, "prestige": pres_m, "cultivation": cult_m, "lifespan": life_m, "items": items_arr.duplicate()},
		"rewards":           {"gold": final_gold, "prestige": final_pres, "cultivation": final_cult, "items": items_arr},
		"cult_overflow_msg": cult_overflow_msg,
		"is_dead":           player.lifespan <= 0,
	}
	_current_task     = {}
	_chosen_modifier  = {}
	return result

# ── 内部 ─────────────────────────────────────────────────────

func get_situation_data() -> Dictionary:
	if _current_task.is_empty():
		return {}
	return {
		"task_text": _current_task["text"],
		"situation": _current_task.get("situation", ""),
		"choices":   _current_task.get("choices", []),
	}

func _abort() -> void:
	_current_task     = {}
	_chosen_modifier  = {}

func _normalize_modifier(m: Dictionary) -> Dictionary:
	# 五字段缺省默认值：gold/prestige/cultivation/lifespan = 0；item = ""
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
