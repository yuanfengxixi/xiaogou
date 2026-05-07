# 起点机制

> **Status**: Approved
> **Author**: User + Claude (Sonnet 4.6)
> **Last Updated**: 2026-05-01（B1-B7 + Q1-Q10 全部修复；user 批准 Approve）
> **Implements Pillar**: 沙盒人生模拟 — 每局是独立的完整故事

## Overview

每一局，玩家以练气期凡人身份进入修仙世界，一无名望、一无宗门、身上只有四十枚灵石。在踏入世界的第一刻，唯有一个选择：**拜入宗门**，还是**成为散修**。

这是一个关于人生走向的基本决定。宗门提供任务、资源与庇护，代价是规矩与束缚；散修得到完全的自由，代价是一切靠自己。两条路是两种不同的人生，走法不同，终点也不同。

起点之后，世界就不再等你了。

## Player Fantasy

这一局从练气初成开始。你不是天选之人——世界里有人已经飞升，有人正在毁宗门，那些都与你无关。你只是一个攥着四十枚灵石的凡人，站在修仙之路的入口，做出第一个真正属于你的选择。

**拜入宗门**：走进门，有饭吃，有规矩管，有人庇护，也有人约束。修仙不是孤旅，代价是自由。宗门有任务、有坊市、有靠山——但靠山也是枷锁。

**成为散修**：转身离开，天地任你走，资源靠自己，危险也靠自己。自由是真实的，孤独也是真实的。修仙世界不保证平等——散修的路更窄、更险，机缘也更随机。这不是更好或更坏的路，是另一种活法。

选择落定之后，世界不会停下来等你适应。

---

**情绪目标：** 玩家在开局第一分钟感受到"这是一个已经在运转的大世界，我只是刚进来的那一个，我刚做出了第一个真正影响走向的选择"。既无天命感，也无压迫感（指叙事文字的主动施加语气，非禁止玩家感受紧张或恐惧）——是平静的、有重量的介入。

> **设计注：** 开局为探索阶段，玩家可依次对多家宗门参加考核。"重量感"和"不可撤销"由后续决策承担（中途退宗代价、被驱逐、归属变更等）。开局考核失败的代价是机会而非结局。

## Detailed Design

### Core Rules

**基础起点（所有路径相同）**
- 境界：练气期（realm = 0）
- 灵石：基础 40 枚 + `talent_family × 20`（实际开局值由 player.gd `init_with_talents()` 计算）
- 声望：0
- 道具：无
- 修为：0
- 寿命：80 年（REALM_LIFESPAN[0]，更新后表 `[80, 200, 400, 800, 1000, ∞]`）
- 心志上限：mind_max = 5.0（练气期，由 psychology-distraction.md 定义）
- 心志累计：mind_used = 0
- 年纪：age = 20（开局凡人入门年龄；pass_time(N) → age += N）

**开局流程**

1. 展示可加入宗门列表（5 家），每家附一行特质描述
2. 玩家选择一家发起考核，或主动选择"不入宗门"直接成为散修
3. 若选择考核：进行开局考核（文字选择类，具体形式待宗门 GDD 定义）
4. 考核通过 → 成为该宗门弟子，进入主循环
5. 考核失败 → 可选择另一家宗门重新考核；无剩余可选宗门时，自动成为散修
6. 主动选择散修 / 所有考核失败 → 以散修身份进入主循环

**拜入宗门（宗门弟子）**
- `player.faction` 写入所选宗门名
- `player.join_year = player.age`（入宗时年纪记录，用于年俸跳过入宗当年发放，见 faction-system.md §年俸）
- `faction_affinity[宗门名] = 50`（与 faction-system.md §faction_affinity 对齐；**当前版本字段尚未写入 player.gd**，待逻辑 Agent 实施）
- 解锁：宗门任务池、宗门坊市（可选使用，无强制义务）

**成为散修**
- `player.faction` = "散修"
- `player.join_year = -1`（散修无入宗年份）
- `faction_affinity` 字典保持默认零值（不主动写入，依赖 player.gd 默认初始化）
- 无任务来源（依赖世界事件与奇遇 NPC 商人）
- 无宗门约束
- 无开局补偿——散修本身意味着更高风险与更少稳定资源，这是真实世界的规则

