---
status: redesign-draft
date: 2026-05-05
revision: 3
---

# 小狗修仙 — 核心概念（Roguelike 重设计版）

## 1. Overview

小狗修仙是一款**回合制文字 Roguelike 修仙小游戏**。每局 30~60 分钟，玩家从练气期凡人开始，通过闭关 / 历练 / 任务 / 突破四个核心动作度过一生，直至飞升或寿尽。一局结束即终局，归档称号后开新局。世界不模拟、NPC 不演化——所有内容由静态事件池（剧情）+ 任务池（任务）+ 突破小游戏构成，每局通过 RNG + 玩家选择产生差异化体验。

## 2. Player Fantasy

- **一局一生**：30~60 分钟跑完一名修士从凡人到飞升/陨落的完整人生
- **博弈感**：每个选择即时结算，灰色选项暴利诱人但有代价（声望/寿命）；正义选项清贫但安全
- **境界压制真实**：突破小游戏的难度与权力差距致死规则让境界差距具有重量
- **奇遇感**：随机历练事件 + 隐藏机缘 + 道具白名单组合产生"这一局我抽到了什么"的牌局体验
- **成长可视**：通过称号收集（items.gd）形成跨局元进度，激励反复挑战

## 3. Detailed Rules

### 核心循环（单局）

```
起点（穿越 + 选宗门 / 散修）
    ↓
FREE 主面板
    ↓
[闭关] / [历练] / [任务] / [集市] / [背包] / [编年史]
    ↓
（修为满 + 持有突破物）→ 突破小游戏
    ↓
（成功）境界 +1、寿命 +N、心志 +Δ
（失败）寿命 -15、可重试
    ↓
循环至飞升（realm = 5）或寿尽（lifespan ≤ 0）
    ↓
终局回放（multi-ending）+ 称号归档
    ↓
新一局
```

### 起点（roguelike 牌局开场）

- 玩家穿越修仙世界的凡人；基线 **talent_speed = 0、talent_luck = 0、age = 20、gold = 40**
- 若已有转世遗赠累计：**player.talent_luck = bonus_start_luck**、**player.gold = 40 + bonus_start_gold**；累计天赋点 > 0 时进入 TALENT_ALLOCATE 屏由玩家分配 speed / luck
- 选择起点：4 家宗门考核（青云宗 / 修罗门 / 衍天宗 / 草门）+ 守一门保底，失败后可成为散修
- 每家宗门考核机制不同（schulte / logic / gate / 草门 30 秒），通过即入宗 + faction_affinity = 50 + 起手 prestige

### 单局动作（FREE 主面板）

| 动作 | 触发 | 主要回报 | 主要代价 |
|------|------|----------|----------|
| 闭关 | 心志 > 0 | cultivation 增 | mind_used 累 + 寿命 -N |
| 出门历练 | mind_blocked 阻断时强制 | gold / prestige / item / qiyun | 寿命 -1~-7（leave 可零代价） |
| 门派任务 | prestige > -50 | gold / prestige / cultivation / item | 寿命 + prestige sink |
| 宝物集市 | 任意（黑市需 prestige < -100） | item 购入 | gold |
| 突破 | cultivation 满 + 突破物 | realm +1 + 寿命续 | 失败 -15 寿命 |

### 内容池（一切静态、无世界模拟）

- **历练事件池**：`story_one.gd` 30 普通历练 + `story_more.gd` 隐藏机缘（prestige + qiyun 提升触发率）
- **任务池**：`task_easy.gd` / `task_normal.gd` / `task_hard.gd` 三档（宗门系数：修罗门 gold ×1.5、声望 sink ×0.6）
- **突破小游戏池**：舒尔特 / 数独 / 扫雷 / 黑格 / 记忆 / 数链 / 逻辑 / 异类（境界越高随机出题难度越大）
- **道具白名单**：聚灵丹 / 破境符 / 突破材料 / 功法 / 气运丹（详见 story-system.md §3.5）

