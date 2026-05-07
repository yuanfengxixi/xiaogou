---
name: REALM_LIFESPAN 不一致
description: player.gd 中 REALM_LIFESPAN 与设计文档示例表格数值不同，影响 mind_max 突破增量公式
type: project
---

player.gd（第 25 行）中 REALM_LIFESPAN = [80, 200, 500, 1200, 3000, 99999]。

psychology-distraction.md Section 4 示例（第 60 行）使用的是 [80, 200, 400, 800, 1000, 99999]，二者从 index 2 开始分叉。

**Why:** 设计文档在代码之前写成，之后 player.gd 数值被调整但文档未同步更新。

**How to apply:** 在任何涉及 mind_max 突破增量（`mind_max += (REALM_LIFESPAN[realm+1] - REALM_LIFESPAN[realm]) / 15.0`）的 AC 验证或单元测试实施前，必须先确认使用哪套数值，并将设计文档示例与代码对齐。AC 4 的期望值 13.75 基于旧表，需重算。
