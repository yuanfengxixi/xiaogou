---
status: in-design
date: 2026-05-06
revision: 4
---

# 任务系统

## 1. Overview

任务系统分三档难度，由 `task.gd` 统一调度：

| 文件 | 难度 | 执行机制 |
|------|------|---------|
| `task_easy.gd` | 简单 | 时间换灵石，无选择 |
| `task_normal.gd` | 普通 | 1 个情境，1 次选择，**base + modifier 结算** |
| `task_hard.gd` | 困难 | 多步情境，多次选择，**base + Σ modifier 累加结算** |

任务来源两种：**宗门任务**（宗门弟子专属）和 **江湖悬赏**（含散修在内全员可接）。

> **架构变更（Rev 2，2026-05-02）**：废除 outcome 三档（complete/partial/fail）评分。每选项独立返回五字段；finish 直接发放（task_normal）或累加发放（task_hard）。

> **修订（Rev 3，2026-05-02）**：偷修代价 / result schema 契约 / Array[String] 道具 / lifespan 双扣 / 修罗门 gold ×1.5 multiplier（运行时）/ 任务声望 sink ×0.6 / 江湖悬赏字段约束 / abort 字段清单 / game.gd UI 重写。

> **修订（Rev 4，2026-05-06）— 透明报酬制**：每选项独立 5 字段绝对值的旧 schema 让玩家接任务前看不到承诺报酬，选项之间数值差异无来源解释。Rev 4 引入 `base_reward`（任务保底，TASK_LIST 接任务屏可见）+ `modifier`（选项浮动，TASK_STORY 选项按钮可见）双字段制。运行时结算 = `base_reward` + Σ `chosen.modifier`。修罗门 gold ×1.5 由数据填充阶段直接乘入 `base_reward.gold`，**handler 不再做运行时系数**。

## 2. Player Fantasy

修仙世界的活计，不是考试。

- 看守藏经阁就是看守藏经阁——时间换灵石，没什么好商量的
- 同一件普通任务，可以认真做，可以敷衍偷修，可以圆滑捞油水——这三种活法都能"完成"任务，但带回宗门的不一样
- 困难任务是真正的历练：每一步选什么，最后结算时灵石、声望、修为、道具一起算总账

不再有"高分"和"低分"。每个选项都对应一种真实的修仙生活方式。
认真负责的人会越来越受敬重；
敷衍偷修的人灵石照拿、私下修为偷偷涨——但被察觉一两次声望也得擦伤；
圆滑取利的人手里多几枚灵石，但师门那边的脸色不那么好看。

> **Rev 4 玩家承诺可见性**：接任务屏（TASK_LIST）显示该任务的 base_reward.gold，玩家在点"接取"前知道保底进账。任务进行中（TASK_STORY）每个选项按钮上标注 modifier 浮动（"灵石±X 声望±Y"），玩家在点选项前知道该选项相对保底的偏移。结算屏（TASK_RESULT）分三段显示：基础报酬（来自 base）、选择浮动（来自 modifier_total）、总计（base + modifier_total）。

## 3. Detailed Rules

### 任务来源

| 属性 | 宗门任务 | 江湖悬赏 |
|------|---------|---------|
| 访问权 | `player.faction != "散修"` | 全员 |
| 声望锁 | `prestige < -50` 拒绝 | 无 |
| 奖励特点 | 灵石中等，含声望/修为/特殊道具 | 灵石中等偏高，几无声望，无修为 |

### task_easy 数据结构（Rev 4）

```gdscript
{
    "id":             "te1",
    "text":           "任务名",
    "desc":           "任务描述",
    "source":         "宗门任务",   # or "江湖悬赏"
    "realm_required": 0,
    "years":          3,
    "base_reward": {
        "gold":        20,
        "prestige":    2,
        "lifespan":    0,            # 简单任务恒 0
        "cultivation": 0,            # 简单任务恒 0
        "item":        ""            # 通常空；唯一允许在 base 写道具的档（无 modifier）
    }
    # 无 choices 字段
}
```

执行：接取 → 时间流逝（pass_time(years)）→ base_reward 全字段直接发放。

### task_normal 数据结构（Rev 4）

```gdscript
{
    "id":             "tn1",
    "text":           "任务名",
    "desc":           "任务描述",
    "source":         "宗门任务",
    "realm_required": 0,
    "years":          5,
    "situation":      "情境描述文本",
    "base_reward": {
        "gold":        50,           # 任务保底灵石（认真路径或中性完成路径的金额）
        "prestige":    6,            # 任务保底声望
        "lifespan":    0,            # base 恒 0
        "cultivation": 0,            # base 恒 0
        "item":        ""            # base 恒 ""（道具仅由 modifier.item 提供）
    },
    "choices": [
        {
            "text":        "选项文字",
            "result":      "结果描述",
            "modifier": {
                "gold":        0,    # 偏离 base 的灵石浮动（可正可负）
                "prestige":    0,    # 偏离 base 的声望浮动（可正可负）
                "lifespan":    0,    # ≤0，由 game.gd 即时扣（不进 finish 累加）
                "cultivation": 0,    # ≥0，仅敷衍偷修选项；要求同选项 modifier.prestige ∈ [-3, -1]
                "item":        ""    # 选项独立给道具；空串 = 无
            }
        },
        # ... 建议 3 个选项，覆盖三种性格路线（认真/敷衍/圆滑）
    ]
}
```

