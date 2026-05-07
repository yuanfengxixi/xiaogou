---
status: In Review
date: 2026-05-02
---

# 人性/分心机制

## 1. Overview

修仙者也是人。无法无视欲望与恐惧。本系统用"心志"（mind）模拟修仙者维持闭关定力的能力——单次闭关年数受 mind 上限约束，超出后会"心智不坚"，必须出门历练（触发剧情事件）才能重新闭关。心志通过历练事件缓慢成长，境界提升时按寿命上限差值大幅累加。

## 2. Player Fantasy

- 闭关不是无限计时，长时间独处会耗损心力
- 必须周期性接触世界——历练、与人互动、看修仙日常
- 心志成长源于经历，不是数值堆叠
- 高境界给更长闭关空间，但绝非无限

## 3. Detailed Rules

### 心志属性
- `mind_max: float` — 心志上限（内部 float，UI 显示 `floor(mind_max)`）
- `mind_used: int` — 当前累计闭关年数（计数器）
- 单次闭关或多次闭关累计：`mind_used` 持续累加，直到 `mind_used >= floor(mind_max)` 触发拦截

### 闭关上限约束
- 玩家发起闭关 N 年时：`available = floor(mind_max) - mind_used`
- 若 `available <= 0` → 拦截
- 若 `N > available` → 自动截断为 `available` 年完成本次闭关
- 闭关结束后 `mind_used += 实际年数`
- **mind_used 增长仅来源于 `calculate_retreat`（闭关）路径**。任务、世界事件、宗门活动、出门历练自身的 `pass_time` 调用**不计入 mind_used**。

### 拦截 UX 规范
- 拦截发生在**主面板闭关按钮层级**（不是闭关界面内部）
  - `mind_used >= floor(mind_max)` 时主面板"闭关"按钮**禁用**（灰色不可点）
  - 按钮下方/旁边显示提示文字（语气见 Open Questions A8）
  - 同时显示"出门历练"按钮（启用，与闭关按钮平级）
- **首次拦截 onboarding**：玩家首次被拦截时显示一句解释 tooltip："长期闭关耗损心力，出门历练可恢复心志。"显示后写入标记，之后不再展示。

### 截断 UX 规范
- 闭关输入界面：`available_years` 实时显示在输入框上方（如 "可闭关年数：X 年（心志已用 M/F）"）
- 玩家输入 N > available 时：
  - 输入框接受值，但提交后实际闭关 = available 年
  - 闭关结果屏顶部显示 "本次闭关因心智之故，止步于 X 年。"
  - 玩家不会以为是 bug

### 出门历练（重置）
- 历练动作：`pass_time(N)`，`N = ceil(mind_max / 10)`（**此路径 pass_time 不计入 mind_used**）
- 历练流程：
  1. 玩家点"出门历练"按钮 → game.gd 调用 `pass_time(N)`
  2. 弹出事件屏（复用 story.gd 标准事件 UI 渲染 1 个 story_one.gd EVENTS 池随机事件）
  3. 玩家完成事件选项 → 事件结果文本展示 → 关闭事件屏 → 回主面板
  4. 回到主面板的同一帧执行：`mind_used = 0`，`mind_max += 0.25`
- 玩家在主面板看到心志已重置（M=0），获得反馈感知

### 境界提升联动
- `try_breakthrough` 成功且突破后非飞升时：
  - `mind_max += (REALM_LIFESPAN[realm+1] - REALM_LIFESPAN[realm]) / 15.0`
  - 不重置 `mind_used`（突破后玩家可继续累计闭关，但通常已重置过）
- **飞升（realm 4→5）特例**：飞升即终态，**不 add mind_max**（避免 99999/15 ≈ 6666 数值爆炸）

### 心志显示
- 主面板显示：`心志：M / F`（M=`mind_used`, F=`floor(mind_max)`）
- 整数显示，不展示小数。内部 `mind_max` 仍为 float 累积
- 详情面板（如长按或点击 "i" 图标）可显示精确 `mind_max` 值（用于调试/玩家了解）

