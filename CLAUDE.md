# 小狗修仙 — 开发规范

## 项目简介
Godot 4.6 文字修仙 Roguelike 小游戏，纯代码驱动 UI，单文件状态机。每局 30~60 分钟，凡人到飞升或寿尽。带转世遗赠 meta 累加（reincarnation.gd / user://reincarnation.cfg）。无 NPC 模拟、无世界事件、纯静态事件池 + 突破小游戏驱动。

## 文件职责
- main.gd：入口，创建UI，调用setup()；启动时载入 reincarnation 并注入 talent / player
- game.gd：状态机，驱动全部界面
- player.gd：玩家数据模型
- talent.gd：天赋分配逻辑（来世铭印分配池）
- reincarnation.gd：转世 meta progression — 跨局持久 bonus（user://reincarnation.cfg）
- task.gd：任务调度器（数据已迁至 task_easy.gd / task_normal.gd / task_hard.gd）
- story.gd：剧情协调器
- story_one.gd：普通历练事件池
- story_more.gd：隐藏机缘事件池
- items.gd：称号和宝物图鉴

## 剧情 Agent 规范

### 职责范围
只修改 `story_one.gd`（普通历练）/ `story_more.gd`（隐藏机缘）。不修改任何其他文件。

### 权威设计源
**所有写作规则、schema、数值边界、题材分布、灰色选项、离开模板均以 `design/gdd/story-system.md` 为准。每次写作前必读。**

关键章节速查：
- §3.2 选项数量（普通固定 4）+ 离开规则
- §3.4 数值字段定义表（gold/prestige/lifespan/qiyun/cultivation 上下限）
- §3.5 道具白名单（5 类）
- §3.6 气运奖励规则（qiyun 仅重要 NPC 击杀）
- §3.7 题材分布硬约束（30 事件比例表）
- §4 写作风格 9 节（含 §4.3 离开 5 套模板、§4.6 灰色选项、§4.9 anti-patterns）
- §6 数值校验公式

### 隐藏事件数值边界（story_more.gd 专用，story-system.md 不覆盖）
- 灵石：+80 ~ +300
- 声望：+15 ~ +80
- 寿命：-1 ~ -4
- 超过半数事件含道具奖励
- **cultivation 固定 0**

### 邪道隐藏事件数值边界（声望 ≤ -35 触发）
- 灵石：+80 ~ +500
- 声望：-30 ~ -60
- 寿命：-1 ~ -4
- **cultivation 固定 0**

### 跨 Agent cultivation 红线协议（Rev 3，2026-05-02）
- `story_one.gd` / `story_more.gd` 的 cultivation 字段必须 = 0（剧情 Agent 红线）
- `task_easy/normal/hard` 允许 cultivation > 0（任务 Agent 例外）
- 详见 `design/gdd/task-system.md` §3 数据填充硬约束 + §4 境界上限表

## 任务 Agent 规范

### 职责范围
只修改 `task_easy.gd` / `task_normal.gd` / `task_hard.gd` 三个文件的 TASKS 数组。
不修改 `task.gd` 调度器、不修改 handler 逻辑、不修改其他文件。

### 权威设计源
**所有 schema、奖励上限、偷修代价、宗门系数均以 `design/gdd/task-system.md` 为准。每次写作前必读。**

关键章节速查：
- §3 数据填充硬约束（含偷修 prestige -1~-3 代价、修罗门 gold ×1.5、声望 sink ×0.6）
- §4 境界 cultivation 上限表（5 / 40 / 100 / 250 / 500）
- §7 Tuning Knobs

### 三档结构
- 简单（task_easy）：固定奖励，无选择
- 普通（task_normal）：1 次选择，每选项独立返回 5 字段
- 困难（task_hard）：多步选择，每步 5 字段独立，finish 累加结算
- 三档评分（complete/partial/fail）已废除

## 逻辑 Agent 规范
可修改 `player.gd` / `game.gd` / `talent.gd`。
修改前必读 `design/gdd/` 下相关 GDD（story-system / task-system / cultivation-system / faction-system / origin-mechanism / psychology-distraction / npc-simulation）确认设计决策。
不得修改已确定的设计决策。

## 整合检查 Agent 规范
多 Agent 开发完成后运行。检查清单：
- 所有函数调用签名匹配
- 所有字段名跨文件一致
- 所有 State 有返回按钮
- `design/gdd/reviews/` review log 已知问题未回归

# --- 以下来自 Claude-Code-Game-Studios ---
> 项目级 Agent 规范（上方）定义具体文件归属与数值红线。
> 以下 CCGS 通用规范提供协作协议与编码标准框架。
> 冲突时项目级具体条款优先，通用流程默认走 CCGS。

# Claude Code Game Studios -- Game Studio Agent Architecture

Indie game development managed through 48 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Version Control**: Git with trunk-based development
- **Build System**: Godot export templates
- **Asset Pipeline**: 详见 `.claude/docs/technical-preferences.md`

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

@docs/engine-reference/godot/VERSION.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md
