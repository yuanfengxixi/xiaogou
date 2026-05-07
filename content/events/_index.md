---
tags: [content-index]
---

# 🎲 事件清单索引

## 数量统计

| 类型 | 文件 | 已写 | 目标 |
|------|------|------|------|
| 普通历练 | story_one.gd | 10 | - |
| 隐藏机缘 | story_more.gd | 4 | 25 |

## 隐藏事件分境界

| 境界 | 已写 | 目标 |
|------|------|------|
| 练气 | 3 | ? |
| 筑基 | 1 | ? |
| 金丹 | 0 | ? |
| 元婴 | 0 | ? |
| 化神 | 0 | ? |

## 已建档事件
```dataview
TABLE type, realm_min, status, gold_max, prestige_max
FROM "content/events"
WHERE file.name != "_index" AND file.name != "normal-events" AND file.name != "hidden-events"
SORT realm_min ASC
```

## 未达红线
```dataview
LIST FROM "content/events"
WHERE status = "draft" AND file.name != "_index"
```

---

## 红线速查
- 普通：灵石 -50~+150 / 声望 -30~+30 / 寿命 -1~-7 / cultivation = 0 / 4 选项 / 首选 leave
- 隐藏：灵石 +80~+300 / 声望 +15~+80 / 寿命 -1~-4 / cultivation = 0 / 2-4 选项 / 半数含道具

## 关联
- 设计：[[../../design/gdd/story-system]]
- 数值：[[../../design/gdd/economy]]
- Agent：[[../../vault-meta/prompts/story-writer]]
- 模板：[[../../vault-meta/templates/event]]
