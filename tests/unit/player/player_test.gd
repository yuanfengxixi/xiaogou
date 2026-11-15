extends SceneTree

var _passed: int = 0
var _failed: int = 0
var _failures: Array[String] = []
var _owned_nodes: Array[Node] = []

func _init() -> void:
	test_add_cultivation_clamps_at_realm_cap()
	test_retreat_truncates_to_remaining_mind_and_advances_time()
	test_retreat_blocks_without_available_mind()
	test_lifespan_pills_have_diminishing_returns()
	test_forced_breakthrough_success_consumes_material_and_resets_cultivation()
	test_forced_breakthrough_failure_consumes_material_and_lifespan()
	_report()

func _make_player() -> Node:
	var player = load("res://player.gd").new()
	_owned_nodes.append(player)
	return player

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
	print("\n─── Player 单元测试 ───")
	print("通过 %d / 失败 %d" % [_passed, _failed])
	if _failed > 0:
		for message in _failures:
			print("  ✗ " + message)
		quit(1)
	else:
		print("✓ 全部通过")
		quit(0)

func test_add_cultivation_clamps_at_realm_cap() -> void:
	var player = _make_player()
	player.realm = 0
	player.cultivation = 90
	var message: String = player.add_cultivation(25)
	_expect(player.cultivation == 100, "修为不超过当前境界上限")
	_expect(message.contains("已达上限"), "达到上限时返回提示")

func test_retreat_truncates_to_remaining_mind_and_advances_time() -> void:
	var player = _make_player()
	player.mind_max = 2.0
	player.mind_used = 1
	var result: Dictionary = player.request_retreat(5)
	_expect(result.get("actual_years") == 1, "闭关年数截断为剩余心志")
	_expect(result.get("truncated") == true, "结果标记请求被截断")
	_expect(player.cultivation == 8, "实际闭关年数结算修为")
	_expect(player.age == 21 and player.lifespan == 79, "闭关同时推进年龄并扣除寿命")
	_expect(player.mind_used == 2, "闭关后累计已用心志")

func test_retreat_blocks_without_available_mind() -> void:
	var player = _make_player()
	player.mind_max = 2.0
	player.mind_used = 2
	var result: Dictionary = player.request_retreat(1)
	_expect(result.get("blocked") == true, "没有剩余心志时阻止闭关")
	_expect(player.age == 20 and player.lifespan == 80, "被阻止的闭关不推进时间")
	_expect(player.cultivation == 0, "被阻止的闭关不增加修为")

func test_lifespan_pills_have_diminishing_returns() -> void:
	var player = _make_player()
	player.add_item("延寿丹")
	player.use_item("延寿丹")
	player.add_item("延寿丹")
	player.use_item("延寿丹")
	player.add_item("延寿丹")
	player.use_item("延寿丹")
	_expect(player.lifespan == 200, "前三枚延寿丹依次增加 50、40、30 年")
	_expect(player.lifespan_max == 200, "寿命上限跟随实际寿命更新")
	_expect(player.lifespan_pill_used == 3, "记录已使用的延寿丹数量")

func test_forced_breakthrough_success_consumes_material_and_resets_cultivation() -> void:
	var player = _make_player()
	player.realm = 1
	player.cultivation = 800
	player.lifespan = 200
	player.lifespan_max = 200
	player.add_item("筑基丹")
	var result: Dictionary = player.try_breakthrough(1)
	_expect(result.get("success") == true, "强制成功结果标记成功")
	_expect(player.realm == 2 and player.cultivation == 0, "成功后晋升境界并清空修为")
	_expect(player.lifespan == 400 and player.lifespan_max == 400, "成功后按新境界增加寿命")
	_expect(not player.has_item("筑基丹"), "成功后消耗突破材料")

func test_forced_breakthrough_failure_consumes_material_and_lifespan() -> void:
	var player = _make_player()
	player.realm = 1
	player.cultivation = 800
	player.add_item("筑基丹")
	player.breakthrough_boost = 0.20
	var result: Dictionary = player.try_breakthrough(-1)
	_expect(result.get("success") == false, "强制失败结果标记失败")
	_expect(player.realm == 1 and player.cultivation == 800, "失败后保留境界和修为")
	_expect(player.lifespan == 65, "失败后扣除 15 年寿命")
	_expect(not player.has_item("筑基丹"), "失败后仍消耗突破材料")
	_expect(player.breakthrough_boost == 0.0, "突破失败后清除一次性成功率加成")
