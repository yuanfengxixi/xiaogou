---
status: redesign-draft
date: 2026-05-04
revision: 1
---

# 多步骤事件系统（重写 v2.0）

**版本**：1.0
**最后更新**：2026-05-04
**适用文件**：`story_more.gd`（事件数据）、`game.gd`（渲染层 _show_hidden_round / _on_hidden_choice / _finish_hidden_event）
**关联系统**：story-system.md（写作风格）、minigame_*.gd（小游戏组件）

---

## 1. Overview

多步骤事件（hidden event / 机缘事件）是触发概率受 prestige + qiyun 影响的稀有剧情。本 GDD 重写其机理：

**旧机理**（废除）：N 轮固定 → 每选项 score 0-3 → 累积分数 → perfect/good/normal/special 三档结局
**新机理**：选项决定分支 → 部分选项可触发小游戏 → 小游戏 pass/fail 决定下一节点

**核心改进**：
1. 废 score 计分制 — 玩家选项不是"打分"，是"分岔路口"
2. 选项含 `next` 字段直接指向下一 round_id 或 ending_id
3. 选项可含 `minigame` 字段触发小游戏（如"转身就逃" → 止刀小游戏）；过 → 逃成功 ending；不过 → 进"未逃走"分支 round
4. 不同分支抵达不同 ending，每 ending 有独立奖励

---

## 2. Player Fantasy

- **真实抉择**：选项不是"评分轴 0-3"，是"路 A vs 路 B vs 路 C"
- **手速决定命运**：选"转身就逃"不只是文字选择，要靠玩家在止刀小游戏中真停在通过区，否则被抓
- **每次重玩不同**：同一 hidden event 多次触发可走不同分支抵达不同 ending；不再"刷分数追求 perfect"
- **小游戏融入剧情**：止刀/找不同/扫雷等小游戏不再仅服务突破/考核，融入机缘事件作"动作判定"

---

## 3. Detailed Rules

### 3.1 数据 Schema

```gdscript
{
    "type": "hidden",
    "title": "灵犬引路",
    "start": "round_intro",                # 起始 round_id
    "rounds": {                             # Dictionary，键 = round_id
        "round_intro": {
            "text": "...",
            "choices": [
                {
                    "text": "蹲下轻声呼唤",
                    "result": "灵犬歪了歪头，慢慢走回你身边。",
                    "next": "round_yaopu"   # 跳到下一 round
                },
                {
                    "text": "原地不动",
                    "result": "灵犬有些失望地耷拉了耳朵。",
                    "ending": "ending_normal"   # 直接终结，跳过更多 round
                },
                {
                    "text": "转身就逃",
                    "result": "你心虚转身，灵犬却紧追不舍。",
                    "minigame": {
                        "type": "stopline",
                        "preset": "caomen",         # 调用 MinigameStopline.preset_caomen()
                        "on_pass": "ending_escape", # 过 → 逃跑结局
                        "on_fail": "round_caught"   # 没过 → 被抓分支
                    }
                }
            ]
        },
        "round_yaopu": {...},
        "round_caught": {...}
    },
    "endings": {
        "ending_treasure": {
            "text": "...",
            "gold": 120, "prestige": 35,
            "item": "筑基丹", "lifespan": -3
        },
        "ending_escape": {...},
        "ending_normal": {...}
    }
}
```

**关键变更**（vs 旧 schema）：
- `rounds` 由 Array 改为 Dictionary（键 = round_id 字符串）
- 加 `start` 字段指定起始 round
- 选项删 `score` 字段，加 `next` / `ending` / `minigame` 之一
- `endings` 仍是 Dictionary，但删 `min_score` / `trigger_choices`，键名自定义（不再固定 perfect/good/normal）

### 3.2 渲染流程

