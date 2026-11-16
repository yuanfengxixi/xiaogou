extends SceneTree

var _passed: int = 0
var _failed: int = 0
var _failures: Array[String] = []
var _owned_nodes: Array[Node] = []

func _init() -> void:
	test_task_eligibility_respects_realm_faction_and_prestige()
	test_easy_task_applies_time_and_fixed_reward()
	test_normal_task_applies_base_and_choice_modifier()
	test_hard_task_accumulates_each_step_before_finishing()
	test_aborting_hard_task_clears_step_state()
	_report()

func _make_manager() -> Node:
	var manager = load("res://task.gd").new()
	_owned_nodes.append(manager)
	manager._ready()
	_owned_nodes.append(manager._easy)
	_owned_nodes.append(manager._normal)
	_owned_nodes.append(manager._hard)
	return manager

func _make_player(realm: int = 0, faction: String = "青云宗") -> Node:
	var player = load("res://player.gd").new()
	_owned_nodes.append(player)
	player.realm = realm
	player.faction = faction
	player.gold = 0
	player.prestige = 0
	player.cultivation = 0
	player.items = []
	return player

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
	print("\n─── Task 单元测试 ───")
	print("通过 %d / 失败 %d" % [_passed, _failed])
	if _failed > 0:
		for message in _failures:
			print("  ✗ " + message)
		quit(1)
	else:
		print("✓ 全部通过")
		quit(0)

func test_task_eligibility_respects_realm_faction_and_prestige() -> void:
	var manager = _make_manager()
	var player = _make_player(0, "散修")
	var sect_task: Dictionary = {"source": "宗门任务", "realm_required": 0}
	var bounty: Dictionary = {"source": "江湖悬赏", "realm_required": 1}
	_expect(not manager.is_eligible(sect_task, player), "散修不能接宗门任务")
	_expect(not manager.is_eligible(bounty, player), "境界不足时不能接任务")
	_expect(manager.is_eligible({"source": "江湖悬赏", "realm_required": 0}, player), "散修可接符合境界的悬赏")
	player.realm = 1
	player.faction = "青云宗"
	player.prestige = -51
	_expect(not manager.is_eligible(sect_task, player), "声望低于封禁线时不能接宗门任务")
	player.prestige = -50
	_expect(manager.is_eligible(sect_task, player), "声望等于封禁线时仍可接宗门任务")

func test_easy_task_applies_time_and_fixed_reward() -> void:
	var manager = _make_manager()
	var player = _make_player()
	manager.start_task("te_qi", "easy")
	var result: Dictionary = manager.finish_task(player)
	_expect(result.get("difficulty") == "easy", "简单任务返回难度")
	_expect(result.get("years") == 3 and player.age == 23 and player.lifespan == 77, "简单任务按固定年数推进时间")
	_expect(player.gold == 20 and player.prestige == 2, "简单任务发放固定灵石与声望")
	_expect(manager._current_difficulty.is_empty(), "结束简单任务后清除调度状态")

func test_normal_task_applies_base_and_choice_modifier() -> void:
	var manager = _make_manager()
	var player = _make_player()
	manager.start_task("tn_qi", "normal")
	var situation: Dictionary = manager.get_normal_situation_data()
	_expect(situation.get("choices", []).size() == 3, "普通任务返回当前情境的三个选项")
	var choice: Dictionary = manager.make_choice(1)
	_expect(choice.get("modifier", {}).get("cultivation") == 4, "选择返回对应的修为浮动")
	var result: Dictionary = manager.finish_task(player)
	_expect(result.get("difficulty") == "normal" and result.get("years") == 5, "普通任务返回类型和时长")
	_expect(player.gold == 50 and player.prestige == -2, "普通任务将基础声望与负向修正相加")
	_expect(player.cultivation == 4 and player.age == 25 and player.lifespan == 75, "普通任务结算修为并推进时间")
	_expect(manager._current_difficulty.is_empty(), "结束普通任务后清除调度状态")

func test_hard_task_accumulates_each_step_before_finishing() -> void:
	var manager = _make_manager()
	var player = _make_player(2, "守一门")
	manager.start_task("th_sy_jindan", "hard")
	_expect(manager.get_hard_step_data().get("total_steps") == 3, "困难任务暴露三步流程")
	var first: Dictionary = manager.make_choice(1)
	var second: Dictionary = manager.make_choice(2)
	var third: Dictionary = manager.make_choice(0)
	_expect(not first.get("is_last", true) and not second.get("is_last", true) and third.get("is_last", false), "逐步推进并标记最终步骤")
	_expect(not manager.is_awaiting_minigame() and manager.get_current_minigame().is_empty(), "无小游戏步骤时不进入等待状态")
	var result: Dictionary = manager.finish_task(player)
	_expect(result.get("difficulty") == "hard" and result.get("years") == 18, "困难任务返回类型和总时长")
	_expect(player.gold == 1635 and player.prestige == 1, "困难任务累加基础奖励与三步声望/灵石修正")
	_expect(player.cultivation == 90 and player.has_item("三阶破境符"), "困难任务汇总修为和步骤道具")
	_expect(result.get("step_results", []).size() == 3 and player.age == 38 and player.lifespan == 62, "困难任务保留逐步结果并只推进一次时间")
	_expect(manager.get_hard_step_data().is_empty(), "结束困难任务后清除步骤状态")

func test_aborting_hard_task_clears_step_state() -> void:
	var manager = _make_manager()
	var player = _make_player(2, "守一门")
	manager.start_task("th_sy_jindan", "hard")
	manager.make_choice(1)
	manager.abort_current_task()
	_expect(manager._current_difficulty.is_empty(), "中止后清除调度状态")
	_expect(manager.get_hard_step_data().is_empty(), "中止后清除困难任务步骤")
	_expect(player.age == 20 and player.gold == 0, "中止任务不结算奖励和时间")
