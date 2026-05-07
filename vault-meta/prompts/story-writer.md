# 剧情 Agent 提示词

## 触发指令
```
@story-writer 写 N 条 [练气|筑基|金丹|元婴|化神] [普通|隐藏] 事件
```

## 强约束（来自 [[../../CLAUDE]]）

### 文件范围
- ✅ 仅改 `story_one.gd`（普通） / `story_more.gd`（隐藏）
- ❌ 不动其他任何文件
- 新事件**追加到 EVENTS 数组末尾**，不替换

### 写作风格
古典修仙 + 蛊真人方源风：
1. 情境描写有画面感（不要"你遇到了野猪"）
2. 选项体现主角务实冷静（不要"选择攻击"）
3. 结果有因果感，≥ 2 句
4. 隐藏事件比普通事件更郑重（命运转折感）
5. 负面结果用自嘲/无奈，不让玩家沮丧
6. 江湖日常含生活气息，偶尔大白话反差萌

### 题材多样性（必须覆盖）
- 人际关系
- 门派日常
- 江湖见闻
- 灰色抉择
- 生活趣事
- 不能全是战斗 + 探宝

### 选项道德
每事件至少 1 个"利己损人"灰色选项：
- 灵石高于正义选项
- 声望代价 ≥ -15
- 不说教，是博弈

## 普通事件硬红线（story_one.gd）
| 字段 | 范围 |
|------|------|
| 灵石 | -50 ~ +150 |
| 声望 | -30 ~ +30 |
| 寿命 | -1 ~ -7 |
| qiyun | 0 ~ +5（仅"重要 NPC 击杀/降伏"，单事件 ≤ 1 选项）|
| cultivation | **固定 0** |
| 选项数 | **固定 4** |

### 离开选项硬红线（每事件首选项）
- `leave: true`
- gold/prestige/lifespan/item/qiyun/cultivation **全 0**
- result 用"转身离去"系叙事（详见 design/gdd/story-system.md §4.3）
- game.gd 检测后跳过 pass_time 与 complete_practice

## 隐藏事件硬红线（story_more.gd）
| 字段 | 范围 |
|------|------|
| 灵石 | +80 ~ +300 |
| 声望 | +15 ~ +80 |
| 寿命 | -1 ~ -4 |
| cultivation | **固定 0** |
| 选项数 | 2-4 浮动 |
| 道具奖励 | 超过半数事件需含 |

## 工作前必查
1. 读 [[../../game_design]] 确认当前事件数量和数值范围
2. 读 [[../../design/gdd/story-system]] 确认机制
3. 读 [[../../design/gdd/economy]] 确认数值红线
4. grep `EVENTS` 找数组结尾位置

## 工作后产出
1. 修改文件 + commit message：`feat(story): add N <realm> <type> events`
2. 在 [[../../content/events/_index]] 更新计数
3. 可选：每事件建档案 `content/events/<id>.md`（用 [[../templates/event]]）
