# 小狗修仙

> Godot 4.6 文字修仙 Roguelike — 凡人到飞升或寿尽，30~60 分钟一局。

[![Engine](https://img.shields.io/badge/Engine-Godot%204.6-478CBF)](https://godotengine.org/)
[![Language](https://img.shields.io/badge/Language-GDScript-355570)](https://docs.godotengine.org/en/4.6/tutorials/scripting/gdscript/index.html)
[![Platform](https://img.shields.io/badge/Platform-PC%20%7C%20Android-blue)]()

## 简介

穿越者一无所有，靠一双脚一颗心修行至飞升。每局：

- **30~60 分钟一局**：凡人入门到飞升或寿尽
- **纯文字 UI**：代码驱动，无 NPC 模拟，无世界事件
- **静态事件池 + 突破小游戏驱动**
- **跨局 meta progression**：转世遗赠累加天赋点 / 起始灵石 / 起始气运

## 核心特性

### 玩法循环

```
凡人入门 → 选宗门 → 闭关 / 历练 / 任务 → 突破境界 → ... → 飞升 / 寿尽
   ↓
死亡 → 转世遗赠（3 选 1）→ 下一局起手 bonus 累加
```

### 系统模块

| 模块 | 文件 | 职责 |
|------|------|------|
| 状态机 | `game.gd` | 30+ State 驱动全部 UI |
| 玩家数据 | `player.gd` | 境界/修为/寿命/灵石/声望/气运/items/life_log |
| 剧情 | `story.gd` + `story_one.gd` + `story_more.gd` | 普通历练 + 隐藏机缘双池 |
| 任务 | `task.gd` + `task_easy/normal/hard.gd` | Rev 4 透明报酬制（base + modifier） |
| 天赋 | `talent.gd` | 来世铭印分配池 |
| 道具 | `items.gd` | ITEM_META 词典 + 称号 |
| 转世 | `reincarnation.gd` | 跨局 bonus（`user://reincarnation.cfg`） |

### 5 大境界

练气 → 筑基 → 金丹 → 元婴 → 化神 → 飞升

修为上限 `100 / 800 / 2000 / 5000 / 10000`，突破基础成功率 `70% / 55% / 40% / 25% / 15%`，寿命基线 `80 / 200 / 400 / 800 / 1000`。

### 9 个突破小游戏

`schulte` · `blacktiles` · `minesweeper` · `sudoku` · `memory` · `numchain` · `logic` · `stopline` · `oddone`

双入口触发：**隐藏事件**（`game.gd`） + **困难任务**（`task_hard`）。

## 技术栈

- **引擎**：Godot 4.6（Forward+ 渲染，无物理）
- **语言**：GDScript（静态类型 + signal 架构）
- **持久化**：`ConfigFile` (`user://reincarnation.cfg`)
- **平台**：PC（Steam / itch）、Android（触屏全适配，最小按钮 64px）
- **测试**：GUT (Godot Unit Test)

## 项目结构

```
xiaogou/
├── *.gd                 # 游戏代码（单文件，根目录）
├── main.tscn            # 入口场景
├── project.godot        # Godot 项目配置
├── design/
│   ├── gdd/             # 系统设计文档
│   ├── architecture-diagram.md   # 架构图（Mermaid）
│   └── registry/        # 实体注册表
├── docs/
│   └── engine-reference/godot/   # Godot 4.6 版本参考
├── content/             # 设计内容索引（事件/道具/任务/NPC/小游戏）
├── lore/                # 世界观
├── vault-meta/          # Obsidian 模板和提示词
├── production/          # 制作管理（sprint/decision/devlog/roadmap）
├── .claude/             # CCGS 48 agent 配置 + skills + hooks
└── CLAUDE.md            # Agent 协作规范
```

## 运行

### 前置

- Godot 4.6 [下载](https://godotengine.org/download)

### 启动

```bash
git clone https://github.com/yuanfengxixi/xiaogou.git
cd xiaogou
# Godot Editor 打开 project.godot → F5 运行
```

### 导出

`项目 → 导出 → 添加 PC / Android preset → 导出`

## 架构图

见 [`design/architecture-diagram.md`](design/architecture-diagram.md) — Mermaid 流程图含 6 子图（Entry / Core / Story / Task / Minigame / Persist）。

## 开发协作

本项目用 **Claude Code Game Studios** 多 Agent 框架开发，48 个专业 Agent + 80+ 技能（skill）+ git hooks 全流程。

- 文件职责红线见 [`CLAUDE.md`](CLAUDE.md)
- Agent 协作协议见 [`docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`](docs/COLLABORATIVE-DESIGN-PRINCIPLE.md)
- 设计文档规范：8 必填 section（Overview / Player Fantasy / Detailed Rules / Formulas / Edge Cases / Dependencies / Tuning Knobs / Acceptance Criteria）

### 关键红线

- **cultivation 字段红线**：`story_one.gd` / `story_more.gd` 必须 = 0；`task_easy/normal/hard.gd` 允许 > 0
- **数据驱动**：所有数值由数据文件提供，禁硬编码
- **持续效果禁令**：所有效果必须用 `gold/prestige/lifespan/item/cultivation/qiyun` 六字段即时结算

## Roadmap

- [x] Rev 4 任务系统透明报酬制（base + modifier 双字段）
- [x] 转世遗赠 meta progression（B 模式累加）
- [x] 5 境界突破系统 + 4 突破小游戏
- [x] 隐藏机缘事件多步骤协议
- [ ] 单测覆盖核心数值逻辑（player / talent / task）
- [ ] Android 包导出 + 触屏适配实测
- [ ] 命格起源系统（origin-mechanism）
- [ ] 心魔干扰系统（psychology-distraction）

## License

待定（项目内部开发中）。

## Credits

- **Game Design / Code**：yuanfengxixi
- **Engine**：[Godot Engine](https://godotengine.org/)（MIT）
- **Dev Framework**：[Claude Code Game Studios](https://github.com/anthropics/claude-code) 多 Agent 协作
