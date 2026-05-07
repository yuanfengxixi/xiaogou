extends Node2D

var player
var story
var task
var talent
var items
var reincarnation
var game

func _ready():
	player        = load("res://player.gd").new()
	story         = load("res://story.gd").new()
	task          = load("res://task.gd").new()
	talent        = load("res://talent.gd").new()
	items         = load("res://items.gd").new()
	reincarnation = load("res://reincarnation.gd").new()
	game          = load("res://game.gd").new()

	add_child(player)
	add_child(story)
	add_child(task)
	add_child(talent)
	add_child(items)
	add_child(reincarnation)
	add_child(game)

	# 转世遗赠：读盘 + 注入 talent / player 起始值
	reincarnation.load_from_disk()
	reincarnation.apply_to_new_run(talent, player)

	# 用代码创建UI
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", UITheme.MARGIN_SIDE)
	margin.add_theme_constant_override("margin_right", UITheme.MARGIN_SIDE)
	margin.add_theme_constant_override("margin_top", UITheme.MARGIN_TOP)
	margin.add_theme_constant_override("margin_bottom", UITheme.MARGIN_BOTTOM)
	canvas.add_child(margin)

	var overlay = MarginContainer.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_constant_override("margin_left", UITheme.MARGIN_SIDE)
	overlay.add_theme_constant_override("margin_right", UITheme.MARGIN_SIDE)
	overlay.add_theme_constant_override("margin_top", UITheme.MARGIN_TOP)
	overlay.add_theme_constant_override("margin_bottom", UITheme.MARGIN_BOTTOM)
	overlay.visible = false
	canvas.add_child(overlay)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UITheme.VBOX_SEP)
	margin.add_child(vbox)

	var story_label = Label.new()
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	story_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	story_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	vbox.add_child(story_label)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	var stats_label = Label.new()
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	stats_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	vbox.add_child(stats_label)

	var sep2 = HSeparator.new()
	vbox.add_child(sep2)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var choices_box = VBoxContainer.new()
	choices_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices_box.size_flags_vertical = 0  # 使用自然高度，让 ScrollContainer 能滚动
	choices_box.add_theme_constant_override("separation", UITheme.CHOICE_SEP)
	scroll.add_child(choices_box)

	game.setup(player, story, task, talent, items, reincarnation, story_label, stats_label, choices_box, margin, overlay)