执行：接取 → 展示情境 → 玩家选一次 → finish 结算 final = base + chosen.modifier。

**重要**：base_reward 代表"标准完成任务"的报酬。各选项 modifier 表达三种活法相对标准的偏离。不再使用"每选项独立绝对值"。

**base_reward.gold 选取规则（数据填充时定义）**：

| 任务来源 | base.gold 取自 | 备注 |
|---------|--------------|------|
| 宗门任务（普通） | 认真路径选项 gold | modifier.gold 圆滑选项 +20~+40，敷衍选项 0 |
| 宗门任务（修罗门特殊） | 通用同境界 base × 1.5 | modifier 浮动同上 |
| 江湖悬赏 | 中性"完成"路径选项 gold | modifier.gold 硬碰硬 +0~+15，圆滑 +20~+50，敷衍 -20~-50 |

### task_hard 数据结构（Rev 4）

```gdscript
{
    "id":             "th1",
    "text":           "任务名",
    "desc":           "任务描述",
    "source":         "宗门任务",
    "realm_required": 2,
    "years":          15,
    "base_reward": {
        "gold":        Σ steps[i].认真选项.gold,    # 各步认真路径 gold 累加
        "prestige":    Σ steps[i].认真选项.prestige, # 各步认真路径 prestige 累加
        "lifespan":    0,
        "cultivation": 0,
        "item":        ""
    },
    "steps": [
        {
            "text":     "情境描述",
            "minigame": "",                 # Phase 1 全部为空；Phase 2 可接小游戏
            "choices": [
                {
                    "text":        "选项",
                    "result":      "结果描述",
                    "modifier": {
                        "gold":        0,
                        "prestige":    0,
                        "lifespan":    0,
                        "cultivation": 0,
                        "item":        ""
                    }
                },
                # ... 建议 3 个选项每步
            ]
        }
    ]
}
```

执行：接取 → 逐步情境 → 各步选项 modifier 累加进 _acc_mod_* → finish 时 final = base + Σ modifier 一次性发放。

> Phase 1 所有 task_hard 步骤 `minigame` 字段固定空字符串。

### 数据填充硬约束（任务 Agent 自检 + design-review 校验）

**base_reward 字段约束**：

| 字段 | task_easy | task_normal | task_hard |
|------|-----------|-------------|-----------|
| gold | ≥0；按境界上限 | ≥0；按境界上限 | ≥0；Σ 各步认真选项 |
| prestige | -8 ~ +9 | -8 ~ +9 | Σ 各步认真选项 prestige，封顶 +15 |
| lifespan | **必须 0** | **必须 0** | **必须 0** |
| cultivation | **必须 0** | **必须 0** | **必须 0** |
| item | "" 或道具名 | **必须 ""** | **必须 ""** |

**modifier 字段约束（建议范围；实际差值随 base 取值变动）**：

| 字段 | 建议范围 | 备注 |
|------|---------|------|
| gold | -50 ~ +200（normal）/ -50 ~ +150 单步（hard）| 偏离 base 的灵石浮动；上限随 base 主体浮动 |
| prestige | -17 ~ +9（normal）/ -16 ~ +12 单步（hard）| 实际差值（圆滑/敷衍路径相对认真路径偏离）；硬约束改用 final.prestige 见下 |
| lifespan | -7 ~ 0 | 寿命代价；step 内 game.gd 即时扣 |
| cultivation | 0 ~ 境界上限（5/40/100/250/500） | 仅敷衍/偷修选项 |
| item | "" 或 ITEM_META 名 | 选项独立绝对值 |

**最终值硬约束（Rev 4 方案 A）**：

旧 schema 的"绝对值代价"语义在 base+modifier 拆分后由 final = base + modifier 表达。设计约束指向玩家实际感受到的 final 值，modifier 范围作为参考。

| 字段 | 硬约束 | 适用范围 |
|------|------|---------|
| final.prestige (= base.prestige + modifier.prestige) | ∈ [-3, +3] | 江湖悬赏所有 choice（AC-16） |
| final.prestige | ∈ [-3, -1] | 同选项 modifier.cultivation > 0（偷修代价，AC-17） |
| final.cultivation | 0 ~ 境界上限（5/40/100/250/500） | 受 player.add_cultivation 截断 |
| final.gold | ≥ 0 | 数据填充时由 base + min(modifier) ≥ 0 保证 |

**cultivation 选项强制约束（Rev 4 方案 A）**：
- **task_normal**：若 modifier.cultivation > 0，则同选项 final.prestige (= base_reward.prestige + modifier.prestige) 必须 ∈ [-3, -1]（偷修代价；与旧 schema "绝对值代价 -1~-3" 等价）
- **task_hard**：base 是任务级累加，step 级 final 无定义；故偷修代价改约束 modifier.prestige < 0（即偷修选项的声望差必须为负，相对认真路径有可见代价）
- 每 task_normal[i] / task_hard 全步合计：modifier.cultivation > 0 的 choice 数量 ≤ 1
- modifier.cultivation 单选项上限：5/40/100/250/500（按 realm_required 0~4）

**修罗门宗门任务约束（Rev 4 数据填充阶段）**：
- base_reward.gold 直接 = 通用同境界 base × 1.5 ±5%（数据填充阶段乘入；运行时 handler 不再乘）
- 所有非偷修选项 modifier.prestige ≤ 0（保持低声望以维持坊市权）
- 偷修选项 modifier.prestige -1~-3（同其他宗门）