> **平衡定位（Phase 1）**：散修在 Phase 1 是**高难度路径**（challenge path）。无年俸、无宗门坊市、无任务收入，唯一资源来源为世界事件与奇遇。Phase 2 将通过提升 `hidden_chance`（隐藏机缘触发率）与散修专属奇遇线进行平衡补偿，详见 `faction-system.md` Known Gaps §2。Phase 1 玩家选择散修应理解为主动选择更难的开局。

**归属变更接口**
- `player.faction` 字段在游戏内可被玩法事件覆写（被驱逐、中途入宗、主动退宗等）
- 归属变更后旧势力好感值保留（不归零），但原宗门的任务/商铺访问权同步消失
- 具体变更流程由势力系统 GDD 定义

### States and Transitions

| 状态 | 触发条件 | 后续 |
|------|---------|------|
| 开局选择屏 | 游戏开始 | 玩家选择宗门或散修过渡屏 |
| 考核进行中 | 选择目标宗门 | 通过 → 入宗屏；失败 → 考核失败屏（剩余 N>0）或散修过渡屏（N=0） |
| 考核失败屏 | 当次考核失败且剩余可选 N>0 | 玩家点击"返回选择" → 开局选择屏（失败宗门已移除） |
| 入宗屏 | 考核通过 | 玩家点击"进入宗门" → 主循环 |
| 散修过渡屏 | 主动选择散修 OR 第 5 次考核失败 | 玩家点击"开始" → 主循环 |
| 主循环（双路径） | 初始状态建立后 | 后续归属变更由势力 GDD 管理 |

> **实现说明**：主循环为单一状态，通过 `player.faction` 条件渲染不同 UI（宗门任务按钮仅 faction ≠ "散修" 时显示）。中途归属变更只需更新 `player.faction`，状态机不需额外状态。

### Screen Designs

各状态转换节点的语气与结构规范。本游戏文字即界面，过渡文案决定情绪是否成立。

#### 屏幕语气规范

| 场景 | 语气规范 | 禁止写法 |
|------|---------|---------|
| **开局选择屏**（首屏） | 世界正在运转，你刚进来。宗门描述用一行，写特质而非优势，不做推销 | "加入XX宗获得最强任务奖励！" |
| **考核失败屏** | 路径分叉，不是被拒绝。语气：这条路走不通，还有别的路 | "你惨败而归，颜面尽失" |
| **散修过渡屏**（被动 / 主动） | 统一文案与语气，无论主动选择还是全部考核失败。仪式感，"转身离开"的动作感，短促，有重量。两条路殊途同归，文案不区分来路 | 主动 vs 被动用不同文案；冗长解释散修利弊 |
| **考核通过 → 入宗** | 入门仪式感。一句话写入世界的感觉，不煽情 | "恭喜你成功加入XX宗！" |

#### 屏幕结构规范

**开局选择屏（首屏）**
- 信息层级：标题（一行）→ 引导文（一行）→ 宗门列表（5 项）→ 散修选项（独立区，列表底部）
- 列表项：宗门名 + 一行特质描述（≤ 24 字），按钮区域整体可点击
- 散修选项：独立按钮，文案固定 "不入宗门，转身离开"，**首屏即可见**（非考核失败后才出现）
- 滚动：列表区**纵向可滚动**，散修选项可固定页脚或随列表滚动（实现选其一，但需保证小屏可达）
- 移除（非禁用）：失败的宗门从列表节点中移除，不留禁用占位
  - *设计理由*：禁用按钮暗示"这里有东西但你不能用"；移除明确传递"这条路已关闭"，符合"路径分叉"的语义

**考核失败屏**
- 必须展示：失败宗门名（一行）+ 失败语气文案（≤ 2 行）+ **剩余可选宗门数提示**（"还有 N 家可考"）
- 操作：单按钮"返回选择" → 回到首屏（已移除失败宗门 + 散修选项仍可见）
- N=0 时不显示此屏，直接进入散修过渡屏

**散修过渡屏**（独立状态）
- 触发：① 主动选择散修按钮 ② 第 5 次考核失败（N=0）
- 内容：统一文案，3-5 行，"转身离开"动作感
- 操作：单按钮"开始" → 主循环
- 该屏**必须存在**，不可由失败屏直接跳主循环（避免情绪断裂）

