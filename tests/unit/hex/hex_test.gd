extends SceneTree

# 海克斯独立测试脚本
# 运行：godot --headless --script tests/unit/hex/hex_test.gd
# 退出码：0 = 全部通过；非 0 = 至少 1 个失败
# 命名规约：test_[scenario]_[expected]（见 coding-standards.md）

var _pass: int = 0
var _fail: int = 0
var _fail_msgs: Array = []

func _init() -> void:
	print("═══ hex.gd 单元测试 ═══")
	test_pool_each_tier_has_10_entries()
	test_draw_tier_distribution_matches_30_35_35()
	test_tier_labels_cover_all_tiers()
	test_apply_gold_increments_player_gold()
	test_apply_cult_pct_scales_by_realm_required()
	test_apply_cult_pct_overflow_clamps_to_cap()
	test_apply_talent_speed_increments_player_talent_speed()
	test_apply_talent_luck_increments_player_talent_luck()
	test_apply_qiyun_routes_to_talent_luck()
	test_apply_item_appends_to_inventory()
	test_apply_item_realm_juling_picks_matching_tier()
	test_is_applicable_returns_false_when_ascended()
	test_draw_options_returns_at_most_3_unique()
	test_draw_options_size_clamped_when_applicable_pool_small()
	test_apply_records_id_in_hex_log()
	test_apply_does_not_duplicate_hex_log_entries()
	test_apply_caihex_p04_grants_both_cult_and_talent()
	test_pool_effect_types_all_whitelisted()
	test_apply_unknown_effect_type_emits_warning_no_crash()
	_report()

func _report() -> void:
	print("\n─── 结果 ───")
	print("通过 %d / 失败 %d" % [_pass, _fail])
	if _fail > 0:
		print("失败列表：")
		for m in _fail_msgs:
			print("  ✗ " + m)
		quit(1)
	else:
		print("✓ 全部通过")
		quit(0)

func _expect(cond: bool, name: String, detail: String = "") -> void:
	if cond:
		_pass += 1
		print("  ✓ " + name)
	else:
		_fail += 1
		var msg: String = name + ("  [" + detail + "]" if detail != "" else "")
		_fail_msgs.append(msg)
		print("  ✗ " + msg)

# ── 工具 ──────────────────────────────────────────────────────
func _make_player() -> Node:
	var P = load("res://player.gd").new()
	P.realm = 0
	P.cultivation = 0
	P.gold = 0
	P.talent_speed = 0
	P.talent_luck = 0
	P.items = []
	P.hex_log = []
	return P

func _load_hex() -> Node:
	return load("res://hex.gd").new()

# ── 池容量 ───────────────────────────────────────────────────
func test_pool_each_tier_has_10_entries() -> void:
	var h = _load_hex()
	_expect(h.POOL["yin"].size() == 10, "银档池 = 10")
	_expect(h.POOL["jin"].size() == 10, "金档池 = 10")
	_expect(h.POOL["caihex"].size() == 10, "彩档池 = 10")

# ── 抽档分布 ──────────────────────────────────────────────────
func test_draw_tier_distribution_matches_30_35_35() -> void:
	var h = _load_hex()
	seed(42)
	var counts: Dictionary = {"caihex": 0, "jin": 0, "yin": 0}
	var N: int = 10000
	for _i in N:
		counts[h.draw_tier()] += 1
	var cai: float = float(counts["caihex"]) / N
	var jin: float = float(counts["jin"]) / N
	var yin: float = float(counts["yin"]) / N
	_expect(abs(cai - 0.30) < 0.03, "彩档 ~30%", "实际 %.3f" % cai)
	_expect(abs(jin - 0.35) < 0.03, "金档 ~35%", "实际 %.3f" % jin)
	_expect(abs(yin - 0.35) < 0.03, "银档 ~35%", "实际 %.3f" % yin)

# ── TIER_LABELS 完整性 ──────────────────────────────────────
func test_tier_labels_cover_all_tiers() -> void:
	var h = _load_hex()
	_expect(h.TIER_LABELS.has("caihex"), "彩档 label 存在")
	_expect(h.TIER_LABELS.has("jin"), "金档 label 存在")
	_expect(h.TIER_LABELS.has("yin"), "银档 label 存在")

