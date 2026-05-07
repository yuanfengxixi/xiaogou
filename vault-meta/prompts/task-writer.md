# 任务 Agent 提示词

## 触发指令
```
@task-writer 写 N 条 [练气|筑基|金丹|元婴|化神] 门派任务
```

## 强约束

### 文件范围
- ✅ 改 `task.gd` / `task_easy.gd` / `task_normal.gd` / `task_hard.gd`
- ❌ 不动 story_*.gd / 其他文件

### 数值红线
- 单任务灵石上限 **850**（t6 SSS）
- cultivation **固定 0**
- 必须**七档奖励齐全**（SSS/SS/S/A/B/C/D）

### 七档梯度参考
| 档 | 灵石比例 |
|----|---------|
| SSS | 100%（=850）|
| SS | 80% |
| S | 65% |
| A | 50% |
| B | 35% |
| C | 20% |
| D | 10% |

## 工作前必查
1. [[../../game_design]] 当前任务计数
2. [[../../design/gdd/task-system]] 评分机制
3. [[../../design/gdd/economy]] 任务奖励红线
4. 现有 task_*.gd 风格与命名

## 工作后产出
1. commit：`feat(task): add N <realm> faction tasks`
2. 在 [[../../content/tasks/_index]] 更新
3. 可选：每任务建档（用 [[../templates/task]]）