**考核通过 → 入宗屏**
- 一句话入门仪式文案 + 单按钮"进入宗门" → 主循环

#### Android 平台规范
- 按钮最小 64px（与 technical-preferences.md 对齐）
- 首屏 5 家宗门 + 散修选项在 5.5 寸竖屏可能超出一屏，**必须支持纵向滑动**
- 文字行高 ≥ 1.5 倍字号；选项按钮文字 ≤ 16 字以避免折行

### Interactions with Other Systems

| 系统 | 接口方向 | 具体内容 |
|------|---------|---------|
| faction-system.md | → 下游 | 初始 `player.faction`、`player.join_year` 值与 `faction_affinity[宗门名] = 50`（设计契约，待字段实施） |
| economy.md | → 下游 | 初始 40 灵石（基础值，叠加 talent_family × 20）；宗门路可用宗门坊市 |
| task-system.md | → 下游 | 宗门路接入任务池；散修路不接入 |
| psychology-distraction.md | ← 上游 | 初始心志值由该 GDD 定义，origin 只读取（临时值 100） |

## Formulas

本系统为纯初始化/状态设定系统，无运行时数值计算。所有起点值均为固定常量：

| 属性 | 值 | 说明 |
|------|-----|------|
| `player.realm` | 0 | 练气期，固定 |
| `player.gold` | 40 | 灵石，固定不随机 |
| `player.prestige` | 0 | 声望，中立起点 |
| `player.cultivation` | 0 | 修为，从零积累 |
| `player.lifespan` | 80 | 寿命，固定（REALM_LIFESPAN[0]） |
| `player.lifespan_max` | 80 | 寿命上限 = REALM_LIFESPAN[0] |
| `player.items` | [] | 空背包 |
| `player.age` | 20 | 凡人入门年龄；替代旧 `years_passed`，pass_time(N) → age += N |
| `player.mind_max` | 5.0 | 心志上限，float；定义见 psychology-distraction.md |
| `player.mind_used` | 0 | 累计闭关年数；见 psychology-distraction.md |
| `player.faction` | 宗门名 或 "散修" | 由开局考核结果写入 |
| `player.join_year` | `player.age` 或 `-1` | 入宗 = 入宗时年纪（开局 = 20）；散修 = -1。供 faction-system.md §年俸 比对 `current_age == join_year` 跳过入宗当年发放 |
| `faction_affinity[宗门名]` | 50（仅入宗时写入） | 与 faction-system.md §faction_affinity 对齐。**字段尚未写入 player.gd，待逻辑 Agent 实施**；散修路径不写入，依赖 dict 默认零值 |
| `player.gold`（实际） | `40 + talent_family × 20` | Formulas 表中 40 为基础值。`init_with_talents()` 中根据天赋叠加，最终开局灵石可能高于 40 |

## Edge Cases

- **若所有考核均失败**：玩家自动以"散修"身份进入游戏。无惩罚标记，散修路与主动选择散修状态完全相同，不影响后续玩法。

- **若玩家在选择界面直接放弃（不参加任何考核）**：直接成为散修，等同于主动选择。

- **不可重考同一宗门**：每个宗门每局只能考核一次。失败后该宗门从可选列表中移除（不显示，而非仅禁用）。

- **考核期间游戏状态未初始化**：考核过程中玩家尚未完全进入主循环。若考核界面异常退出，保持在"开局选择屏"状态，不写入 `player.faction`，下次启动重新从选择屏开始。已失败宗门的记录不持久化——崩溃重启后所有宗门重新可选（设计决策：开局数据轻量，不值得引入持久化复杂度）。

- **心志初始值**：临时值 100 已写入 Formulas 表，待 `psychology-distraction.md` 确认后同步更新。

- **宗门好感 +50 与声望 0 的关系**：宗门好感是势力关系字段（faction_affinity），声望是玩家全局属性（prestige），两者独立，不互相影响。入宗不给声望加成。

- **散修在游戏内中途入宗**：由势力 GDD 管理。`player.faction` 可被覆写，本 GDD 只负责初始值写入。中途入宗时 `player.join_year` 由势力 GDD 写入；本 GDD 只负责开局初始化。

