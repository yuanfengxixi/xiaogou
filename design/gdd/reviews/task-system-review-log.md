# task-system.md — Review Log

> 历次 /design-review 审查记录。最新在顶。

---

## Review — 2026-05-02 (Rev 3 lean re-review) — Verdict: APPROVED

Scope signal: S
Specialists: lean — 主审单 session（无 specialist 并行）
Blocking items: 0 | Recommended: 4 | Nice-to-Have: 2
Summary: Rev 2 → Rev 3 修复 12 BLOCKING + 11/13 RECOMMENDED（2 项 partial：R3 task→faction_affinity hook 留 Phase 2、R11 static typing 注释未补；R6/R7/R8 灵石→丹经济为 user-accepted gap 留 economy.md Phase 2）。新发现 4 RECOMMENDED（AC-15 grep 正则不全、AC-18 修罗门 ×1.5 容差与圆滑 delta 冲突、Section 4 修罗门公式与圆滑 delta 计算顺序未明、修罗门弟子任务可见性范围未明）+ 2 NICE-TO-HAVE。Phase 2 handler 重构可启动。
Prior verdict resolved: Yes (Rev 2 MAJOR REVISION → Rev 3 APPROVED)

---

## Review — 2026-05-02 (Rev 2 full review) — Verdict: MAJOR REVISION NEEDED

Scope signal: L
Specialists: game-designer / systems-designer / economy-designer / qa-lead / godot-gdscript-specialist / creative-director (synthesis)
Blocking items: 12 | Recommended: 13 | Nice-to-Have: 5
Summary: Rev 2 在试图打开 cultivation 红线时引入跨 4 specialist 域的连锁问题。12 项 BLOCKING 中至少 5 项触及 Player Fantasy / 经济差异化 / 跨 Agent 红线协议（治理层）：(1) 偷修选项无代价导致支配/陷阱二选一未定；(2) finish_task / step_result schema 缺失致 game.gd 静默错误；(3) rewards.item String/Array 类型冲突；(4) lifespan vs years 双重计扣未明文；(5) CLAUDE.md cultivation 红线推翻无授权；(6) 任务灵石压制年俸；(7) 修罗门弟子全局收入最低；(8) 声望无 sink → hidden_event_chance 收敛；(9) 修罗门低声望访问权 vs 任务正声望机制；(10) abort 字段清单 + PARTIAL_RATIO 删除清单缺；(11) game.gd 重写范围扩展（_show_step_transition / _show_task_result）；(12) 江湖悬赏字段约束未编码。creative-director 综合建议：先治理（ADR + CLAUDE.md）、再设计（经济模型 v2 五项打包）、最后实现（schema 冻结后落代码）。
Specialist 分歧裁定：economy（偷修是次优）vs game-designer（偷修是支配）— creative-director 裁定两者都对，时间尺度不同；根因 cultivation 任意层级无代价，须双层并修。
Prior verdict resolved: First review (Rev 2 第一轮)

---

## Rev 历史

- **Rev 1（2026-04-27）**：逆向文档，从代码提取，Needs Review 状态（无正式 review）
- **Rev 2（2026-05-02）**：首次 full /design-review；废除 outcome 三档 + 引 cultivation 偷修；MAJOR REVISION NEEDED
- **Rev 3（2026-05-02）**：lean re-review APPROVED；12 BLOCKING + 11/13 RECOMMENDED 全修