## 4. Formulas

### 变量定义
| 变量 | 类型 | 范围 | 说明 |
|------|------|------|------|
| mind_max | float | [5.0, ∞) | 心志上限，可成长 |
| mind_used | int | [0, floor(mind_max)] | 累计闭关年数 |

### 公式
- **初始**：`mind_max = 5.0`，`mind_used = 0`（练气期）
- **闭关 cap**：`available_years = floor(mind_max) - mind_used`
- **历练时长**：`N = ceil(mind_max / 10)`
- **历练完成增量**：`mind_max += 0.25`
- **突破增量**：`mind_max += (REALM_LIFESPAN[realm+1] - REALM_LIFESPAN[realm]) / 15.0`（仅当 realm+1 < 5；飞升不增长）

### 修为速率假设
本 GDD 节奏论证基于 `player.gd calculate_retreat` 当前实现：每年闭关产 8 修为（未乘 talent_speed 倍率）。该数值由 `cultivation-system.md` 锁定。若变更，节奏分析需重审。

### 例子（REALM_LIFESPAN = [80, 200, 400, 800, 1000, 99999]）

**练气期（realm 0, mind_max=5.0）**
- 闭关 cap = 5 年；历练 N = ceil(0.5) = 1 年
- 单 cycle = 5 + 1 = 6 年；+0.25 mind_max
- 突破 0→1 add = (200-80)/15 = 8.0；做 3 历练后突破 → mind_max = 5+0.75+8 = 13.75

**金丹期（realm 2, mind_max≈26）**
- 闭关 cap = 26 年；历练 N = ceil(2.6) = 3 年
- 单 cycle = 29 年；+0.25 mind_max
- 突破 2→3 add = (800-400)/15 ≈ 26.67

**化神期（realm 4, mind_max≈66）**
- 闭关 cap = 66 年；历练 N = ceil(6.6) = 7 年
- 单 cycle = 73 年；+0.25 mind_max
- 突破 4→5（飞升）：**不 add mind_max**

## 5. Edge Cases

- **mind 是 gate 而非 modifier（CLAUDE.md 红线对齐）**：CLAUDE.md "不得出现持续性效果"红线针对的是 modifier 类持续性效果（如修炼速度-20%），通过 gold/prestige/lifespan/item 四字段即时结算规避。mind 系统是**状态约束 gate**：玩家在 mind 充足时正常闭关产出，mind 耗尽时门关闭，历练后门重开。它不修改修炼效率/产出公式，只控制是否能进入闭关流程。属于不同的设计层次，不违反红线精神。

- **calculate_retreat 不感知 mind**：截断逻辑由调用层（game.gd）在调用前完成：`actual_years = min(请求年数, floor(mind_max) - mind_used)`，将 actual_years 传给 `calculate_retreat`。calculate_retreat 内 insight (10年) / danger (30年) 阈值按 actual_years 判定（不按原始请求年数）。realm 0 mind cap=5 时永不触发 insight，符合 "高境界才能享受 insight" 的设计。

- **mind_max < 1.0（不可能但保护）**：floor 为 0 时所有闭关立即拦截。逻辑层强制 `mind_max >= 1.0` clamp。

- **历练事件中途崩溃**：`mind_used` 不重置，`mind_max` 不增长。重启后玩家可重新发起历练。

- **mind_used 溢出（连续闭关无视拦截）**：拦截在 retreat 入口；任何绕过路径必须保持 `mind_used <= floor(mind_max)` 不变式。

- **突破后 mind_max 跨越整数**：mind_max=5.75 → 突破 add 8.0 → 13.75。floor 立即升 8。`mind_used` 维持原值（若 ≤ 13 则可继续闭关）。

- **历练 N=0**：mind_max < 10 时 ceil(mind_max/10) 始终 ≥ 1，无 0 风险。

- **非历练事件触发 mind 增长**：仅 story.gd 普通历练事件（story_one.gd EVENTS）。隐藏机缘 / 任务 / 突破事件不增长 mind_max。

