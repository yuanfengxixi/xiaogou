# Godot — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | 4.6 |
| **Project Pinned** | 2026-04-21 |
| **Last Docs Verified** | 2026-04-21 |
| **LLM Knowledge Cutoff** | 2026-01 (Claude Opus 4.7) |
| **Risk Level** | MEDIUM — 4.6 发布于 2025-Q4，在主训练数据边缘 |

## Knowledge Gap Analysis

Godot 4.6 在模型训练截止（2026-01）前发布，核心 API 应有覆盖。但相较更成熟的 4.2 / 4.3，4.6 新特性（如新的 渲染器优化、新 Control API）可能返回不确定答案。

**处理策略**：
- 编写 GDScript 代码前，若涉及 4.4+ 新引入的 API，先用 WebSearch 验证
- 不确定的 API 引用官方文档：https://docs.godotengine.org/en/4.6/
- 发现 agent 建议过时 API 时，运行 `/setup-engine refresh`

## Post-Cutoff Version Timeline

| Godot Version | Release | Status |
|---------------|---------|--------|
| 4.3 | 2024-08 | 训练数据主要覆盖 |
| 4.4 | 2025-03 | 训练数据边缘 |
| 4.5 | 2025-07 | 训练数据边缘 |
| 4.6 | 2025-Q4 | 本项目使用 — MEDIUM RISK |

## Key References

- 官方文档: https://docs.godotengine.org/en/4.6/
- 变更日志: https://godotengine.org/article/ (按版本查找 release notes)
- 迁移指南: https://docs.godotengine.org/en/4.6/tutorials/migrating/

## Agent Instructions

引擎专家 agent（godot-specialist / godot-gdscript-specialist / godot-shader-specialist）遇到以下情形必须进行验证：

1. 建议使用 Godot 4.4+ 新引入的 API 或 node 类型
2. 用户报告 API 行为异常或调用失败
3. 涉及渲染管线（Forward+ / Mobile / Compatibility）的特定配置
4. 不确定方法签名或参数

**验证顺序**：
1. 读取本文件（已完成版本固定）
2. 若存在 `breaking-changes.md` 或 `deprecated-apis.md`，查阅
3. WebSearch 官方文档或 Godot 论坛确认
4. 若仍不确定，向用户说明并给出官方链接

## Note

当前为精简 VERSION.md。如果 agent 频繁给出过时 API 建议，运行 `/setup-engine refresh` 展开为完整 reference（breaking-changes.md / deprecated-apis.md / current-best-practices.md / modules/）。
