# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Rendering**: Forward+ (默认)
- **Physics**: 不使用（纯文字 UI，无物理）

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC (Steam / itch), Android
- **Input Methods**: Keyboard/Mouse, Touch
- **Primary Input**: Mixed (PC 鼠标 / Android 触屏)
- **Gamepad Support**: None
- **Touch Support**: Full
- **Platform Notes**: 所有按钮最小尺寸 64px 适配触屏；无悬停交互；文字纵向滚动需支持手势滑动

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerController`)
- **Variables/Functions**: snake_case (e.g., `move_speed`, `take_damage()`)
- **Signals**: snake_case 过去式 (e.g., `health_changed`)
- **Files**: snake_case 对应类名 (e.g., `player_controller.gd`)
- **Scenes**: PascalCase 对应根节点 (e.g., `Main.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)

## Performance Budgets

- **Target Framerate**: 60 fps
- **Frame Budget**: 16.6 ms
- **Draw Calls**: < 100 (纯 UI 文字，宽松)
- **Memory Ceiling**: 200 MB (Android 低端机兼容)

## Testing

- **Framework**: GUT (Godot Unit Test)
- **Minimum Coverage**: 核心数值逻辑 80%（talent.gd 天赋分配、task.gd 评分公式、player.gd 属性变更）
- **Required Tests**: 天赋分配合法性、任务选项各字段累加正确性（gold/prestige/cultivation/lifespan/item）、剧情事件数值边界（灵石/声望/寿命/qiyun 上下限）、story.gd 事件抽取概率、leave 选项跳过 pass_time、qiyun 累加正确性、功法/气运丹 use_item 永久属性增量

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- 硬编码数值（灵石/声望/寿命等）在 game.gd / player.gd — 所有游戏数值必须由数据文件（story_one.gd / story_more.gd / task.gd 等 EVENTS/TASKS 数组）提供
- cultivation 字段给予正值 — story_one.gd / story_more.gd 仍固定为 0；task_normal.gd / task_hard.gd 允许在敷衍/取巧/偷修类选项给予 cultivation 增量，单选项上限按境界 5 / 40 / 100 / 250 / 500（练气~化神，对应 REALM_REQUIRED 5%），且每个任务最多一个选项给予
- 持续性效果（如"修炼速度 -20%"）— 所有效果必须用 gold/prestige/lifespan/item/cultivation/qiyun 六个字段即时结算（cultivation 仅任务系统适用；qiyun 仅 story_one 适用）
- 功法 / 气运丹 增加 talent_speed / talent_luck **永久属性**，属于一次性消耗结算，不算持续性效果（详见 design/gdd/story-system.md §3.5、items.gd ITEM_META）
- 跨文件职责越权 — Agent 不得修改 CLAUDE.md "文件职责" 定义外的文件
- 起手 talent_speed / talent_luck 默认 0（穿越者基线）。可由转世遗赠（`reincarnation.gd` · `user://reincarnation.cfg`）注入：累计 `bonus_start_luck` 直加 `player.talent_luck`，累计 `bonus_talent_points` 进入 `talent.total_points` 由玩家在 TALENT_ALLOCATE 屏分配到 speed / luck。运行时通过功法 / 气运丹 / 重要 NPC 击杀的 qiyun 字段进一步提升
- 突破公式中 talent_luck 系数（权威源见 design/gdd/story-system.md §9 Tuning Knobs，当前 0.02/pt）；实现于 player.gd:get_base_breakthrough_chance

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (all .gd files)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (纯代码驱动 UI，primary 覆盖)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only — 当前项目未使用)
- **Routing Notes**: 架构决策、ADR 校验、跨切面代码审查走 primary。代码质量、信号架构、静态类型强制、GDScript idioms 走 gdscript specialist。材质/着色器走 shader specialist。本项目无原生扩展，gdextension specialist 仅预留。

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