```
1. _show_hidden_story(event):
   _hidden_event = event
   _hidden_round_id = event["start"]
   _show_hidden_round()

2. _show_hidden_round():
   round = _hidden_event["rounds"][_hidden_round_id]
   显示 round.text + 渲染 choices 按钮

3. _on_hidden_choice(index):
   choice = round["choices"][index]
   显示 choice.result + "继续 →" 按钮
   按钮 callback 按 choice 字段决定走向：
     - choice.has("ending") → _finish_hidden_event(ending_id)
     - choice.has("minigame") → _start_hidden_minigame(minigame_cfg)
     - choice.has("next") → _hidden_round_id = next; _show_hidden_round()

4. _start_hidden_minigame(cfg):
   实例化 minigame 节点（type + preset 决定）
   连接 minigame_completed → _on_hidden_minigame_done(cfg, result)

5. _on_hidden_minigame_done(cfg, result):
   if result == "pass":
       target = cfg["on_pass"]
   else:
       target = cfg["on_fail"]
   if target.begins_with("ending_") or target in _hidden_event["endings"]:
       _finish_hidden_event(target)
   else:
       _hidden_round_id = target; _show_hidden_round()

6. _finish_hidden_event(ending_id):
   ending = _hidden_event["endings"][ending_id]
   应用 gold/prestige/item/lifespan
   显示结局界面
```

### 3.3 选项可选字段

| 字段 | 类型 | 含义 |
|------|------|------|
| `text` | String | 选项标签 |
| `result` | String | 即时反馈文（在跳转前显示） |
| `next` | String | 下一 round_id |
| `ending` | String | 直接跳到 ending_id（跳过 next） |
| `minigame` | Dictionary | 触发小游戏（见 §3.4） |

**优先级**：minigame > ending > next（同选项只能含一个，渲染层按优先级查）

### 3.4 minigame 字段

```gdscript
"minigame": {
    "type": "stopline" | "oddone" | "logic" | "schulte" | ...,
    "preset": "caomen" | "yangtian_skill" | ...,    # 对应 minigame 类的 preset_* 方法
    "on_pass": "ending_id" | "round_id",            # pass 后跳转目标
    "on_fail": "ending_id" | "round_id"             # fail/death 跳转目标
}
```

**支持类型**（与现有 minigame_*.gd 类对齐）：
- `stopline` → MinigameStopline + preset_xiuluo / yangtian_skill / qingyun / caomen / shouyi / yangtian_talent
- `oddone` → MinigameOddOne + preset_qiqi / zhuji / jindan
- `logic` → MinigameLogic + pool: easy / medium / advanced
- `sudoku/schulte/numchain/...` → 后续按需扩展

**参数透传**：preset 字符串指向 minigame 类的 static preset_* 方法返回的 dict。游戏层调 `minigame_node.configure(preset_dict)`。

### 3.5 兼容旧 schema

新 game.gd 渲染层**不**兼容旧 schema（rounds: Array + score 字段）。

**迁移路径**：剧情 Agent 委托重写 `story_more.gd` 现有 4 hidden events 为新 schema。在迁移完成前，hidden event 触发被 game.gd 检测旧 schema 时跳过（safety fallback）。

---

## 4. Formulas

### 4.1 触发概率

承袭 story-system.md（不变）：

```
P_hidden = clampf(prestige / (prestige + 100), 0.0, 0.60) * luck_multiplier
```

### 4.2 minigame 触发判定

minigame 内置 pass/fail 阈值（preset 控制），直接 emit signal。GDD 渲染层不参与判定逻辑。

---

## 5. Edge Cases

- **next 指向不存在 round_id** → 跳到 `start` round（safety fallback），log warning
- **ending 指向不存在 ending_id** → 强制结束 + 应用 0 奖励（防 crash）
- **minigame on_pass / on_fail 指向不存在** → 同上 safety fallback
- **选项同时有 next + ending + minigame** → 按优先级 minigame > ending > next 取一
- **rounds 为 Array（旧 schema）** → 检测到 `event["rounds"]` 是 Array → log warning + 不触发该 event（fallback show_free）
- **start 字段缺失** → 取 rounds 字典第一个键 fallback
- **minigame 节点 emit signal 后未释放** → 渲染层 queue_free + 解绑 signal（防 leak）
- **死循环（A → B → A）** → 不阻止；玩家可通过 minigame on_fail 退出（设计师责任）
- **endings 字典空** → 不允许；schema 校验时报错
- **玩家死于 ending lifespan -N** → _finish_hidden_event 末尾 is_dead 判定（同旧逻辑）

---

## 6. Dependencies

### 上游

- **story-system.md**：写作风格 §4（情境 / 选项 / 结果 三段式 + anti-patterns §4.9）
- **player.gd**：gold / prestige / lifespan / item 字段访问；pass_time / add_prestige
- **items.gd**：item 字段必须在 ITEM_META 注册
- **minigame_*.gd 全 8 类**：MinigameStopline / MinigameOddOne / MinigameLogic / 等，提供 configure() + minigame_completed signal

