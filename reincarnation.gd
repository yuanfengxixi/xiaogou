extends Node

# 转世 meta progression — 跨局持久增益
# 设计源：本会话 user 决策（B 模式累加 / 灵石 10% / 飞升全拿 / 飞升后 lives 重置）
# 持久化路径：user://reincarnation.cfg
# 数值表见 REWARD_POINTS_BY_REALM / REWARD_LUCK_BY_REALM / GOLD_INHERIT_RATE_*
# TODO: 完整 GDD 文档 design/gdd/reincarnation.md（待 /design-system 走 8 sections）

const SAVE_PATH := "user://reincarnation.cfg"

# 各境界死亡奖励（飞升单独走 commit_ascension）
# 索引 0..4：练气 / 筑基 / 金丹 / 元婴 / 化神
const REWARD_POINTS_BY_REALM := [0, 0, 2, 5, 10]
const REWARD_LUCK_BY_REALM   := [0, 0, 1, 3, 6]

# 飞升专属（B 模式 + 飞升全拿）
const ASCENSION_GRANT_POINTS := 20
const ASCENSION_GRANT_LUCK   := 12

# 灵石继承率：普通死亡 10% / 飞升 100%
const GOLD_INHERIT_RATE_DEATH  := 0.10
const GOLD_INHERIT_RATE_ASCEND := 1.00

# 起手灵石基线（与 game.gd _show_faction_select 原 player.gold = 40 对应）
const START_GOLD_BASE := 40

# 持久化字段（disk → mem，main.gd 调用 load_from_disk 后注入）
var lives: int = 0
var total_ascensions: int = 0
var bonus_talent_points: int = 0
var bonus_start_gold: int = 0
var bonus_start_luck: int = 0

# 从 user:// 读盘；无存档则保持默认 0 值
func load_from_disk() -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err != OK:
		return
	lives = cfg.get_value("meta", "lives", 0)
	total_ascensions = cfg.get_value("meta", "total_ascensions", 0)
	bonus_talent_points = cfg.get_value("bonus", "talent_points", 0)
	bonus_start_gold = cfg.get_value("bonus", "start_gold", 0)
	bonus_start_luck = cfg.get_value("bonus", "start_luck", 0)

func save_to_disk() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("meta", "lives", lives)
	cfg.set_value("meta", "total_ascensions", total_ascensions)
	cfg.set_value("bonus", "talent_points", bonus_talent_points)
	cfg.set_value("bonus", "start_gold", bonus_start_gold)
	cfg.set_value("bonus", "start_luck", bonus_start_luck)
	cfg.save(SAVE_PATH)

# 起手注入：把累计 bonus 写入 talent / player；main.gd 在 add_child 后调用
# - talent.total_points 决定来世铭印分配池；talent_speed/luck 仍 0（待玩家分配）
# - player.gold = 40 + bonus_start_gold；player.talent_luck = bonus_start_luck
func apply_to_new_run(talent, player) -> void:
	talent.total_points = bonus_talent_points
	talent.talent_speed = 0
	talent.talent_luck = 0
	player.gold = START_GOLD_BASE + bonus_start_gold
	player.talent_luck = bonus_start_luck

# 死亡时计算 3 项可选遗赠
func get_death_options(player) -> Dictionary:
	var realm: int = clampi(player.realm, 0, REWARD_POINTS_BY_REALM.size() - 1)
	return {
		"realm": realm,
		"realm_name": player.REALMS[realm],
		"points": REWARD_POINTS_BY_REALM[realm],
		"luck": REWARD_LUCK_BY_REALM[realm],
		"gold": int(player.gold * GOLD_INHERIT_RATE_DEATH),
	}

# 飞升时全拿（无选择）
func get_ascension_grant(player) -> Dictionary:
	return {
		"points": ASCENSION_GRANT_POINTS,
		"luck": ASCENSION_GRANT_LUCK,
		"gold": int(player.gold * GOLD_INHERIT_RATE_ASCEND),
	}

# 死亡 commit：玩家选 1 项；放弃 = "skip"
func commit_death_choice(choice: String, opts: Dictionary) -> void:
	match choice:
		"talent":
			bonus_talent_points += int(opts["points"])
		"gold":
			bonus_start_gold += int(opts["gold"])
		"luck":
			bonus_start_luck += int(opts["luck"])
		"skip":
			pass
	lives += 1
	save_to_disk()

# 飞升 commit：三项全加 + lives 重置
func commit_ascension(grant: Dictionary) -> void:
	bonus_talent_points += int(grant["points"])
	bonus_start_gold += int(grant["gold"])
	bonus_start_luck += int(grant["luck"])
	total_ascensions += 1
	lives = 0
	save_to_disk()

# 累计状态文本（用于死亡屏 / 飞升屏透明展示）
func get_status_text() -> String:
	return (
		"═══ 当前轮回累计 ═══\n" +
		"【转世次数】%d　【飞升次数】%d\n" % [lives, total_ascensions] +
		"【天赋点累计】+%d　【起始灵石累计】+%d　【起始气运累计】+%d" % [
			bonus_talent_points, bonus_start_gold, bonus_start_luck
		]
	)
