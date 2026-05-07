---
tags: [content-index]
---

# 👤 NPC 清单

## 全部
```dataview
TABLE faction, realm, role, status
FROM "content/npcs"
WHERE file.name != "_index"
SORT faction ASC, realm DESC
```

## 按门派
```dataview
TABLE WITHOUT ID file.link, realm, role
FROM "content/npcs"
WHERE file.name != "_index"
GROUP BY faction
```

## 按境界
```dataview
TABLE WITHOUT ID file.link, faction, role
FROM "content/npcs"
WHERE file.name != "_index"
GROUP BY realm
```

---

## 关联
- 设计：[[../../design/gdd/npc-simulation]]
- 模板：[[../../vault-meta/templates/npc]]
