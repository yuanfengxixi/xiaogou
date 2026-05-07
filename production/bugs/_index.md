# 🐛 Bug 列表

## 全部未修
```dataview
TABLE severity, component, build, date_found
FROM "production/bugs"
WHERE status != "fixed" AND file.name != "_index"
SORT severity DESC, date_found ASC
```

## 严重
```dataview
LIST FROM "production/bugs"
WHERE severity = "critical" AND status != "fixed" AND file.name != "_index"
```

## 已修
```dataview
TABLE date_found, component
FROM "production/bugs"
WHERE status = "fixed" AND file.name != "_index"
SORT date_found DESC LIMIT 20
```

---

模板：[[../../vault-meta/templates/bug]]