### 下游

- **story_more.gd**：4 现有 hidden events 数据迁移（剧情 Agent 委托）
- **game.gd**：_show_hidden_round / _on_hidden_choice / _finish_hidden_event 重写；新增 _start_hidden_minigame / _on_hidden_minigame_done

---

## 7. Tuning Knobs

| 参数 | 默认值 | 调节意义 |
|------|--------|---------|
| 分支深度上限 | 5 round | 太深玩家迷失；太浅缺乏分歧感 |
| minigame on_fail 比例 | ≥ 50% 走未逃走分支（非 ending） | 提高 = 失败有戏；降低 = 失败直接结算 |
| ending 数量 | 3-5 / event | 太多写作工作量大；太少分支感弱 |
| minigame 类型分布 | stopline 60% / oddone 20% / logic 20% | 单调时调整 |
| 选项含 minigame 比例 | 30% | 增多增加紧张感；减少节奏宽松 |
| ending 奖励上限 | 灵石 +300（同 story-system 隐藏） | 同步 |

---

## 8. Acceptance Criteria

GDD 实施后必须满足以下可验证条件：

1. **AC-1 schema 校验**：每个 event 含 `start` + `rounds` (Dictionary) + `endings` (Dictionary)；选项含 `text` + `result` + (`next` | `ending` | `minigame`) 之一
2. **AC-2 渲染流程**：玩家选含 `next` 的选项 → 显示 result → 「继续 →」按钮 → 跳到下一 round；选 `ending` → 「查看结局 →」 → 应用奖励 + 显示 ending text
3. **AC-3 minigame 触发**：选 minigame 选项 → 显示 result → 「迎接挑战 →」 → 渲染 minigame；minigame emit pass → 跳 on_pass；emit fail/death → 跳 on_fail
4. **AC-4 死循环防护**：手动构造 A.next = B / B.next = A，玩家可通过任一含 minigame 的选项退出（minigame on_fail 走 ending）
5. **AC-5 安全 fallback**：next/ending 指向不存在 id → log warning + 不 crash + 跳 start round / 0 奖励 ending
6. **AC-6 旧 schema 不触发**：rounds 是 Array 类型 event → game.gd 检测后不触发，回退 show_free
7. **AC-7 minigame 类型覆盖**：至少 stopline + oddone + logic 三类可在 hidden event 中触发；GDD §3.4 列出的 type 字符串与 minigame_*.gd 类静态 preset_* 方法对应
8. **AC-8 写作风格**：抽 5 random rounds × 选项，零项触发 story-system.md §4.9 anti-patterns
9. **AC-9 ending 字段**：含 gold/prestige/item/lifespan 四字段（item 可空字符串），数值在 story-system.md 隐藏事件边界（gold +80~+300 / prestige +15~+80 / lifespan -1~-4）
10. **AC-10 GUT 测试**：渲染流程单元测试覆盖 next / ending / minigame 三路径；fallback 路径覆盖

---

## 9. 实施计划

### Phase 1：渲染层重写（本次）
1. game.gd 改 `_show_hidden_round` 接 round_id 参数；用 `_hidden_round_id: String`
2. game.gd 改 `_on_hidden_choice` 按 next/ending/minigame 字段分派
3. game.gd 新增 `_start_hidden_minigame(cfg)` + `_on_hidden_minigame_done(cfg, result)`
4. game.gd 改 `_finish_hidden_event(ending_id)` 按 ending_id 取奖励
5. game.gd `_show_hidden_story` 入口检测旧 schema → fallback show_free

### Phase 2：数据迁移（剧情 Agent 委托）
6. story_more.gd 4 现有 hidden events 全部迁移新 schema
7. 至少 1 event 含 minigame 选项作为 demo（如"转身就逃" + stopline preset_caomen）
8. 写作风格审计

### Phase 3：测试
9. GUT 单元测试覆盖 AC-10
10. headless smoke 测试 4 events 至少各走通 1 完整路径

---

## Changelog

- **v1.0 (2026-05-04)**：初版重写。废 score 计分，引选项分支 + minigame 触发。schema rounds 改 Dictionary。