# ── effect: gold ─────────────────────────────────────────────
func test_apply_gold_increments_player_gold() -> void:
	var h = _load_hex()
	var p = _make_player()
	var hex_def: Dictionary = {"id": "TEST", "effects": [{"type": "gold", "value": 100}]}
	p.gold = 50
	h.apply(hex_def, p, null)
	_expect(p.gold == 150, "gold +100 累加", "got %d" % p.gold)

# ── effect: cult_pct 各境界正确按 REALM_REQUIRED 比例 ─────────
func test_apply_cult_pct_scales_by_realm_required() -> void:
	var h = _load_hex()
	for realm in range(5):
		var p = _make_player()
		p.realm = realm
		var hex_def: Dictionary = {"id": "TEST", "effects": [{"type": "cult_pct", "value": 40}]}
		h.apply(hex_def, p, null)
		var expected: int = int(p.REALM_REQUIRED[realm] * 40 / 100.0)
		_expect(p.cultivation == expected, "境界%d cult 40%% = %d" % [realm, expected],
			"got %d" % p.cultivation)

# ── effect: cult_pct 超上限自动截断 ───────────────────────────
func test_apply_cult_pct_overflow_clamps_to_cap() -> void:
	var h = _load_hex()
	var p = _make_player()
	p.realm = 0
	p.cultivation = 80
	var hex_def: Dictionary = {"id": "TEST", "effects": [{"type": "cult_pct", "value": 40}]}
	h.apply(hex_def, p, null)
	_expect(p.cultivation == 100, "cultivation 截断在 REALM_REQUIRED", "got %d" % p.cultivation)

# ── effect: talent_speed ────────────────────────────────────
func test_apply_talent_speed_increments_player_talent_speed() -> void:
	var h = _load_hex()
	var p = _make_player()
	p.talent_speed = 2
	var hex_def: Dictionary = {"id": "TEST", "effects": [{"type": "talent_speed", "value": 5}]}
	h.apply(hex_def, p, null)
	_expect(p.talent_speed == 7, "talent_speed 累加", "got %d" % p.talent_speed)

# ── effect: talent_luck ─────────────────────────────────────
func test_apply_talent_luck_increments_player_talent_luck() -> void:
	var h = _load_hex()
	var p = _make_player()
	p.talent_luck = 1
	var hex_def: Dictionary = {"id": "TEST", "effects": [{"type": "talent_luck", "value": 5}]}
	h.apply(hex_def, p, null)
	_expect(p.talent_luck == 6, "talent_luck 累加", "got %d" % p.talent_luck)

# ── effect: qiyun → 等价 talent_luck（走 add_qiyun）──────────
func test_apply_qiyun_routes_to_talent_luck() -> void:
	var h = _load_hex()
	var p = _make_player()
	p.talent_luck = 3
	var hex_def: Dictionary = {"id": "TEST", "effects": [{"type": "qiyun", "value": 8}]}
	h.apply(hex_def, p, null)
	_expect(p.talent_luck == 11, "qiyun → talent_luck +8", "got %d" % p.talent_luck)

# ── effect: item ─────────────────────────────────────────────
func test_apply_item_appends_to_inventory() -> void:
	var h = _load_hex()
	var p = _make_player()
	var hex_def: Dictionary = {"id": "TEST", "effects": [{"type": "item", "value": "延寿丹"}]}
	h.apply(hex_def, p, null)
	_expect(p.has_item("延寿丹"), "宝物加入 inventory")

# ── effect: item_realm_juling ───────────────────────────────
func test_apply_item_realm_juling_picks_matching_tier() -> void:
	var h = _load_hex()
	var names: Array = h.JLD_NAMES
	for realm in range(5):
		var p = _make_player()
		p.realm = realm
		var hex_def: Dictionary = {"id": "TEST", "effects": [{"type": "item_realm_juling", "value": ""}]}
		h.apply(hex_def, p, null)
		_expect(p.has_item(names[realm]), "境界%d 应得【%s】" % [realm, names[realm]])

# ── is_applicable: 飞升时 false ──────────────────────────────
func test_is_applicable_returns_false_when_ascended() -> void:
	var h = _load_hex()
	var p = _make_player()
	p.realm = 5  # 飞升
	var any_hex: Dictionary = h.POOL["yin"][0]
	_expect(not h.is_applicable(any_hex, p), "飞升时所有海克斯均不可应用")