**江湖悬赏字段约束（Rev 4 方案 A）**：
- 各 choice final.prestige (= base.prestige + modifier.prestige) ∈ [-3, +3]
  （base.prestige 通常 = 0；故等价于 modifier.prestige ∈ [-3, +3]）
- 各 choice modifier.cultivation **必须 0**

### 失败路径

唯一失败 = **寿命耗尽中途中止**。由 `game.gd._on_task_choice` 检测 `player.lifespan <= 0`，调用 `task.abort_current_task()`，显示中断屏。已累加但未结算的奖励**不发放**（包括 base 和 modifier 累加器）；时间已消耗（task_hard 已执行的 step lifespan 不可逆）。

宗门任务**不再因评分低而扣声望**。如玩家主动放弃任务（UI 加放弃按钮，Phase 2 范围），可在该按钮路径单独扣声望。

### task.gd 对外 API（Rev 4 不变）

```gdscript
get_available_tasks(player) -> Dictionary      # {easy:[], normal:[], hard:[]}
start_task(id: String, difficulty: String)
make_choice(index: int) -> Dictionary
finish_task(player) -> Dictionary
abort_current_task() -> void
get_normal_situation_data() -> Dictionary
get_hard_step_data() -> Dictionary
# 小游戏接口（Phase 2 使用，Phase 1 调用为 no-op）
is_awaiting_minigame() -> bool
get_current_minigame() -> String
notify_minigame_result(passed: bool) -> void
```

### make_choice / step_result schema（Rev 4）

| 字段 | 类型 | task_easy | task_normal | task_hard | 说明 |
|------|------|-----------|-------------|-----------|------|
| step | int | — | — | ✓ 当前步序号 1-based | hard 专用 |
| result | String | — | ✓ 选项 result 文本 | ✓ 选项 result 文本 | |
| modifier | Dictionary | — | ✓ 五字段 | ✓ 五字段 | 本选项浮动；UI 显示「本选项浮动」 |
| modifier.gold | int | — | ✓ 可正可负 | ✓ 可正可负 | |
| modifier.prestige | int | — | ✓ 可正可负 | ✓ 可正可负 | |
| modifier.cultivation | int | — | ✓ ≥0 | ✓ ≥0 | |
| modifier.lifespan | int | — | ✓ ≤0 | ✓ ≤0 | game.gd 即时扣 |
| modifier.item | String | — | ✓ "" or 道具名 | ✓ "" or 道具名 | |
| is_last | bool | — | ✓ true | ✓ 是否末步 | |

> task_easy 不调 make_choice。

### finish_task / result dict schema（Rev 4）

| 字段 | 类型 | task_easy | task_normal | task_hard | 说明 |
|------|------|-----------|-------------|-----------|------|
| task_text | String | ✓ | ✓ | ✓ | 任务名 |
| difficulty | String | ✓ "easy" | ✓ "normal" | ✓ "hard" | UI 分支 |
| years | int | ✓ | ✓ | ✓ | pass_time 已消耗 |
| base_reward | Dictionary | ✓ 五字段 | ✓ 五字段 | ✓ 五字段 | **Rev 4 新增**：UI 分解显示「基础报酬」 |
| modifier_total | Dictionary | ✓ 全 0 | ✓ 选中 choice 的 modifier | ✓ Σ 各步选中 modifier | **Rev 4 新增**：UI 分解显示「选择浮动」 |
| rewards | Dictionary | ✓ | ✓ | ✓ | 最终发放值 = base + modifier_total |
| rewards.gold | int | ✓ | ✓ | ✓ | 已发放给 player.gold |
| rewards.prestige | int | ✓ | ✓ | ✓ | 已应用给 player.prestige |
| rewards.cultivation | int | — | ✓ ≥0 | ✓ ≥0 | 已 add_cultivation 发放 |
| rewards.items | Array[String] | ✓ 0-1 元素 | ✓ 0-1 元素 | ✓ 0-N 元素 | 已逐项 add_item 发放 |
| step_results | Array[Dictionary] | — | — | ✓ | 各步选项快照 |
| cult_overflow_msg | String | — | ✓ "" or 溢出文 | ✓ "" or 溢出文 | finish 时一次性 add_cultivation 后取返回值 |
| is_dead | bool | ✓ | ✓ | ✓ | player.lifespan ≤ 0 |

> ⚠ score / max_score / outcome 字段 **Rev 2 起完全删除**。
> ⚠ rewards.item（单数 String）**Rev 3 起完全删除**，统一 rewards.items Array。
> ⚠ choice 顶层 gold/prestige/item/lifespan/cultivation 五字段 **Rev 4 起删除**，统一改 choice.modifier 嵌套。

**base_reward / modifier_total 子字段约定（Rev 4）**：

```
base_reward    = {gold: int, prestige: int, cultivation: int, lifespan: int, item:  String}
modifier_total = {gold: int, prestige: int, cultivation: int, lifespan: int, items: Array[String]}
```

注意非对称：
- `base_reward.item`（**单数 String**）—— 任务级保底道具，仅 task_easy 允许非空，task_normal/hard 恒 ""
- `modifier_total.items`（**复数 Array[String]**）—— task_normal 单选项 modifier.item 非空时收为单元素数组；task_hard 各步累加非空 modifier.item 成数组
- `rewards.items`（最终发放）= `([base.item] if base.item != "" else [])` + `modifier_total.items`

