# 小狗修仙 — 项目主文档

> **系统详情已拆分至 `design/gdd/`（CCGS 标准结构）。**
> 本文件保留：项目索引、已冻结设计决策、版本记录、运营进度、Agent 分工。

---

## 系统文档索引

| 文档 | 内容 |
|---|---|
| [game-concept.md](design/gdd/game-concept.md) | 核心理念 / 目标体验 / 核心循环 / 胜败条件 |
| [talent-system.md](design/gdd/talent-system.md) | 开局天赋分配、公式、边界 |
| [cultivation-system.md](design/gdd/cultivation-system.md) | 玩家属性、境界、闭关、突破 |
| [economy.md](design/gdd/economy.md) | 灵石、声望、寿命、道具、集市 |
| [story-system.md](design/gdd/story-system.md) | 剧情事件（普通 + 隐藏）、境界真实性、碾压模式 |
| [task-system.md](design/gdd/task-system.md) | 门派任务、评级、奖励表 |
| [title-collection.md](design/gdd/title-collection.md) | 称号、宝物图鉴 |

---

## 已确定的设计决策（冻结）

以下决策已在代码中固化，调整需修改对应逻辑：


2. **突破失败消耗道具**：`remove_item` 在成功与失败分支均调用（练气→筑基无需道具故不受影响），失败额外扣 15 年寿命。

3. **突破成功寿命累加不重置**：`lifespan += REALM_LIFESPAN[realm+1] - REALM_LIFESPAN[realm]`，保留玩家此前积累的寿命。

4. **寿命归零立即进入死亡处理**：所有行动完成后当帧判断 `lifespan <= 0`，若持有延寿丹给予紧急使用选项，否则直接 GAMEOVER。


6. **集市双重灵石检查**：UI 层禁用不可购买按钮，`_on_buy_item()` 回调内部有第二次 `if gold < price: return` 保护。

7. **境界门槛机制（min_realm）**：choice 可选字段 `min_realm` / `low_realm_result` / `low_realm_lifespan`。`_on_choice_pressed()` 在应用奖励前检查，低于门槛时跳过 gold/prestige/item，仅扣 `low_realm_lifespan` 年寿命。`low_realm_lifespan = -999` 触发必死（`pass_time(999)` 使寿命归零）。仅限直接肉搏/接触高阶灵力的选项使用，智谋/观望/逃跑类选项不加门槛。

---

## 数值红线速查（供剧情 / 任务 Agent 工作前查阅）

### 普通事件数值边界（story_one.gd）
- 灵石：-50 ~ +150
- 声望：-30 ~ +30
- 寿命：-1 ~ -7
- cultivation：固定 0
- 选项数量：固定 4

### 隐藏事件数值边界（story_more.gd）
- 灵石：+80 ~ +300
- 声望：+15 ~ +80
- 寿命：-1 ~ -4
- cultivation：固定 0
- 选项数量：2-4 浮动
- 超过半数事件要含道具奖励

### 任务奖励红线（task.gd）
- 单任务灵石上限 850（t6 SSS）
- cultivation 固定 0
- 必须七档奖励齐全（SSS/SS/S/A/B/C/D）

详见 [economy.md](design/gdd/economy.md)、[story-system.md](design/gdd/story-system.md)、[task-system.md](design/gdd/task-system.md)。

---

## 当前事件/任务数量

- **普通历练事件**：10 条（story_one.gd）
- **隐藏机缘事件**：4 / 25 条（story_more.gd），练气 3 / 筑基 1；金丹/元婴/化神池空
- **门派任务**：6 条（task.gd），覆盖练气~金丹；元婴/化神期未开发
- **称号**：14 条（items.gd）
- **宝物**：16 种含完整元数据（items.gd::ITEM_META）

---

## 当前已知问题

### 尚未修复
- **任务选项级寿命字段未应用**：`task.gd::make_choice` 记录 step_result 的 lifespan，但未扣到 player.lifespan（待验证后修复）

### 已修复
- GAMEOVER 界面展示称号与宝物图鉴（v0.6）
- 状态栏最高称号实时刷新（v0.7）

---

## 待开发功能（按优先级）

### 第一优先：填充隐藏机缘事件（story_more.gd）
补至 25 条（练气 5 / 筑基 5 / 金丹 5 / 元婴 5 / 化神 5）。当前 4 条集中在低境界，金丹/元婴/化神期完全缺失。声望系统依赖此内容。

### 第二优先：高境界任务内容（task.gd）
元婴期 / 化神期任务缺失。元婴期修仙者无任务可做。

### 第三优先：声望系统扩展
声望目前仅影响隐藏事件触发概率，可扩展为解锁特殊任务、影响门派关系等。

---

## 版本记录

| 版本 | 说明 |
|---|---|
| v0.1 | 初始版本，核心状态机 + 天赋系统 + 闭关系统完成 |
| v0.2 | 添加多步评分制门派任务（6 任务）、称号系统、宝物图鉴（items.gd） |
| v0.3 | 拆分剧情系统（story_one.gd / story_more.gd），填充 10 条历练事件，新增 items.gd 元数据 |
| v0.4 | 修复天赋界面 [+] 按钮无响应、突破材料失败不扣除、寿命累加逻辑；速悟天赋限定只影响闭关 |
| v0.5 | 解决 6 项边界问题（灵石检查、修为满禁闭关、家族冷却、寿命归零续命、自定义闭关时长、宝物集市）；任务修为奖励归零，灵石奖励相应提升 |
| v0.6 | 修复 UI 双重创建；状态界面集成称号 / 图鉴；任务结算显示家族被动收入；事件 05 文字数值修正；years_passed 全面接入 |
| v0.7 | `_update_stats()` 补充 `check_titles()` 调用；称号实时刷新 |
| v0.8 | story_more 新增 3 条隐藏机缘事件；normal 结局灵石/声望提至 CLAUDE.md 下限；story_one 7 条事件补强灰色选项 |
| v0.9 | 境界真实性重构；Event 03 min_realm 门槛；`_on_choice_pressed()` 接入门槛检查；game_design.md 写入境界真实性原则 + 设计决策 9 |
| v0.10 | 接入 CCGS 框架：配置引擎为 Godot 4.6 / GDScript；创建 docs/engine-reference/godot/VERSION.md；`game_design.md` 拆分为 7 份 design/gdd/ 系统文档 |

---

## Agent 开发分工

### 当前分工
- **剧情Agent**：只修改 `story_one.gd` / `story_more.gd`
- **任务Agent**：只修改 `task.gd`
- **逻辑Agent**：修改 `player.gd` / `game.gd` / `talent.gd`
- **整合检查Agent**：读取所有文件验证接口一致性

详细规范见 `CLAUDE.md`。

### 使用规范
- 每次多 Agent 开发完成后运行整合检查
- 每次版本更新后同步更新本文档的版本记录
- 重大设计决策确认后追加到"已确定的设计决策"章节
- 系统级设计改动应同步更新对应的 `design/gdd/*.md` 文件

---

## CCGS 常用命令（参考）

| 命令                     | 用途             |
| ---------------------- | -------------- |
| `/consistency-check`   | 校验各 GDD 与代码一致性 |
| `/balance-check`       | 校验事件/任务数值红线    |
| `/sprint-plan`         | 规划下一迭代         |
| `/dev-story`           | 执行单个 story     |
| `/architecture-review` | 架构级审查          |
| `/scope-check`         | 检查需求蔓延         |
