---
event_id: 
type: normal
realm_min: 0
file_source: story_one.gd
status: draft
gold_min: 
gold_max: 
prestige_min: 
prestige_max: 
lifespan_cost: 
has_item_reward: false
choices: 4
themes: []
tags: [content, event]
---

# <% tp.file.title %>

## 题材
- [ ] 战斗
- [ ] 探宝
- [ ] 人际关系
- [ ] 门派日常
- [ ] 江湖见闻
- [ ] 灰色抉择
- [ ] 生活趣事

## 情境描写


## 选项设计

| # | 选项 | 性格 | 灵石 | 声望 | 寿命 | 道具 | qiyun | 灰色? | leave? |
|---|------|------|------|------|------|------|-------|-------|--------|
| 1 | 转身离去 | - | 0 | 0 | 0 | - | 0 | - | ✅ |
| 2 | | | | | | | | | |
| 3 | | | | | | | | | |
| 4 | | | | | | | | | |

## 结果文本

### 选项 2


### 选项 3


### 选项 4


## 数值校验
- [ ] 灵石范围合规
- [ ] 声望范围合规
- [ ] 寿命范围合规
- [ ] cultivation = 0
- [ ] 首选项 leave: true 且全 0
- [ ] 含 ≥1 灰色选项（声望 -15 以上）
- [ ] 题材非战斗/探宝单一

## 关联
- 设计参考：[[../../design/gdd/story-system]]
- 数值：[[../../design/gdd/economy]]
- 实现：`story_one.gd` / `story_more.gd`
- Commit: 