### 任务资格检查（task.gd 内统一执行）

1. `realm_required <= player.realm`
2. 宗门任务：`player.faction != "散修"` 且 `player.prestige >= -50`
3. 江湖悬赏：无额外限制

### Phase 2 实施清单（Rev 4 必删 / 必加）

**task.gd**
- 保留 `const PRESTIGE_LOCK = -50`
- 保留 dispatcher API 不变

**task_easy.gd**
- 字段 `reward` 重命名为 `base_reward`，加 `lifespan: 0` / `cultivation: 0` 两字段
- finish() 增加 `base_reward` 与 `modifier_total`（全 0 dict）写入返回 result

**task_normal.gd**
- 删字段：`_chosen_choice`（旧顶层五字段缓存）
- 加字段：`_chosen_modifier: Dictionary = {}`（缓存选中 choice 的 modifier 五字段）
- 删函数：所有访问 `_chosen_choice.gold/prestige/cultivation/item/lifespan` 顶层字段的代码
- finish() 重写：从 `_current_task.base_reward` + `_chosen_modifier` 合成 final，发放
- finish() 内 cultivation 调用：`player.add_cultivation(base.cultivation + modifier.cultivation)`，返回 cult_overflow_msg
- result dict 加 `base_reward` / `modifier_total` 字段
- _abort() 清空：`_current_task = {}`、`_chosen_modifier = {}`

**task_hard.gd**
- 删字段：`_acc_gold` / `_acc_prestige` / `_acc_cultivation` / `_acc_item_list`（旧累加器）
- 加字段：`_acc_mod_gold` / `_acc_mod_prestige` / `_acc_mod_cultivation` / `_acc_mod_item_list`（modifier 累加器）
- make_choice() 重写：从 `step.choices[index].modifier` 累加；不累加 lifespan（game.gd 即时扣）
- step_result schema 改：`modifier` 嵌套 dict 替换原顶层字段
- finish() 重写：final.gold = base.gold + _acc_mod_gold 等；调 player.add_cultivation 一次；逐项 add_item；调 pass_time(years)
- result dict 加 `base_reward` / `modifier_total` 字段
- _reset() 清空所有 `_acc_mod_*`

**game.gd**（任务流程函数，Rev 4 重写范围）
- `_task_reward_summary` 重写：仅显示 `base_reward.gold` 单字段，不再扫 choices 取 max
- `_show_normal_task_situation` 选项按钮文字：拼接 modifier 浮动（"灵石±X 声望±Y 修为+Z 寿命-W 获得：...")
- `_show_task_step` 选项按钮文字：同上
- `_show_step_transition`：显示本步 modifier 浮动 + 当前累计 modifier 总和
- `_show_task_result` 重写：分三段显示「基础报酬 / 选择浮动 / 总计」，从 final.base_reward / modifier_total / rewards 三 dict 取值

## 4. Formulas

**task_easy**：奖励固定值，无公式。

```
final.gold        = base_reward.gold
final.prestige    = base_reward.prestige
final.cultivation = 0
final.items       = [base_reward.item] if base_reward.item != "" else []
final.lifespan_step = 0
```

**task_normal**：
```
chosen_mod = choices[player_choice].modifier

final.gold        = base_reward.gold        + chosen_mod.gold
final.prestige    = base_reward.prestige    + chosen_mod.prestige
final.cultivation = base_reward.cultivation + chosen_mod.cultivation   # base.cultivation 恒 0
final.items       = [chosen_mod.item] if chosen_mod.item != "" else []  # base.item 恒 ""
# lifespan 由 game.gd._on_task_choice 即时扣，不进 finish 累加
```

**task_hard**：
```
acc_mod_gold        = Σ steps[i].choices[chosen_i].modifier.gold
acc_mod_prestige    = Σ steps[i].choices[chosen_i].modifier.prestige
acc_mod_cultivation = Σ steps[i].choices[chosen_i].modifier.cultivation
acc_mod_item_list   = [steps[i].choices[chosen_i].modifier.item for i if item != ""]

final.gold        = base_reward.gold        + acc_mod_gold
final.prestige    = base_reward.prestige    + acc_mod_prestige
final.cultivation = base_reward.cultivation + acc_mod_cultivation       # base.cultivation 恒 0
final.items       = acc_mod_item_list                                    # base.item 恒 ""

# lifespan 不在 finish 累加 — 已在 game.gd._on_task_choice 即时扣减
total_lifespan_cost = years + |Σ steps[i].choices[chosen_i].modifier.lifespan|   # 仅 GDD 文档参考
```

**cult_overflow_msg 触发**：
```
cult_overflow_msg = player.add_cultivation(final.cultivation)   # 仅 finish 时一次调用
```

**修罗门 base.gold 数据填充阶段乘入（Rev 4）**：
```
# 数据填充阶段（不在 handler 运行时）
if 任务条目.faction_target == "修罗门" and source == "宗门任务":
    base_reward.gold = round(generic_base_gold × 1.5)
```
> 由任务 Agent 在 TASKS 数组写数据时直接乘入。修罗门特化任务条目独立 id（如 `tn_xl_qi`），不与通用任务（如 `tn_qi`）共享。运行时 handler 一律按 `base_reward.gold` 字面值发放，**不存在 `if faction == "修罗门"` 系数分支**。

**变量定义**

