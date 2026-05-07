extends Node

var total_points   = 0      # 起手 0 — 穿越者一无所有，天赋只能靠后天获取
var talent_speed   = 0
var talent_luck    = 0

const INTRO_TEXT := "你穿越到了修仙世界，可惜你一无所有。\n天赋一片空白，气运未染分毫。\n往后修行多艰，全凭一双脚和一颗心。"

func get_remaining() -> int:
	return total_points - talent_speed - talent_luck

func add_point(t: String) -> bool:
	if get_remaining() <= 0:
		return false
	match t:
		"speed":  talent_speed  += 1
		"luck":   talent_luck   += 1
		_: return false
	return true

func remove_point(t: String) -> bool:
	match t:
		"speed":
			if talent_speed  <= 0: return false
			talent_speed  -= 1
		"luck":
			if talent_luck   <= 0: return false
			talent_luck   -= 1
		_: return false
	return true

func apply_to_player(player):
	player.init_with_talents(talent_speed, talent_luck)

func get_speed_desc() -> String:
	var mult = 1.0 + talent_speed * 0.1
	return "修炼倍率 ×%.1f" % mult

func get_luck_desc() -> String:
	var bonus = int(talent_luck * 2)  # +0.02/pt 折算百分比
	return "突破率 +%d%%，顿悟与机缘概率提升" % bonus
