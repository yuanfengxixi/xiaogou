# 小狗修仙 — GDD 系统索引

> 每次 `/design-review` 或 `/design-system` 完成后更新此文件。
> **Last Updated**: 2026-05-02

## 状态说明

| 状态 | 含义 |
|------|------|
| **Approved** | 已通过 /design-review，可进入实现 |
| **In Review** | 审查中或已修订，待复审 |
| **In Design** | 设计草稿，未经正式审查 |
| **Needs Review** | 逆向文档（从代码提取），需设计层审查 |
| **BLOCKED** | 依赖其他未完成 GDD，无法推进 |
| **Not Started** | 已知需要但尚未创建 |

> **Note**：标 In Design / redesign-draft 的 GDD 内部数值已被下游 Approved/In Review GDD 覆写（如 talent_luck 0.02 由 story-system.md §9 覆写 breakthrough-minigame.md）。新读者请优先查 Approved/In Review。

---

## 系统列表

| 文件 | 系统名 | 状态 | 阻塞依赖 / 备注 |
|------|--------|------|----------------|
| `game-concept.md` | 核心概念 | **Roguelike Rev 2** | 2026-05-04 重定位为 Roguelike 短局小游戏；删 NPC 模拟 + 世界 timeline 依赖 |
| `origin-mechanism.md` | 起点机制 | **Approved** | B1-B7 + Q1-Q10 全部修复 2026-05-01；14 主 AC + 4 BLOCKED-FIELD AC；player.gd 字段实施缺口（mind/join_year/faction_affinity）记录在 Open Questions |
| `faction-system.md` | 势力系统 | **In Review** | 全部五家考核 + 所有章节完成；post-review 修订完成（8项阻塞项已处理）；2026-04-30 |
| `cultivation-system.md` | 修炼系统 | In Design | redesign-draft |
| `breakthrough-minigame.md` | 突破小游戏 | In Design | redesign-draft |
| `power-system.md` | 权力等级系统 | In Design | redesign-draft |
| `economy.md` | 经济系统 | In Design | redesign-draft；Formulas 章节仍有 TBD |
| `task-system.md` | 门派任务系统 | **Approved (Rev 3)** | 2026-05-02 Rev 3：废 outcome 三档、引 cultivation 偷修代价、修罗门 ×1.5、声望 sink ×0.6；详见 `design/gdd/reviews/task-system-review-log.md` |
| `title-collection.md` | 称号图鉴 | Needs Review | 逆向文档；P0-4 计划：补负声望称号、更新道具来源、更新 Dependencies |
| `psychology-distraction.md` | 心志/分心机制 | **In Review** | 2026-05-02 /design-review 完成；9 BLOCKING 修复（mind 红线对齐/cultivation 来源/任务 pass_time 不计入/飞升不 add/截断 UX/拦截 UX/历练流程屏数/calculate_retreat 调用层截断/REALM_LIFESPAN 新值同步）；14 主 AC；A1/A8/A9 标 Phase 2 待定 |
| `multi-ending.md` | 多路线终局 | In Design | redesign-draft |
| `multi-step-events.md` | 多步骤机缘事件重写 | **In Design (v1.0)** | 2026-05-04 废 score 计分制；选项含 next/ending/minigame 三类走向；rounds 从 Array 改 Dictionary；渲染层已实施；story_more.gd 数据迁移待剧情 Agent；待 /design-review |

---

## 缺失但已被引用的 GDD（Not Started）

无。

> **2026-05-04 Roguelike 重定位**：删除 npc-simulation.md / npc-causal-events.md / world-timeline-events.md 三份 GDD + 对应实现（npc.gd / npc_sim.gd / smoke_npc.gd），game-concept.md 重写为 Roguelike 小游戏。原 NPC / 世界系统的反向引用从所有下游 GDD 中清理。

---

## 按优先级排列的下一步审查建议

1. `task-system.md` — Phase 2 handler 重构（task.gd / task_normal.gd / task_hard.gd / game.gd 三函数 + player.gd hidden_event 上限）
2. `title-collection.md` — /design-review
3. `economy.md` — 补全 Formulas 章节后 /design-review
4. Phase B 全部 In Review 后 → `/review-all-gdds`

## 实施侧待办（逻辑 Agent）

### player.gd — 已完成 2026-05-02
- [x] 删 `years_passed`，加 `age: int = 20`
- [x] 加 `mind_max: float = 5.0`、`mind_used: int = 0`
- [x] 加 `join_year: int = -1`、`faction_affinity: Dictionary = {}`
- [x] `REALM_LIFESPAN` 改为 `[80, 200, 400, 800, 1000, 99999]`
- [x] `pass_time(N)`：`age += N`
- [x] `try_breakthrough` 成功路径：`mind_max += gain / 15`（仅非飞升）
- [x] 新增辅助：`request_retreat(years)` 截断契约 / `complete_practice()` / `get_available_retreat_years()` / `get_practice_years()` / `get_mind_display()`
- [x] `get_detail_text()` 加年纪 + 心志显示

### game.gd — 已完成 2026-05-02
- [x] _stats_footer 显示年纪 + 心志（`player.age` + `player.get_mind_display()`）
- [x] 入宗写入 `player.faction_affinity[faction_name] = 50` + `player.join_year = player.age`（_on_exam_passed）
- [x] 散修 `player.join_year = -1`（_on_choose_rogue）
- [x] 闭关 UI 改用 `player.request_retreat(years)`；处理 blocked/truncated
- [x] 主面板加"出门历练"按钮（`_on_practice` handler）
- [x] 出门历练流程：pass_time(get_practice_years) + 触发普通事件（`_practice_active` 标志）+ 事件结束调 `player.complete_practice()`
- [x] 主面板拦截"闭关"按钮（`get_available_retreat_years() <= 0` 禁用 + 按钮文本提示"心智不坚"）
- [x] 闭关结果屏：truncated 时显示 "心智不坚，本次闭关止步于 X 年（原计划 Y 年）"
- [x] 闭关输入界面显示 "可闭关年数：X 年（心志：M / F）"
- [x] new_game：通过 `get_tree().reload_current_scene()` 完成 = 全字段重置自动（_on_restart）

### game.gd — 待办（Phase 2 / 优化）
- [ ] 首次拦截 onboarding tooltip + 写入标记（A7 ADVISORY）
- [ ] 出门历练事件按 realm 分档筛选（A5 Phase 2）
- [ ] 文案语气优化（A8 Phase 2 待定）

### task.gd — 已完成 2026-05-02
- [x] line 44 `:=` 类型推断错误修复（改 `var result: Dictionary = ...`）