| 变量 | 类型 | 范围 | 说明 |
|------|------|------|------|
| base_reward.gold | int | 0 ~ +2500（按境界），修罗门 ×1.5 数据填充 | 任务保底灵石 |
| base_reward.prestige | int | -8 ~ +15 | 任务保底声望 |
| modifier.gold | int | 建议 -50 ~ +200（normal）/ -50 ~ +150（hard 单步） | 选项灵石浮动；硬约束 final.gold ≥ 0 |
| modifier.prestige | int | 建议 -17 ~ +9（normal）/ -16 ~ +12（hard 单步） | 选项声望浮动；硬约束在 final.prestige，见 §3 最终值硬约束 |
| modifier.lifespan | int | -7 ~ 0 | 寿命代价（step 内 game.gd 即时扣） |
| modifier.cultivation | int | 0 ~ 500（按境界） | 修为增量；仅敷衍/偷修选项；要求同选项 final.prestige ∈ [-3, -1] |
| modifier.item | String | 见 items.gd ITEM_META | 道具名；空串 = 无 |

**境界上限表（modifier.cultivation 单选项）**

| 境界 | realm | 该境界总修为需求 | modifier.cultivation 单选项上限 |
|------|-------|----------------|----------------------------|
| 练气 | 0 | 100 | 5 |
| 筑基 | 1 | 800 | 40 |
| 金丹 | 2 | 2000 | 100 |
| 元婴 | 3 | 5000 | 250 |
| 化神 | 4 | 10000 | 500 |

约束：每任务最多 1 个选项给予 modifier.cultivation > 0；上限为该境界总修为需求的 5%。

**示例计算（金丹期 task_hard 三步）**

```
任务：化神师叔之劫
base_reward = {gold: 1300, prestige: +16, lifespan: 0, cultivation: 0, item: ""}
  # 各步认真选项 gold 累加：500+500+300=1300
  # 各步认真选项 prestige 累加：5+6+5=16

step1 选"立外围位偷修"：modifier = {gold:0, prestige:-7, cultivation:+90, item:""}
step2 选"上前接雷"：    modifier = {gold:0, prestige:0, cultivation:0, item:"", lifespan:-3}
step3 选"如实整理":     modifier = {gold:0, prestige:0, cultivation:0, item:"三阶破境符"}

acc_mod_gold        = 0
acc_mod_prestige    = -7
acc_mod_cultivation = +90
acc_mod_item_list   = ["三阶破境符"]

finish 总结算：
  rewards.gold        = 1300 + 0   = 1300
  rewards.prestige    = +16  + -7  = +9
  rewards.cultivation = 0    + 90  = 90（受 100 上限约束，合规）
  rewards.items       = ["三阶破境符"]
  pass_time(years=20)

UI 显示分三段：
  ─── 基础报酬 ───
  灵石 +1300
  声望 +16
  ─── 选择浮动 ───
  声望 -7
  修为 +90
  道具：三阶破境符
  ─── 总计 ───
  灵石 +1300
  声望 +9
  修为 +90
  道具：三阶破境符
  消耗寿命：-23 年
```

## 5. Edge Cases

**E1 — 散修接宗门任务**
`get_available_tasks` 在 task.gd `is_eligible` 中过滤，UI 不展示宗门任务条目。

**E2 — 声名狼藉（prestige < -50）**
仅宗门任务受锁。江湖悬赏无声望门槛，仍正常显示。

**E3 — 任务中途死亡**
`game.gd._on_task_choice` 检测 `player.lifespan <= 0`（step lifespan 已即时扣减后）→ 显示中断屏 → 调用 `task.abort_current_task()`。已累加但未结算的 task_hard 收获（`_acc_mod_gold/_acc_mod_prestige/_acc_mod_cultivation/_acc_mod_item_list`）**不发放**。base_reward 也**不发放**。pass_time(years) **不调用**——abort 路径不消耗任务总年数（仅 step lifespan 已扣）。

> Rev 3 明文继承：abort 路径下 player.age / player.lifespan 仅反映已扣的 step lifespan 之和，task base years 不再消耗。

**E4 — task_hard 小游戏字段（Phase 1）**
所有步骤 `minigame == ""`。handler 直接展示选项，不触发 `is_awaiting_minigame`。Phase 2 接入小游戏时再启用。

**E5 — runtime 状态泄漏（Rev 4 字段清单）**
`start_task` 负责清理子 handler 旧状态：

- task_easy: `_current_task = {}`
- task_normal: `_current_task = {}`, `_chosen_modifier = {}`
- task_hard: `_current_task = {}`, `_current_step = 0`, `_acc_mod_gold = 0`, `_acc_mod_prestige = 0`, `_acc_mod_cultivation = 0`, `_acc_mod_item_list = []`, `_step_results = []`, `awaiting_minigame = false`, `current_minigame_id = ""`

`finish_task` / `abort_current_task` 完成后清空 `_current_difficulty`。

**E6 — cultivation 溢出**
仅在 task_normal/task_hard finish 时 **一次** 调用 `player.add_cultivation(final.cultivation)`，该函数返回 overflow_msg。task handler 在 result dict 加 `cult_overflow_msg` 字段，game.gd `_show_task_result` 在结算文本附加显示。**禁止逐步调用 add_cultivation**——abort 路径下保证已累加 cultivation 不污染 player 状态。