- **player.join_year 越界保护**：入宗时 `player.join_year = player.age`，依赖 `player.age` 已正确初始化（开局 = 20）。若 `player.age` 未初始化（崩溃恢复路径），`join_year` 默认 -1，年俸跳过逻辑由 faction-system.md 处理。

- **散修过渡屏崩溃**：若玩家在散修过渡屏关闭游戏（未点"开始"），`player.faction` 仍为空字符串，下次启动重新从开局选择屏开始（与 AC 6a 一致）。

## Dependencies

**上游（本系统依赖）：**
- `psychology-distraction.md` — 提供 `player.mind` 初始值常量（临时占位 100；**优先级提升**：自 2026-04-27 无进展，影响 AC 验证）
- `faction-system.md` — 定义考核形式与通过阈值（已闭环）；定义 `faction_affinity` 字段结构（已定义，但 player.gd 字段尚未实施）

**下游（依赖本系统）：**
- `faction-system.md` — 读取 `player.faction` 与 `player.join_year` 初始值
- `economy.md` — 读取初始灵石 40；宗门路解锁宗门坊市入口
- `task-system.md` — 宗门路才接入任务池
- 所有其他系统 — 读取 `player.realm=0` 作为初始境界

**实施侧依赖（player.gd / 逻辑 Agent）：**
- `player.join_year` 字段（int）尚未在 player.gd 中声明；逻辑 Agent 需添加
- `faction_affinity` 字典字段尚未在 player.gd 中声明；逻辑 Agent 需添加

## Tuning Knobs

| 调优项 | 当前值 | 安全范围 | 过高影响 | 过低影响 |
|--------|--------|---------|---------|---------|
| 初始灵石（基础值） | 40 | 20–80 | 早期经济节奏偏宽松，拮据感减弱 | 早期体验过于拮据 |
| 开局可选宗门数 | 5（固定） | — | — | — |
| 宗门初始好感加成 | +50 | +30–+80 | 宗门路早期 affinity 优势过大，影响中期归属变更触发 | 入宗感知不到归属感，与 faction-system.md 阈值（如 +30 解锁权益）脱节 |
| 散修 join_year | -1（固定哨兵） | — | — | — |

## Acceptance Criteria

> **字段实施缺口标记说明**：以下 AC 引用的字段中，`player.mind`、`player.join_year`、`faction_affinity` 字典尚未写入 player.gd。对这些字段的断言标记为 **BLOCKED-FIELD**，待逻辑 Agent 实施后转为可执行。`player.years_passed` 已存在，作为 join_year 的实际记录值（开局入宗 = 0）。
>
> **测试用例参数约定**：涉及 talent 的 AC 使用两个测试用例：① talent_family=0（最低）、② talent_family=5（默认中位）。

### 已实现字段 — 可立即执行

- **AC 1（可执行部分）** — **GIVEN** 新局开始，**WHEN** 玩家选择宗门 X 并通过考核，**THEN** `player.faction == "X"`，主菜单显示"宗门任务"按钮，主菜单显示"宗门坊市"入口。验证手段：UI 直接观察 + debug overlay 输出 `player.faction`。

- **AC 2（可执行部分）** — **GIVEN** 玩家全部 5 家考核均失败，**WHEN** 第 5 次失败后玩家点击散修过渡屏"开始"，**THEN** `player.faction == "散修"`，主菜单无"宗门任务"按钮，主菜单无"宗门坊市"入口。

- **AC 3** — **GIVEN** 玩家主动选择散修（talent_family=5 测试用例），**WHEN** 在散修过渡屏点击"开始"，**THEN** `player.faction == "散修"`，`player.gold == 140`（即 40 + 5 × 20，由 `init_with_talents()` 计算），`player.prestige == 0`，`player.items == []`，`player.realm == 0`，`player.cultivation == 0`，`player.lifespan == 80`，`player.age == 20`，主菜单无"宗门任务"按钮，主菜单无"宗门坊市"入口。
  - *talent_family=0 用例：`player.gold == 40`*
  - *BLOCKED-FIELD：`player.mind_max == 5.0`、`player.mind_used == 0` 待 mind 字段实施后验证*

