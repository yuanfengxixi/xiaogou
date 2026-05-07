---
tags: [content-index]
---

# 📜 任务清单索引

## 数量统计

| 境界 | 已写 | 目标 | 文件 |
|------|------|------|------|
| 练气 | ? | - | task_easy.gd |
| 筑基 | ? | - | task_normal.gd |
| 金丹 | ? | - | task_normal.gd |
| 元婴 | 0 | ? | task_hard.gd |
| 化神 | 0 | ? | task_hard.gd |

总计：6 条（覆盖练气~金丹）

## 已建档
```dataview
TABLE realm_required, status, gold_sss
FROM "content/tasks"
WHERE file.name != "_index"
SORT realm_required ASC
```

---

## 红线速查
- SSS 灵石 ≤ 850
- cultivation = 0
- 七档齐全（SSS/SS/S/A/B/C/D）

## 关联
- 设计：[[../../design/gdd/task-system]]
- Agent：[[../../vault-meta/prompts/task-writer]]
- 模板：[[../../vault-meta/templates/task]]