- **历练事件四字段全生效**：触发的 story_one EVENTS 中 gold/prestige/lifespan/item 四字段**全部正常结算**，与历练时长（pass_time(N)）的寿命消耗相互独立、可叠加。例：事件 lifespan=-3 + N=1 年历练 → 总寿命扣 4。

- **历练事件玩家选错/失败选项**：选项 result 字段照常结算（即使是负面结果）。事件完成（任意选项被选）即视为"历练完成"，触发 `mind_used=0` + `mind_max+=0.25`。失败选项不阻止 mind 增长，因为"经历"本身已发生。

- **突破失败**：`try_breakthrough` 返回失败时 mind_max 不变，mind_used 不变（玩家承担本次冒险的代价；突破前 mind_used 已积累的状态保留）。失败后玩家若 mind_used 接近 cap，下次闭关会被立即拦截要求历练。

- **道具不影响 mind**：所有道具（延寿丹/破境符/聚灵丹等）均不影响 `mind_max` 或 `mind_used`。mind_max 唯二来源：历练完成 (+0.25) 与突破成功 ((new_lifespan-old_lifespan)/15)。延寿丹延长 lifespan 但不改 mind（因为公式用 REALM_LIFESPAN 数组而非 player.lifespan_max）。

## 6. Dependencies

**上游**
| 系统 | 内容 |
|------|------|
| origin-mechanism.md | 初始 `mind_max = 5.0`、`mind_used = 0` |
| player.gd | `mind_max`/`mind_used` 字段定义；`REALM_LIFESPAN = [80, 200, 400, 800, 1000, 99999]` |
| cultivation-system.md | 修为速率（当前 8/年）锁定后，本 GDD 节奏分析依赖此值 |
| story.gd / story_one.gd | 提供历练事件池；事件完成回调触发 mind_max += 0.25 + mind_used = 0 |

**下游**
| 系统 | 内容 |
|------|------|
| cultivation-system.md | 闭关流程必须读 mind cap；突破成功 mind_max += diff/15 |
| breakthrough-minigame.md | 已知不影响（突破成败由 minigame 决定，与 mind 无关） |
| game.gd | 主面板闭关按钮拦截；UI 显示心志面板；出门历练流程；首次拦截 onboarding tooltip；截断显示 |

**调用层契约**
- `calculate_retreat(years)` 不感知 mind；game.gd 调用前必须先截断：`actual_years = min(N, floor(mind_max) - mind_used)`
- 事件完成回调：story.gd 历练事件结束后必须发出信号（如 `practice_completed`），game.gd 监听并执行 `mind_used=0` + `mind_max+=0.25`

## 7. Tuning Knobs

| 参数 | 当前值 | 安全范围 | 影响 |
|------|--------|---------|------|
| 初始 mind_max | 5.0 | 3.0-10.0 | 过高早期闭关无压力；过低开局打不到 100 修为 |
| 历练事件增量 | +0.25 | 0.1-0.5（必须为 0.25 倍数） | 必须保持 0.25 倍数避免 floor/int 截断异常；过高心志膨胀过快；过低成长无感 |
| 历练时长公式 | ceil(mind_max/10) | 系数 5-15 | 系数过小历练频繁；过大历练成本太高 |
| 突破 add 系数 | 1/15 | 1/20-1/10 | 过大破境后 mind 暴涨；过小高境界 mind 拖慢闭关 |
| 历练事件池筛选 | 不筛选（story_one.gd 全池随机） | — | Phase 2 可加 realm 分档（避免化神看练气鸡毛蒜皮） |

## 8. Acceptance Criteria