- **AC 4** — **GIVEN** 游戏初始化（任意路径），**WHEN** 进入主循环，**THEN**：
  - `player.realm == 0`
  - `player.prestige` ∈ { 0（守一门/草门/散修）, 30（青云宗）, -30（修罗门）, 60（衍天宗） }
  - `player.items == []`
  - `player.cultivation == 0`
  - `player.lifespan == 80`
  - `player.lifespan_max == 80`
  - `player.age == 20`
  - `player.gold == 40 + talent_family × 20`（talent_family=5 → 140；talent_family=0 → 40）
  - `player.faction` ∈ { "守一门", "修罗门", "衍天宗", "青云宗", "草门", "散修" }
  - *BLOCKED-FIELD：`player.mind_max == 5.0`、`player.mind_used == 0` 待字段实施*

- **AC 5** — **GIVEN** 玩家已对宗门 X 参加过一次考核（无论通过或失败），**WHEN** 玩家尝试再次对宗门 X 发起考核，**THEN** 宗门 X 不出现在选择列表中（节点不存在于列表容器子节点中）；若通过直接调用触发，系统不修改 `player.faction`，返回无操作。

- **AC 6a** — **GIVEN** 开局考核界面已显示题目、玩家尚未提交，**WHEN** 玩家关闭游戏窗口（Alt+F4 或系统关闭按钮），**THEN** 重新启动后：显示宗门选择屏（而非主循环）；`player.faction == ""`。
  - *验证手段：① 间接验证——重启后看到宗门选择屏即说明 faction 未写入；② 直接验证——通过 debug overlay 显示 `player.faction` 字符串值；游戏当前无存档系统，不需要查存档。*

- **AC 6b** — **GIVEN** 同 AC 6a 条件，**WHEN** 通过 Task Manager 强制终止进程（PC 平台），**THEN** 结果与 AC 6a 相同。

- **AC 7** — **GIVEN** 上一局玩家对某宗门考核失败，**WHEN** 开始新的一局，**THEN** 宗门选择屏重新展示所有 5 家可选宗门，上局失败的宗门重新出现在列表中。

- **AC 8** — **GIVEN** 玩家在剩余可考宗门数 N>0 状态下考核失败，**WHEN** 失败屏显示，**THEN** 屏幕文本必须包含子串 "还有 X 家可考"（X = 5 - 已失败数）；当 X=0 时不显示此屏，直接进入散修过渡屏。

- **AC 9** — **GIVEN** 玩家全部 5 家考核失败 OR 主动选择散修，**WHEN** 触发条件成立，**THEN** 显示散修过渡屏（独立状态），玩家必须点击"开始"按钮才进入主循环；不允许从失败屏直接跳入主循环。

- **AC 10** — **GIVEN** Android 竖屏 viewport 1080×1920（xxhdpi 标准）或 720×1280（hdpi 标准），**WHEN** 进入开局选择屏，**THEN** 列表区可纵向滑动；散修选项首屏可见或可通过滑动到达（不被遮挡）；所有按钮高度 ≥ 64px（约 32dp@xxhdpi）。

- **AC 11** — **GIVEN** 玩家选择宗门 X 并通过考核（talent_family=5 测试用例），**WHEN** 点击"进入宗门"进入主循环，**THEN**：
  - `player.faction == "X"`
  - `player.realm == 0`
  - `player.cultivation == 0`
  - `player.lifespan == 80`
  - `player.lifespan_max == 80`
  - `player.age == 20`
  - `player.items == []`
  - `player.gold == 140`（40 + 5 × 20）
  - `player.prestige` 等于宗门 X 的入宗声望变更值：守一门=0、青云宗=30、修罗门=-30、衍天宗=60、草门=0
  - 主菜单显示"宗门任务"按钮 + "宗门坊市"入口
  - *talent_family=0 用例：`player.gold == 40`*
  - *BLOCKED-FIELD：`player.mind_max == 5.0`、`player.mind_used == 0`，`player.join_year == player.age`（开局入宗 = 20），`faction_affinity[X] == 50`*

