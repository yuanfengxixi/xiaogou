extends SceneTree

var _passed: int = 0
var _failed: int = 0
var _failures: Array[String] = []
var _owned_nodes: Array[Node] = []
var _temporary_save_paths: Array[String] = []

func _init() -> void:
	test_death_options_use_realm_rewards_and_inherit_ten_percent_gold()
	test_death_options_clamp_out_of_range_realms()
	test_ascension_grant_inherits_all_gold_and_fixed_bonuses()
	test_new_run_receives_accumulated_bonuses()
	test_load_from_disk_keeps_defaults_when_save_is_missing()
	test_death_choice_persists_only_the_selected_bonus()
	test_ascension_persists_rewards_and_resets_lives()
	_report()

func _make_node(path: String) -> Node:
	var node: Node = load(path).new()
	_owned_nodes.append(node)
	return node

func _make_reincarnation(save_path: String = "") -> Node:
	var script = load("res://reincarnation.gd")
	var node: Node = script.new(save_path) if not save_path.is_empty() else script.new()
	_owned_nodes.append(node)
	return node

func _new_save_path() -> String:
	var path := "user://reincarnation-test-%d.cfg" % Time.get_ticks_usec()
	_temporary_save_paths.append(path)
	return path

func _expect(condition: bool, name: String, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  ✓ " + name)
	else:
		_failed += 1
		var message := name + (" [" + detail + "]" if not detail.is_empty() else "")
		_failures.append(message)
		print("  ✗ " + message)

func _report() -> void:
	for node in _owned_nodes:
		if is_instance_valid(node):
			node.free()
	_owned_nodes.clear()
	for path in _temporary_save_paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_temporary_save_paths.clear()
	print("\n─── Reincarnation 单元测试 ───")
	print("通过 %d / 失败 %d" % [_passed, _failed])
	if _failed > 0:
		for message in _failures:
			print("  ✗ " + message)
		quit(1)
	else:
		print("✓ 全部通过")
		quit(0)

func test_death_options_use_realm_rewards_and_inherit_ten_percent_gold() -> void:
	var reincarnation = _make_node("res://reincarnation.gd")
	var player = _make_node("res://player.gd")
	player.realm = 2
	player.gold = 1999

	var options: Dictionary = reincarnation.get_death_options(player)
	_expect(options.get("realm") == 2, "死亡选项保留当前境界索引")
	_expect(options.get("realm_name") == "金丹期", "死亡选项使用对应境界名称")
	_expect(options.get("points") == 2 and options.get("luck") == 1, "死亡选项按金丹期奖励表计算")
	_expect(options.get("gold") == 199, "普通死亡继承灵石的 10% 并向下取整")

func test_death_options_clamp_out_of_range_realms() -> void:
	var reincarnation = _make_node("res://reincarnation.gd")
	var player = _make_node("res://player.gd")
	player.realm = -5
	var low_options: Dictionary = reincarnation.get_death_options(player)
	player.realm = 100
	var high_options: Dictionary = reincarnation.get_death_options(player)

	_expect(low_options.get("realm") == 0 and low_options.get("realm_name") == "练气期", "负境界回退到练气期")
	_expect(high_options.get("realm") == 4 and high_options.get("realm_name") == "化神期", "越界境界回退到最高普通境界")

func test_ascension_grant_inherits_all_gold_and_fixed_bonuses() -> void:
	var reincarnation = _make_node("res://reincarnation.gd")
	var player = _make_node("res://player.gd")
	player.gold = 321

	var grant: Dictionary = reincarnation.get_ascension_grant(player)
	_expect(grant.get("points") == 20, "飞升赠送固定天赋点")
	_expect(grant.get("luck") == 12, "飞升赠送固定气运")
	_expect(grant.get("gold") == 321, "飞升完整继承灵石")

func test_new_run_receives_accumulated_bonuses() -> void:
	var reincarnation = _make_node("res://reincarnation.gd")
	var talent = _make_node("res://talent.gd")
	var player = _make_node("res://player.gd")
	reincarnation.bonus_talent_points = 12
	reincarnation.bonus_start_gold = 50
	reincarnation.bonus_start_luck = 4
	talent.talent_speed = 9
	talent.talent_luck = 8
	player.gold = 999
	player.talent_luck = 99

	reincarnation.apply_to_new_run(talent, player)
	_expect(talent.total_points == 12, "新局继承累计天赋点")
	_expect(talent.talent_speed == 0 and talent.talent_luck == 0, "新局先清空待分配天赋")
	_expect(player.gold == 90, "新局灵石等于基础值加累计奖励")
	_expect(player.talent_luck == 4, "新局气运继承累计奖励")

func test_load_from_disk_keeps_defaults_when_save_is_missing() -> void:
	var reincarnation = _make_reincarnation(_new_save_path())
	reincarnation.load_from_disk()
	_expect(reincarnation.lives == 0, "缺少存档时转世次数保留默认值")
	_expect(reincarnation.total_ascensions == 0, "缺少存档时飞升次数保留默认值")
	_expect(reincarnation.bonus_talent_points == 0, "缺少存档时天赋加成保留默认值")

func test_death_choice_persists_only_the_selected_bonus() -> void:
	var path := _new_save_path()
	var reincarnation = _make_reincarnation(path)
	reincarnation.commit_death_choice("luck", {"points": 3, "luck": 2, "gold": 99})

	var loaded = _make_reincarnation(path)
	loaded.load_from_disk()
	_expect(loaded.lives == 1, "死亡选择写入转世次数")
	_expect(loaded.bonus_start_luck == 2, "死亡选择只累加已选气运")
	_expect(loaded.bonus_talent_points == 0 and loaded.bonus_start_gold == 0, "死亡选择不累加未选奖励")

func test_ascension_persists_rewards_and_resets_lives() -> void:
	var path := _new_save_path()
	var reincarnation = _make_reincarnation(path)
	reincarnation.lives = 3
	reincarnation.bonus_talent_points = 4
	reincarnation.total_ascensions = 1
	reincarnation.commit_ascension({"points": 20, "luck": 12, "gold": 321})

	var loaded = _make_reincarnation(path)
	loaded.load_from_disk()
	_expect(loaded.total_ascensions == 2, "飞升后累计飞升次数")
	_expect(loaded.lives == 0, "飞升后重置转世次数")
	_expect(loaded.bonus_talent_points == 24, "飞升后累计天赋点")
	_expect(loaded.bonus_start_luck == 12, "飞升后累计气运")
	_expect(loaded.bonus_start_gold == 321, "飞升后累计灵石")