**E7 — 同任务多选项 cultivation 跨步绕过单选项上限（Rev 3 强化继承）**
设计约束：每任务最多 1 选项给 modifier.cultivation。运行时由任务 Agent 自律 + design-review 校验。**handler finish 不做 sum 跨步上限截断**（仅靠 add_cultivation 内部对 REALM_REQUIRED 截断）——若数据违规多步给 cultivation，sum 仍按累加发放，但单值受 player.gd 内 `mini(cultivation + amount, REALM_REQUIRED[realm])` 截断。

**E8 — 寿命耗尽边界（Rev 3 明文继承）**
若 task_hard 选项 modifier.lifespan = -3，且选择前 player.lifespan == 2 → game.gd `_on_task_choice` `player.lifespan += -3` → lifespan = -1 → 进入中断屏，不进入下一步。已累加 `_acc_mod_*` 不发放（abort 不调 finish；累加器在 _reset 时归零）。base_reward 也不发放。任务 base years 也不消耗（pass_time 仅在 finish 调用）。

**E9 — task_hard 累加可能触发声望锁（Rev 3 提示继承）**
玩家完成 task_hard 后总 prestige 累加变化（base + modifier_total）可能跨过 -50 锁线。下一次任务列表打开时，宗门任务消失。建议 Phase 2 在 `_show_step_transition` 显示"当前累计浮动 prestige：±X"，让玩家在任务进行中即可感知风险。

**E10 — task_hard 中途死亡前置提示（Rev 3 提示继承）**
Phase 2 在 `_on_task_start` 进入 hard 任务前，UI 显示提示文本"途中若寿命耗尽，本次历练所有累积收益（含基础报酬）将不予结算"。Phase 1 范围内不实现。

**E11 — 修罗门 base.gold 数据填充阶段乘入边界（Rev 4 新增）**
若一名玩家选了修罗门 + 接修罗门特化任务（如 `tn_xl_qi` base.gold=75），handler 不再做 `× 1.5` 运行时计算。AC-18 校验数据填充正确性：通用同境界 base × 1.5 ±5% 容差。如有偏差，由任务 Agent 在数据迁移阶段修正。运行时 player.faction 字段不影响 task gold 发放金额。

**E12 — modifier 字段缺省默认值（Rev 4 新增）**
若数据条目漏写 modifier 子字段，handler 用 `Dictionary.get(key, default)` 取默认（gold/prestige/cultivation/lifespan 默认 0；item 默认 ""）。这容许数据条目仅写非零字段（如认真选项可只写 `{"gold": 0, "prestige": 0}` 而省略 lifespan/cultivation/item）。但 design-review 阶段建议数据条目五字段全填写以提升可读性。

## 6. Dependencies

**本系统依赖**

| 依赖目标 | 依赖内容 | 文件 |
|---------|---------|------|
| player.gd | `realm`/`faction`/`prestige`/`lifespan`/`pass_time`/`add_gold`/`add_prestige`/`add_item`/`add_cultivation` | player.gd |
| origin-mechanism.md | 散修 (faction="散修") 无宗门任务访问权 | design/gdd/origin-mechanism.md |
| faction-system.md | `player.faction` 决定宗门任务来源筛选；修罗门 gold ×1.5 数据填充阶段乘入 | design/gdd/faction-system.md |
| items.gd | `add_item` 后 ITEM_META 解锁与图鉴登记 | items.gd |
| psychology-distraction.md | 任务 pass_time 不计入 mind_used | design/gdd/psychology-distraction.md |

**本系统被依赖**

| 依赖方 | 依赖内容 |
|--------|---------|
| game.gd | TASK_LIST / TASK_STORY / TASK_RESULT 三个 state；`_task_reward_summary`（仅显示 base.gold）/ `_show_normal_task_situation` 与 `_show_task_step`（按钮显示 modifier）/ `_show_step_transition` / `_show_task_result`（分三段显示 base / modifier_total / rewards） |
| origin-mechanism.md | 入宗后立即可见任务列表 |
| faction-system.md | 各宗门任务池气质差异（任务 Agent 在 TASKS 数据填充时执行）；修罗门 base.gold 数据填充阶段乘 1.5 |
| player.gd | `get_hidden_event_chance` 上限 0.6 防 task prestige 失稳 |

## 7. Tuning Knobs

