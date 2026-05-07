# ⚖ 决策记录（ADR）索引

## 全部
```dataview
TABLE id, date, status
FROM "production/decisions"
WHERE file.name != "_index"
SORT date DESC
```

## 已接受
```dataview
LIST FROM "production/decisions"
WHERE status = "accepted" AND file.name != "_index"
```

## 待定
```dataview
LIST FROM "production/decisions"
WHERE status = "proposed" AND file.name != "_index"
```

---

## 历史冻结决策（来自 CLAUDE.md）

以下 9 条已固化在代码中，详见各 ADR：

1. [[ADR-001-cultivation-source-restriction|修为来源严格限制]]
2. [[ADR-002-breakthrough-fail-cost|突破失败消耗道具]]
3. [[ADR-003-breakthrough-lifespan-accumulate|突破成功寿命累加不重置]]
4. [[ADR-004-talent-speed-only-retreat|速悟天赋只影响闭关]]
5. [[ADR-005-talent-20-required|天赋 20 点全部分配完才能开始]]
6. [[ADR-006-lifespan-zero-instant-death|寿命归零立即进入死亡处理]]
7. [[ADR-007-family-talent-zero-hide|家族天赋 0 时隐藏援助按钮]]
8. [[ADR-008-market-double-gold-check|集市双重灵石检查]]
9. [[ADR-009-min-realm-gate|境界门槛机制 min_realm]]

模板：[[../../vault-meta/templates/adr]]