- **AC 12** — **GIVEN** 上一局玩家通过考核成功入宗（faction ≠ "散修"）且玩家选择"开始新局"，**WHEN** 新局流程重新进入 NAME_INPUT 状态，**THEN**：
  - `player.faction == ""`
  - `player.realm == 0`
  - `player.cultivation == 0`
  - `player.lifespan == 80`
  - `player.lifespan_max == 80`
  - `player.gold == 0`（init_with_talents 调用前；调用后变为 `talent_family × 20`）
  - `player.prestige == 0`
  - `player.items == []`
  - `player.age == 20`
  - `player.mind_max == 5.0`
  - `player.mind_used == 0`
  - game.gd `_failed_factions == []`
  - 首次显示宗门选择屏时全部 5 家宗门均出现在列表中
  - *实施依赖：game.gd 必须有明确的 new_game/reset 逻辑保证字段重置；逻辑 Agent 需核查 `_failed_factions` 是否在 NAME_INPUT 进入时被显式 reset。*

- **AC 13** — **GIVEN** 玩家已到达散修过渡屏（主动选择或全部考核失败）但尚未点击"开始"，**WHEN** 强制终止进程（窗口关闭或任务管理器），**THEN** 重启后显示宗门选择屏（不直接进入主循环）；`player.faction == ""`；所有 5 家宗门重新可选（不持久化本局失败记录）。

- **AC 14** — **GIVEN** 玩家通过宗门考核到达入宗屏，**WHEN** 点击"进入宗门"按钮，**THEN** 直接进入主循环（不经过散修过渡屏），`player.faction == 选择的宗门名`，主菜单显示"宗门任务"按钮 + "宗门坊市"入口。这是 AC 9（"不允许从失败屏直接跳入主循环"）的正向镜像，验证入宗成功路径不被错误路由到散修屏。

### 待字段实施 — BLOCKED

- **AC 1b（BLOCKED-FIELD）** — `faction_affinity[宗门名] == 50` 入宗后验证。依赖：player.gd 添加 `faction_affinity: Dictionary` 字段；逻辑 Agent 在入宗时执行 `player.faction_affinity[faction_name] = 50`。faction-system.md §faction_affinity 已定义结构。

- **AC 1c（BLOCKED-FIELD）** — `player.join_year == player.age` 入宗后验证。依赖：player.gd 添加 `join_year: int` 字段（默认 -1）+ `age: int` 字段（默认 20）；逻辑 Agent 在入宗时执行 `player.join_year = player.age`。供 faction-system.md §年俸 比对 `current_age == join_year` 跳过入宗当年发放使用。

- **AC 2b（BLOCKED-FIELD）** — `faction_affinity` 字典所有键值均为 0，依赖 player.gd 默认 dict 初始化（散修路径不主动写入）。

- **AC 2c（BLOCKED-FIELD）** — `player.join_year == -1` 散修路径验证。同 AC 1c 依赖。

## Open Questions

- **考核形式**：五家考核全部完成设计（见 `faction-system.md` §考核系统）。本项已闭环。
- **开局宗门数量**：5 家，全部展示（已确定，与 `faction-system.md` 对齐）。
- **心志初始值**：已闭环。psychology-distraction.md 2026-05-01 完成定义。`mind_max = 5.0` `mind_used = 0` 写入 player.gd 字段。

### player.gd 字段实施缺口（BLOCKED-FIELD 项的依赖）

以下字段尚未写入 player.gd，导致部分 AC 标记为 BLOCKED-FIELD。逻辑 Agent 实施后这些 AC 转为可执行：

| 字段 | 类型 | 默认值 | 依赖 AC |
|------|------|--------|--------|
| `age` | int | 20 | AC 3, AC 4, AC 11（替代旧 `years_passed`） |
| `mind_max` | float | 5.0 | AC 3, AC 4, AC 11 |
| `mind_used` | int | 0 | AC 3, AC 4, AC 11 |
| `join_year` | int | -1 | AC 1c, AC 2c, AC 11 |
| `faction_affinity` | Dictionary | {} | AC 1b, AC 2b, AC 11 |

- **`_failed_factions` 跨局重置**：AC 12 依赖 game.gd 在 NAME_INPUT 进入时显式 reset `_failed_factions = []`。逻辑 Agent 实施 AC 12 时需核查并补齐此重置逻辑。
