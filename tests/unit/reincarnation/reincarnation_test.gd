extends SceneTree

var _passed: int = 0
var _failed: int = 0
var _failures: Array[String] = []
var _owned_nodes: Array[Node] = []

func _init() -> void:
	test_death_options_use_realm_rewards_and_inherit_ten_percent_gold()
	test_death_options_clamp_out_of_range_realms()
	test_ascension_grant_inherits_all_gold_and_fixed_bonuses()
	test_new_run_receives_accumulated_bonuses()
	_report()

func _make_node(path: String) -> Node:
	var node: Node = load(path).new()
	_owned_nodes.append(node)
	return node

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