# ── draw_options 上限 + 唯一性 ───────────────────────────────
func test_draw_options_returns_at_most_3_unique() -> void:
	var h = _load_hex()
	var p = _make_player()
	for _trial in 50:
		var opts: Array = h.draw_options("yin", p)
		_expect(opts.size() <= 3, "draw_options size ≤ 3", "got %d" % opts.size())
		var ids: Dictionary = {}
		for o in opts:
			_expect(not ids.has(o["id"]), "draw_options 内 hex id 不重复 (%s)" % o["id"])
			ids[o["id"]] = true

# ── draw_options: applicable 不足 3 时返回较小数组 ───────────
func test_draw_options_size_clamped_when_applicable_pool_small() -> void:
	var h = _load_hex()
	# stub: 模拟 applicable 仅 1 个的极端：让 player.realm = 4（化神），
	# 银档应仍至少有非境界宝物的 ≥ 3 个可应用，因此该测试主要校验"返回值
	# size 永远 ≤ applicable.size()"的不变量
	var p = _make_player()
	p.realm = 4  # 化神
	var opts: Array = h.draw_options("yin", p)
	_expect(opts.size() <= 3, "draw_options ≤ 3", "got %d" % opts.size())
	var applicable_count: int = 0
	for hx in h.POOL["yin"]:
		if h.is_applicable(hx, p):
			applicable_count += 1
	_expect(opts.size() <= applicable_count, "size 不超过 applicable 池",
		"opts=%d applicable=%d" % [opts.size(), applicable_count])

# ── hex_log 记录 ────────────────────────────────────────────
func test_apply_records_id_in_hex_log() -> void:
	var h = _load_hex()
	var p = _make_player()
	var hex_def: Dictionary = {"id": "TESTLOG", "effects": [{"type": "gold", "value": 1}]}
	h.apply(hex_def, p, null)
	_expect(p.hex_log.has("TESTLOG"), "hex_log 记录已选 id")

# ── hex_log 去重（防同 id 重复 append）────────────────────────
func test_apply_does_not_duplicate_hex_log_entries() -> void:
	var h = _load_hex()
	var p = _make_player()
	var hex_def: Dictionary = {"id": "DUPTEST", "effects": [{"type": "gold", "value": 1}]}
	h.apply(hex_def, p, null)
	h.apply(hex_def, p, null)
	var count: int = 0
	for id in p.hex_log:
		if id == "DUPTEST":
			count += 1
	_expect(count == 1, "hex_log 同 id 仅一条", "got %d" % count)

# ── 彩 P04 双效果（cult_pct + talent_speed）─────────────────
func test_apply_caihex_p04_grants_both_cult_and_talent() -> void:
	var h = _load_hex()
	var p = _make_player()
	p.realm = 1  # 筑基期 800
	var p04: Variant = null
	for hx in h.POOL["caihex"]:
		if hx["id"] == "P04":
			p04 = hx
			break
	_expect(p04 != null, "P04 存在于彩档池")
	if p04 == null:
		return
	h.apply(p04, p, null)
	var expected_cult: int = int(800 * 30 / 100.0)
	_expect(p.cultivation == expected_cult, "P04 修为 +30%% = %d" % expected_cult,
		"got %d" % p.cultivation)
	_expect(p.talent_speed == 1, "P04 talent_speed +1", "got %d" % p.talent_speed)

# ── 池数据合规：所有 effect.type 在白名单内 ────────────────────
func test_pool_effect_types_all_whitelisted() -> void:
	var h = _load_hex()
	# 与 apply() 的 match 分支一一对应；新增 effect type 需同步更新
	var allowed: Array = ["gold", "cult_pct", "talent_speed", "talent_luck", "qiyun",
		"item", "item_realm_juling", "item_realm_pojing"]
	for tier in ["yin", "jin", "caihex"]:
		for hx in h.POOL[tier]:
			for e in hx["effects"]:
				_expect(e["type"] in allowed, "%s 效果类型合法（%s）" % [hx["id"], e["type"]])

# ── 未知 effect type 不崩 + push_warning ─────────────────────
func test_apply_unknown_effect_type_emits_warning_no_crash() -> void:
	var h = _load_hex()
	var p = _make_player()
	var hex_def: Dictionary = {"id": "UNKNOWN", "effects": [{"type": "nonexistent", "value": 99}]}
	var msgs: Array = h.apply(hex_def, p, null)
	_expect(msgs.size() == 0, "未知 type 不产生 msg")
	_expect(p.gold == 0 and p.talent_speed == 0, "未知 type 不改 player 状态")
	_expect(p.hex_log.has("UNKNOWN"), "hex_log 仍记录")
