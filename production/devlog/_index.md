# 📝 Devlog 索引

## 全部日志
```dataview
TABLE date, sprint, build
FROM "production/devlog"
WHERE file.name != "_index"
SORT date DESC
```

## 本周
```dataview
LIST FROM "production/devlog"
WHERE date >= date(today) - dur(7 days) AND file.name != "_index"
SORT date DESC
```

## 本 Sprint
```dataview
LIST FROM "production/devlog"
WHERE sprint = this.current_sprint AND file.name != "_index"
SORT date DESC
```

---

模板：[[../../vault-meta/templates/devlog]]
