extends Node

# story.gd — 事件协调器
# 普通历练事件 → story_one.gd
# 隐藏机缘事件 → story_more.gd（多轮多结局）

const StoryOne  = preload("res://story_one.gd")
const StoryMore = preload("res://story_more.gd")

func get_random_event(hidden_chance: float = 0.0) -> Dictionary:
	var adventure: Array = StoryOne.EVENTS
	var hidden:    Array = StoryMore.EVENTS

	if not hidden.is_empty() and randf() < hidden_chance:
		return {}  # 返回空字典，由 game.gd 判断后走隐藏事件流程
	return adventure[randi() % adventure.size()]

func get_hidden_event(evil_mode: bool = false) -> Dictionary:
	var hidden: Array = StoryMore.EVENTS
	var pool = hidden.filter(func(e): return e.get("evil", false) == evil_mode)
	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()]

func has_hidden_events() -> bool:
	return StoryMore.EVENTS.any(func(e): return not e.get("evil", false))

func has_evil_events() -> bool:
	return StoryMore.EVENTS.any(func(e): return e.get("evil", false))

func get_crush_choices(event: Dictionary, player_realm: int) -> Array:
	var choices = event["choices"]
	var diff = player_realm - event.get("suggested_realm", 0)
	var orig_best = 0
	var event_item = ""
	for c in choices:
		var g = c.get("gold", 0)
		if g > orig_best:
			orig_best = g
		if event_item == "" and c.get("item", "") != "":
			event_item = c["item"]
	return [
		{
			"text": "放他一条生路",
			"result": "你御空而立，气息外泄三寸，对方不战自退。这等小争端，你懒得亲自出手——悬赏与酬劳战战兢兢地奉上，有人低声感叹：「今日算是他们运气好。」",
			"cultivation": 0, "lifespan": -1, "prestige": 8,
			"gold": int(orig_best * 1.5), "item": ""
		},
		{
			"text": "一掌碾碎，以儆效尤",
			"result": "你随手一击，干净利落。对方来不及发出声音便烟消云散。旁观者噤若寒蝉，奉上的灵石比原先多了数倍——在你今日的境界面前，这不过是举手之劳，却足以令人铭记许久。",
			"cultivation": 0, "lifespan": -1, "prestige": 5 + diff * 5,
			"gold": orig_best * (2 + diff), "item": event_item
		}
	]