| 旋钮 | 位置 | 默认 | 安全范围 | 影响 |
|------|------|------|---------|------|
| 简单任务保底灵石 | task_easy.TASKS[].base_reward.gold | 见数据 | 按境界 ≤ 50% 普通任务上限 | 时间换灵石的稳定性 |
| 普通任务 base.gold | task_normal.TASKS[].base_reward.gold | 按境界 50/150/400/1000/2500 | ±30% | 任务保底灵石 |
| 普通任务 base.prestige | task_normal.TASKS[].base_reward.prestige | 按宗门任务 +6 / 江湖悬赏 0 | ±50% | 保底声望 |
| 困难任务 base.gold | task_hard.TASKS[].base_reward.gold | 各步认真选项 gold 累加 | 200/600/1600/4000/10000（练气~化神） | 高难度回报曲线 |
| modifier.gold 圆滑加成 | task_normal/hard choice.modifier.gold（圆滑选项）| +20~+40（normal）/ +10~+30（hard 单步）| ±20% | Player Fantasy "圆滑多几枚灵石" 兑现 |
| modifier.prestige 实际范围 | task_normal/hard choice.modifier.prestige | -17 ~ +9（normal）/ -16 ~ +12（hard 单步）| 同 | 性格路线声望分化（实际差值；硬约束在 final.prestige） |
| modifier.cultivation 上限 | task_normal/hard choice.modifier.cultivation | 按境界 5/40/100/250/500 | 同 | 偷修路线收益；每任务最多 1 选项；要求叠 final.prestige ∈ [-3,-1] |
| 困难任务步数 | task_hard.TASKS[].steps.size() | 3 ~ 5 | 2 ~ 6 | 任务时长感受 |
| 修罗门 base.gold ×1.5 数据填充系数（Rev 4） | task_normal/hard 修罗门数据填充时 | 1.5 | 1.0~2.0 | 无年俸宗门补偿；运行时 handler 不再有此 knob |
| 偷修代价 | modifier.cultivation>0 选项 modifier.prestige | -1~-3 | -1~-5 | Player Fantasy 三路线张力 |
| 声望锁阈值 | task.gd PRESTIGE_LOCK | -50 | -100 ~ -30 | 宗门任务封禁线 |
| hidden_event_chance 上限 | player.gd get_hidden_event_chance | 0.60 | 0.40~0.80 | 防任务 prestige 累积破坏隐藏事件稀缺感 |

> **Rev 4 删除**：旧的"运行时修罗门 gold multiplier"knob 已删除（数据填充阶段直接乘入 base_reward.gold，handler 无运行时分支）。

## 8. Acceptance Criteria

> 注：以下 AC 中标 **BLOCKED-CODE** 表示依赖 Phase B handler 重构 + Phase C UI 重写完成；标 **BLOCKED-DATA** 表示依赖 Phase D 数据迁移完成。

| AC | 测试方法 | 通过条件 | 状态 |
|----|---------|---------|------|
| AC-1 散修无宗门任务 | 开局选散修 → FREE → 任务列表 | 列表中 0 条标【宗门】条目；【悬赏】正常显示 | BLOCKED-DATA |
| AC-2 声名狼藉锁宗门任务 | 任意路径将 prestige < -50 → 任务列表 | task_list 头部"声名狼藉"警告；【宗门】消失，【悬赏】留 | BLOCKED-DATA |
| AC-3 task_easy 时间消耗与奖励 | 接取一条 te，结算 | gold/prestige 增加；player.age 增 years；player.lifespan 减 years；无选择按钮出现；result dict 含 base_reward 字段 | BLOCKED-CODE + BLOCKED-DATA |
| AC-4 task_normal final = base + modifier | 同一 task（≥2 选项）独立游戏选不同选项 | 各次 player.gold 增量 = task.base_reward.gold + chosen.modifier.gold；声望/修为/道具同理 | BLOCKED-CODE + BLOCKED-DATA |
| AC-5 task_normal cultivation 路径 | 拉满 player.cultivation 后选含 modifier.cultivation>0 选项 | player.cultivation 不超 REALM_REQUIRED；story_label 含 add_cultivation 返回的溢出文 | BLOCKED-CODE |
| AC-6 task_hard 累加结算 | 接条 ≥2 步 task_hard，记录每步选项 modifier，走完全程 | 结算屏 rewards.gold = base.gold + Σ modifier.gold；prestige 同理；items = 各步非空 modifier.item 集合 | BLOCKED-CODE + BLOCKED-DATA |
| AC-7 task_hard 寿命耗尽中止 | 构造 player.lifespan = 2，选含 modifier.lifespan=-3 的 step | 中断屏文本"寿命耗尽，任务被迫中止"；player.gold 不变；累加器 _reset 后归零；base_reward 不发放 | BLOCKED-CODE |
| AC-8 cultivation 仅指定文件（值>0） | grep 正则 `"cultivation"\s*:\s*[1-9]` story_one.gd / story_more.gd | 0 命中（占位符 `"cultivation": 0` 合规） | — |
| AC-9 modifier.cultivation 单选项境界上限 | 静态脚本 / code review：遍历 TASKS 所有 choice，modifier.cultivation>0 时验证 ≤ CULTIVATION_CAP[realm_required] | 0 违规 | BLOCKED-DATA |
| AC-10 每任务 modifier.cultivation>0 选项数 ≤ 1 | 静态脚本 / code review：task_normal 每条 choice 中 modifier.cultivation>0 数 ≤ 1；task_hard 全 steps × choices 中 modifier.cultivation>0 数 ≤ 1 | 0 违规 | BLOCKED-DATA |
| AC-11 任务列表境界过滤 | 练气期开局；筑基期通过突破或 debug → 任务列表 | 显示任务 realm_required ≤ player.realm；高境界任务不显 | BLOCKED-DATA |
| AC-12 五宗门任务池非空 | 任一宗门入宗，realm 0~4 各试一遍 → 任务列表 | 每个宗门 × 每境界至少 1 条【宗门】任务 | BLOCKED-DATA |
| AC-13 江湖悬赏全员可见 | 散修 + 5 宗门弟子（prestige 正常）→ 任务列表 | 6 次测试江湖悬赏 id 列表完全相同 | BLOCKED-DATA |
| AC-14 finish_task 后 runtime 清零 | 单元测试：start → make_choice → finish 后断言所有 runtime 字段 / UI 代理：完成一任务后立刻接第二任务，第一步文本应为新任务内容 | 所有 runtime 字段空（含 _chosen_modifier / _acc_mod_*）/ 第二任务文本正确 | BLOCKED-CODE |
| AC-15 三档评分概念已删除 | grep 正则 `"outcome"\s*[=:]|"thresholds"\s*:|"complete"\s*:|"partial"\s*:|score\s*[+]?=` 排除注释行 | task_normal.gd / task_hard.gd / task.gd 0 命中 | BLOCKED-CODE |
| AC-16 江湖悬赏 final.prestige 约束（Rev 4 方案 A） | 静态脚本：遍历 source=="江湖悬赏" 的 TASKS 各 choice，验证 (base.prestige + modifier.prestige) ∈ [-3, +3] 且 modifier.cultivation == 0 | 0 违规 | BLOCKED-DATA |
| AC-17 偷修选项强制代价（Rev 4 方案 A） | 静态脚本：(a) task_normal 所有 modifier.cultivation>0 的 choice，验证 (base.prestige + modifier.prestige) ∈ [-3, -1]；(b) task_hard 所有 modifier.cultivation>0 的 choice，验证 modifier.prestige < 0 | 0 违规 | BLOCKED-DATA |
| AC-18 修罗门 base.gold ×1.5（Rev 4 数据填充阶段校验） | 静态脚本：(a) task_normal 修罗门条目 base_reward.gold = 通用同境界 base × 1.5 ±5%（严格）；(b) task_hard 修罗门条目 base_reward.gold ≥ 同境界其他宗门 base.gold 中位数 × 1.3（宽松，hard 无统一通用基线，仅检查 1.3+ 倍差距） | 满足比例 | BLOCKED-DATA |
| AC-19 hidden_event_chance 上限 0.60 | 单元测试：player.prestige = 1000 → get_hidden_event_chance() | 返回值 ≤ 0.60 | BLOCKED-CODE（player.gd 修改，已 Rev 3 完成） |
| AC-20 result dict schema 一致性（Rev 4） | 单元测试 / code review：task_easy/normal/hard finish 返回字段含 base_reward / modifier_total / rewards 三 dict | 字段齐全；rewards.items 为 Array[String]；base_reward 五字段；modifier_total 五字段（item 取值规则：normal 取 chosen.modifier.item，hard 取 acc_mod_item_list 首项或空） | BLOCKED-CODE |
| AC-21 TASK_LIST 接任务屏仅显示 base.gold（Rev 4 新增） | UI 代理：进入 TASK_LIST 检查每条任务摘要文本 | 文本仅含"灵石 +N"（N = base_reward.gold）；不含声望、修为、道具预览 | BLOCKED-CODE |
| AC-22 选项按钮显示 modifier（Rev 4 新增） | UI 代理：进入 TASK_STORY，检查选项按钮文字 | 按钮文字格式：`[choice.text]  [灵石±X | 声望±Y | 修为+Z | 寿命-W | 获得：item]`，仅非零字段出现 | BLOCKED-CODE |
| AC-23 TASK_RESULT 三段显示（Rev 4 新增） | UI 代理：完成 task_normal / task_hard 后检查 story_label.text | 文本含"基础报酬"段（来自 base_reward）+"选择浮动"段（来自 modifier_total，仅非零字段）+"总计"段（来自 rewards） | BLOCKED-CODE |
| AC-24 旧 choice 顶层字段已删除（Rev 4 新增） | grep 正则 `choice\.gold\\|choice\.prestige\\|choice\.cultivation\\|choice\.lifespan\\|choice\.item`（task_*.gd / game.gd 任务相关函数） | 仅出现在 modifier 解构上下文（如 `choice.modifier.gold`）；无独立字段访问 | BLOCKED-CODE |

