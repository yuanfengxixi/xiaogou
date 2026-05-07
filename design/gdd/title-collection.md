---
status: in-design
source: items.gd
date: 2026-04-27
---

# 宝物图鉴系统

## 1. Overview

道具收藏记录系统，由 `items.gd` 管理。**宝物图鉴**记录玩家一生中所有获得过的道具（含获取次数、来源、背景描述）。状态界面与 GAMEOVER 界面均展示，作为玩家一生的回顾。

## 2. Player Fantasy

- 宝物图鉴是"你这辈子见过什么宝贝"
- 即使失败，积累的图鉴仍是意义——一个一无所有的散修和一个集齐了延寿丹的老修士，死亡面前都是一样，但图鉴不同
- 邪道玩家的图鉴里会出现护身符、储物戒等正道玩家看不到的物品

## 3. Detailed Rules

### 宝物图鉴 (`collection_log`)

- `on_item_collected(item_name)` 在每次发放道具时调用
- 记录获取次数：`collection_log[name] += 1`
- 首次获得返回 `true`（可触发解锁弹窗，当前 UI 未接入）

### 宝物词典 (`ITEM_META`)

每个道具含：

- `type` — 突破材料 / 消耗品
- `desc` — 背景描述（修仙风味文字）
- `source` — 主要获取途径
- `effect` — 使用效果（部分道具有）

含以下 15 种道具元数据：

| 道具 | 类型 | 来源 |
|---|---|---|
| 筑基丹 | 突破材料 | 隐藏机缘事件、宝物集市 |
| 金丹 | 突破材料 | 宝物集市 |
| 元婴珠 | 突破材料 | 宝物集市 |
| 化神石 | 突破材料 | 宝物集市 |
| 延寿丹 | 消耗品 | 门派任务·SSS奖励、隐藏机缘事件 |
| 一阶破境符 | 消耗品 | 宝物集市 |
| 二阶破境符 | 消耗品 | 宝物集市 |
| 三阶破境符 | 消耗品 | 隐藏机缘事件、宝物集市 |
| 四阶破境符 | 消耗品 | 隐藏机缘事件、宝物集市 |
| 五阶破境符 | 消耗品 | 隐藏机缘事件、宝物集市 |
| 一阶聚灵丹 | 消耗品 | 隐藏机缘事件、宝物集市 |
| 二阶聚灵丹 | 消耗品 | 门派任务·SSS奖励、隐藏机缘事件、宝物集市 |
| 三阶聚灵丹 | 消耗品 | 隐藏机缘事件、宝物集市 |
| 四阶聚灵丹 | 消耗品 | 隐藏机缘事件、宝物集市 |
| 五阶聚灵丹 | 消耗品 | 隐藏机缘事件、宝物集市 |

**已知 ITEM_META 缺口**（道具存在于代码，但无元数据条目，显示"无记录"）：

| 道具 | 来源 |
|---|---|
| 护身符 | story_more.gd 恶行事件 |
| 储物戒 | story_more.gd 恶行事件 |
| 残破法器 | story_more.gd 恶行事件 |

### 展示文本 (`get_collection_text`)

状态界面与 GAMEOVER 界面调用，返回完整的宝物收藏：

```
【宝物图鉴】
  ▸ 【筑基丹】× 1
    以千年灵草为引……
    来源：隐藏机缘事件、宝物集市
  ...
```

## 4. Formulas

无数值公式。收藏记录为计数累加，道具效果由 `player.use_item()` 处理。

## 5. Edge Cases

- **道具无元数据**：`ITEM_META.get(item_name, {})` 返回空字典，desc 显示"无记录"，source 显示"不详"。恶行事件道具（护身符/储物戒/残破法器）目前均命中此分支
- **首次获得道具**：`on_item_collected` 返回 `true`，当前 UI 未消费该返回值（可扩展弹窗）
- **重复获取**：只叠加次数，不重复写条目
- **空 item 字段**：`item_name == ""` 时直接 return false，不写入 collection_log

## 6. Dependencies

- **上游**：`story_more.gd`（隐藏事件道具奖励）、`task.gd`（任务SSS奖励）、`game.gd`（宝物集市购买、ST_BREAKTHROUGH 突破流程）
- **下游**：UI 状态栏（`ST_STATUS`，宝物图鉴列表）；GAMEOVER 界面（`ST_GAMEOVER`，完整展示）

## 7. Tuning Knobs

- `ITEM_META` 描述文案（15条，可随时修改）
- `ITEM_META` 来源文本（与实际代码来源保持同步）
- `get_collection_text` 展示格式（当前 `▸【名称】× 数量 + desc + source`）

## 8. Acceptance Criteria

- [ ] `on_item_collected` 首次返回 true，后续返回 false
- [ ] `on_item_collected("")` 返回 false，不写入 collection_log
- [ ] 重复获取同一道具只叠加次数，不重复条目
- [ ] 每个 ITEM_META 键名与 player.gd / game.gd 中 `add_item` / `give_item` 调用名称完全一致（无拼写漂移）
- [ ] GAMEOVER 界面显示完整宝物图鉴
- [ ] 状态栏宝物图鉴显示正确次数
- [ ] 恶行道具（护身符/储物戒/残破法器）图鉴内显示"无记录"而非崩溃（待补充 ITEM_META）
