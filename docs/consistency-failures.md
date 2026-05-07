# Consistency Failures Log

Record of all 🔴 CONFLICT entries found by `/consistency-check`.
Append-only. Never delete entries.

---

### 2026-04-21 — /consistency-check — 🔴 CONFLICT (RESOLVED)

**Domain**: 修炼突破系统
**Documents involved**: `design/gdd/game-concept.md` vs `design/gdd/cultivation-system.md`
**What happened**:
- `game-concept.md` stated: "突破失败：-15 年寿命，**道具不消耗**"
- `cultivation-system.md` stated: "道具亦消耗（两个分支均调用 remove_item）"
- 代码 `player.gd::try_breakthrough` 确认：成功与失败分支均调用 `remove_item(required_item)`

**Resolution**: 修正 `game-concept.md` 为"道具同样消耗"。cultivation-system.md 是权威来源。

**Root cause**: `game-concept.md` 继承了 `game_design.md` v0.4 前的旧描述（彼时设计曾是"失败不消耗"），v0.4 修复了代码但未同步核心循环描述。

**Pattern**: 核心循环文档（game-concept）仅为高层摘要，细节与子系统 GDD 发生漂移时不易察觉。子系统 GDD 是权威来源，核心概念文档引用时应链接而非复制数值。