- **AC 1** — GIVEN 新局 realm=0 mind_max=5.0 mind_used=0，WHEN 闭关 5 年，THEN 闭关完成，mind_used=5，下次闭关被拦截。
- **AC 2** — GIVEN mind_used=5 mind_max=5.0，WHEN 玩家在主面板查看，THEN 闭关按钮禁用（灰色），按钮旁/下显示提示文字；"出门历练"按钮可点。
- **AC 3** — GIVEN mind_used=5 mind_max=5.0，WHEN 玩家点出门历练，THEN pass_time(1)、不增加 mind_used；触发 story_one.gd EVENTS 中 1 个随机事件；事件完成（任意选项）后回主面板，mind_used=0，mind_max=5.25。
- **AC 4** — GIVEN realm=0 mind_max=5.75（已 3 次历练），WHEN 突破 0→1 成功，THEN mind_max=13.75，mind_used 不变（突破前值保留）。
- **AC 5** — GIVEN 闭关请求 N=10 mind_used=2 mind_max=5.0，WHEN game.gd 调用层执行 `actual = min(10, floor(5)-2) = 3`，THEN 实际调用 calculate_retreat(3)，mind_used=5；闭关结果屏显示 "本次闭关因心智之故，止步于 3 年"。
- **AC 6** — GIVEN realm=4 mind_max=66.5，WHEN 突破 4→5（飞升）成功，THEN mind_max=66.5 不变（飞升不 add）。
- **AC 7** — GIVEN 主面板显示，WHEN 渲染，THEN 显示 "心志：M / F"（M=mind_used 整数, F=floor(mind_max) 整数），不展示小数。详情面板可显示精确 mind_max。
- **AC 8** — GIVEN realm=0 mind_max=5.0 mind_used=0，WHEN 突破 0→1 失败，THEN mind_max=5.0 不变，mind_used=0 不变。
- **AC 9** — GIVEN 玩家完成宗门任务（任务执行 pass_time(N)），WHEN 任务结算后，THEN mind_used 不增加；玩家闭关 5 年仍可正常完成（前提 mind_used + 5 ≤ floor(mind_max)）。
- **AC 10** — GIVEN 玩家首次被拦截（mind_used 第一次达到 cap），WHEN 主面板看到禁用闭关按钮，THEN 显示 onboarding tooltip "长期闭关耗损心力，出门历练可恢复心志。"；玩家关闭/查看后写入标记；下次拦截不再展示。
- **AC 11** — GIVEN mind_used=2 mind_max=5.0，WHEN 玩家进入闭关输入界面，THEN 输入框上方显示 "可闭关年数：3 年（心志已用 2/5）"；玩家输入超过 3 时，提交后实际只闭关 3 年。
- **AC 12** — GIVEN 历练事件中玩家选择负面 result 选项（lifespan-3, gold-50），WHEN 事件结算完成，THEN lifespan 与 gold 按 result 字段扣除；同时 mind_used=0、mind_max+=0.25（"经历"本身完成）。
- **AC 13** — GIVEN 持有延寿丹/破境符，WHEN 玩家使用任一道具，THEN mind_max、mind_used 均不变。
- **AC 14** — GIVEN 闭关请求 N=20 mind_used=0 mind_max=5.0，WHEN 截断为 5 年实际闭关，THEN insight 不触发（5 < 10 阈值），danger 不触发（5 < 30 阈值）；mind_used=5。

## 9. Open Questions

- **历练事件触发率**：当前规则 "出门历练 = 触发 1 个 EVENTS"，100% 触发。是否需要随机不触发的概率？默认 100% 触发。
- **mind_max 上限**：理论无上限，但化神期初值 ≈ 66，飞升不 add。是否设硬上限（如 200）？默认无。
- **持久化**：mind_max / mind_used 当前不写存档（游戏无存档系统）。Phase 2 加存档时一并处理。AC 6（崩溃重启）依赖此项闭环。
- **Phase 2 待定**（用户标记，不在本轮处理）：
  - **A1 EVENTS 池为空 fallback**：story_one EVENTS = [] 时历练行为
  - **A8 拦截/历练文案语气**：从"心智不坚"（惩罚感）改为"久居静室，心有所动"（主动感）的具体文案
  - **A9 roguelike 单调**：天赋是否影响初始 mind_max；历练时长是否给玩家选择
- **Phase 2 增强**：
  - 历练事件按 realm 分档筛选（化神期不抽练气鸡毛蒜皮事件）
  - 化神期 cycle 节奏退化对策（13 cycle/局可能机械）