### 终局与元进度

- 单局结束触发 `multi-ending` 终局回放（境界/声望/势力/死因维度合成）
- 称号收集（`items.gd` ITEM_META + title-collection.md）跨局持久化
- **转世遗赠 meta 累加**（`reincarnation.gd` · `user://reincarnation.cfg`）：
  - 死亡时按死亡境界 3 选 1（B 模式）：天赋点 / 灵石继承（×10%）/ 气运
  - 飞升时三项全拿（×100% 灵石），飞升后 lives 计数重置
  - 累计无 cap（设计预留 — 若后续平衡破坏可加 cap）
- 无解锁分支 / 无世界状态保存——基线仍 run-based，meta 仅注入起手 talent / gold / luck

## 4. Formulas

具体数值由各子系统 GDD 定义。本概念层不锁数。

- 突破成功率：见 `breakthrough-minigame.md` + `player.gd:get_breakthrough_chance`
- 境界寿命表：见 `player.gd:REALM_LIFESPAN = [80, 200, 400, 800, 1000, 99999]`
- 境界修为表：见 `player.gd:REALM_REQUIRED = [100, 800, 2000, 5000, 10000, 99999]`
- 心志阀：见 `psychology-distraction.md`

## 5. Edge Cases

- **权力悬殊**：突破小游戏的难度阶梯吸收权力差距，高境界 mini-game 客观难度高
- **延寿手段**：延寿丹（药效递减）+ 突破成功固定续寿；上限受 REALM_LIFESPAN 限制
- **心志阻断**：mind_used 满 → 闭关按钮置灰，必须先出门历练恢复
- **走投无路**：prestige < -50 任务系统锁死、prestige < -100 切黑市；可通过历练正义选项恢复
- **leave 刷池**：玩家可一直点离开刷历练池——接受此 UX 取舍（mind 不恢复，刷不出收益）

## 6. Dependencies

- `cultivation-system.md` — 修为 + 境界推进
- `breakthrough-minigame.md` — 突破挑战实现
- `story-system.md` — 历练事件 schema + 写作风格 + 题材分布
- `task-system.md` — 任务三档 schema + 偷修代价 + 宗门系数
- `psychology-distraction.md` — 心志阀
- `faction-system.md` — 宗门考核 + faction_affinity
- `origin-mechanism.md` — 起点流程 + 散修过渡
- `power-system.md` — 境界差距致死规则（保留为突破/历练叙事支撑）
- `multi-ending.md` — 终局生成
- `title-collection.md` — 称号收集（元进度）
- `economy.md` — gold sink/faucet 平衡

> **已删除依赖**（2026-05-04 重设计）：~~npc-simulation.md~~、~~npc-causal-events.md~~、~~world-timeline-events.md~~

## 7. Tuning Knobs

| 旋钮 | 安全范围 | 影响 |
|------|---------|------|
| 单局目标时长 | 30~60 分钟 | 闭关/历练节奏 |
| 隐藏事件触发率 | 0% ~ 60% | get_hidden_event_chance() |
| 突破基础成功率表 | 见 REALM_BASE_CHANCE | 局难度曲线 |
| 心志上限初值 | 5.0 | mind_max 起手值 |
| 历练 mind_max 增量 | 0.25 | PRACTICE_MIND_GAIN |

## 8. Acceptance Criteria

- [ ] 玩家可在 30~60 分钟内跑完一局（凡人到飞升或寿尽）
- [ ] 突破必须通过小游戏，非纯概率
- [ ] 境界差距过大的对抗触发即死判定（power-system 保留）
- [ ] 一局以寿命耗尽或飞升结束，触发终局回放
- [ ] 称号在跨局间持久（title-collection 持久层）
- [ ] 无 NPC 模拟、无世界 timeline、无大事件触发——一切由静态池驱动
- [ ] 玩家选择即时结算，无延迟生效（无 NPC 反扑、无 N 年后回响）