## Open Questions

1. **任务放弃按钮**：当前 game.gd 无放弃按钮路径；玩家点开任务后只能选选项不能退出。Phase 2 加放弃按钮 + 声望惩罚（仅宗门任务）。
2. **task_hard 小游戏接入**：`minigame` 字段保留但 Phase 1 全空。Phase 2 决定哪些境界/宗门接入哪种小游戏。
3. **江湖悬赏来源**：当前设计含散修可接条目。是否引入"悬赏告示牌" UI 入口？Phase 2 决定。
4. **task_hard 累加 prestige 跨锁线警告**：E9 提到 step_transition 显示当前累计 prestige，Phase 2 实现。
5. **task_hard 死亡前置提示**：E10，Phase 2 实现。
6. **task_completed signal 预埋**：Phase 2 加 faction_affinity hook 时一次性引入。
7. **base_reward.item 启用范围**（Rev 4 新增）：当前 task_easy 的 base.item 字段允许填道具（te1~te_jh_high 可选），task_normal/hard 的 base.item 强制 ""。Phase 2 视设计需要决定是否放宽 task_normal 也允许 base.item（如某任务保底必给某道具）。

## Known Gaps for Phase 2

1. 放弃按钮 + 声望惩罚路径
2. task_hard minigame 接入
3. 江湖悬赏独立 UI 入口
4. 宗门任务完成 → faction_affinity[本宗] +X 联动
5. 任务灵石压制年俸结构差距（Rev 3 user-accepted gap 继承）
6. cultivation 跨步硬截断 helper（task.gd `_validate_task`）
7. step_transition / 任务接取屏 UI 文案规范（E9/E10）
8. add_cultivation 调用时机的运行时单元测试覆盖
9. task_normal base_reward.item 启用范围（Rev 4 Open Q7）
