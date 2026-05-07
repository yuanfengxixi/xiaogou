# 🐕 小狗修仙 — 知识中枢

> Vault 总入口。所有路径从此扩散。

---

## 🚀 快速入口

- [[../CLAUDE|🤖 开发规范 CLAUDE.md]]
- [[../design/gdd/systems-index|📖 系统索引（CCGS）]]
- [[../production/roadmap/roadmap|🗺 路线图]]
- [[../production/devlog/_index|📝 Devlog 索引]]
- [[../production/decisions/_index|⚖ 决策记录]]
- [[../production/bugs/_index|🐛 Bug 列表]]

---

## 🎯 当前状态

```dataview
TABLE WITHOUT ID file.link AS "最近 Devlog", file.mtime AS "更新时间"
FROM "production/devlog"
WHERE file.name != "_index"
SORT file.name DESC LIMIT 5
```

---

## 🐛 待修 Bug

```dataview
TABLE severity, status, file.mtime AS "更新"
FROM "production/bugs"
WHERE status != "fixed" AND file.name != "_index"
SORT severity DESC
```

---

## 📊 内容生产进度

### 事件
- 普通历练（`story_one.gd`）：10 条
- 隐藏机缘（`story_more.gd`）：4 / 25 条
  - 练气：3
  - 筑基：1
  - 金丹 / 元婴 / 化神：0

### 任务（`task.gd`）
- 已开发：6 条（练气~金丹）
- 缺：元婴期、化神期

### 收集
- 称号：14 条（`items.gd`）
- 宝物：16 种（含元数据）

### 小游戏（8 种）
- blacktiles / memory / minesweeper / numchain / oddone / schulte / stopline / sudoku

---

## 🎮 系统模块

| 系统 | 文件 |
|------|------|
| 核心理念 | [[../design/gdd/game-concept]] |
| 修炼 | [[../design/gdd/cultivation-system]] |
| 经济 | [[../design/gdd/economy]] |
| 剧情 | [[../design/gdd/story-system]] |
| 任务 | [[../design/gdd/task-system]] |
| NPC 模拟 | [[../design/gdd/npc-simulation]] |
| 门派 | [[../design/gdd/faction-system]] |
| 多结局 | [[../design/gdd/multi-ending]] |
| 出身机制 | [[../design/gdd/origin-mechanism]] |
| 力量体系 | [[../design/gdd/power-system]] |
| 心魔分心 | [[../design/gdd/psychology-distraction]] |
| 突破小游戏 | [[../design/gdd/breakthrough-minigame]] |
| 称号收集 | [[../design/gdd/title-collection]] |
| 世界时间线 | [[../design/gdd/world-timeline-events]] |

---

## 🔥 数值红线速查

### 普通事件（story_one.gd）
- 灵石：-50 ~ +150
- 声望：-30 ~ +30
- 寿命：-1 ~ -7
- cultivation：**固定 0**
- 选项：固定 4
- 首选项：必须 `leave: true`，所有数值 0

### 隐藏事件（story_more.gd）
- 灵石：+80 ~ +300
- 声望：+15 ~ +80
- 寿命：-1 ~ -4
- cultivation：**固定 0**
- 选项：2-4 浮动
- 超过半数事件含道具奖励

### 任务（task_easy/normal/hard.gd）
- 详见 [[../design/gdd/task-system|task-system.md]] §3 数据填充硬约束 + §7 Tuning Knobs
- cultivation：练气~化神上限 5/40/100/250/500（仅敷衍偷修选项）
- 三档评分（SSS~D）已废除

---

## 🛠 模板

- [[templates/devlog|📝 Devlog 模板]]
- [[templates/adr|⚖ ADR 决策模板]]
- [[templates/event|🎲 事件模板]]
- [[templates/task|📜 任务模板]]
- [[templates/npc|👤 NPC 模板]]
- [[templates/bug|🐛 Bug 模板]]
- [[templates/minigame|🎮 小游戏模板]]

---

## 🤖 Agent 提示词

- [[prompts/story-writer|剧情 Agent]]
- [[prompts/task-writer|任务 Agent]]
- [[prompts/balance-check|平衡校验]]
- [[prompts/code-review|代码审查]]
