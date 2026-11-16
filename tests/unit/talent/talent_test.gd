extends SceneTree

var _passed: int = 0
var _failed: int = 0
var _failures: Array[String] = []
var _owned_nodes: Array[Node] = []

func _init() -> void:
	test_point_budget_is_enforced()
	test_unknown_talent_does_not_consume_points()
	test_remove_point_stops_at_zero()
	test_apply_to_player_copies_allocated_talents()
	_report()

func _make_talent() -> Node:
	var talent = load("res://talent.gd").new()
	_owned_nodes.append(talent)
	return talent

func _expect(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("  ✓ " + name)
	else:
		_failed += 1
		_failures.append(name)
		print("  ✗ " + name)

func _report() -> void:
	for node in _owned_nodes:
		if is_instance_valid(node):
			node.free()
	_owned_nodes.clear()
	print("\n─── Talent 单元测试 ───")
	print("通过 %d / 失败 %d" % [_passed, _failed])
	if _failed > 0:
		for message in _failures:
			print("  ✗ " + message)
		quit(1)
	else:
		print("✓ 全部通过")
		quit(0)

func test_point_budget_is_enforced() -> void:
	var talent = _make_talent()
	talent.total_points = 2
	_expect(talent.add_point("speed"), "可分配第一个天赋点")
	_expect(talent.add_point("luck"), "可分配第二个天赋点")
	_expect(not talent.add_point("speed"), "预算用完后拒绝继续分配")
	_expect(talent.get_remaining() == 0, "剩余点数保持为零")

func test_unknown_talent_does_not_consume_points() -> void:
	var talent = _make_talent()
	talent.total_points = 1
	_expect(not talent.add_point("unknown"), "拒绝未知天赋类型")
	_expect(talent.get_remaining() == 1, "无效分配不消耗天赋点")

func test_remove_point_stops_at_zero() -> void:
	var talent = _make_talent()
	talent.total_points = 1
	_expect(not talent.remove_point("speed"), "零点数的天赋不能继续移除")
	_expect(not talent.remove_point("unknown"), "不能移除未知天赋类型")
	_expect(talent.get_remaining() == 1, "无效移除不改变剩余点数")

func test_apply_to_player_copies_allocated_talents() -> void:
	var talent = _make_talent()
	var player = load("res://player.gd").new()
	_owned_nodes.append(player)
	talent.talent_speed = 3
	talent.talent_luck = 2
	talent.apply_to_player(player)
	_expect(player.talent_speed == 3 and player.talent_luck == 2, "把已分配天赋复制到玩家")
	_expect(is_equal_approx(player.get_speed_multiplier(), 1.3), "修炼倍率反映速度天赋")
	_expect(is_equal_approx(player.get_luck_multiplier(), 1.2), "气运倍率反映气运天赋")
