# 小狗修仙 — 系统架构图

**生成日期**：2026-05-07
**对应代码版本**：Rev 4 任务系统透明报酬制 + 转世遗赠 meta progression

## 总览

```mermaid
flowchart TB
    subgraph Entry["main.gd · 入口 Node2D"]
        UI[创建 UI<br/>CanvasLayer + VBox<br/>story_label / stats_label / choices_box / overlay]
    end

    subgraph Core["核心 Node 单例（main 实例化 + add_child）"]
        player[player.gd<br/>玩家数据模型<br/>境界/修为/寿命/灵石/声望<br/>气运 = talent_luck<br/>items / life_log]
        talent[talent.gd<br/>来世铭印分配池<br/>total_points → speed/luck]
        reincarnation[reincarnation.gd<br/>meta progression<br/>跨局 bonus 累加]
        game[game.gd<br/>状态机 30+ State<br/>驱动全部 UI]
        items_node[items.gd<br/>ITEM_META 词典<br/>称号体系]
    end

    subgraph StorySys["剧情系统"]
        story[story.gd<br/>事件协调器]
        story_one[story_one.gd<br/>普通历练池<br/>cultivation=0]
        story_more[story_more.gd<br/>隐藏机缘池<br/>正/邪 evil 分流]
    end

    subgraph TaskSys["任务系统 Rev 4 透明报酬"]
        task[task.gd<br/>调度器<br/>资格检查/路由]
        task_easy[task_easy.gd<br/>固定奖励 8 条]
        task_normal[task_normal.gd<br/>1 选择 19 条<br/>base + modifier]
        task_hard[task_hard.gd<br/>多步 5 条<br/>含 minigame]
    end

    subgraph MG["小游戏池（9 个）"]
        mgs[schulte / blacktiles / minesweeper<br/>sudoku / memory / numchain<br/>logic / stopline / oddone]
    end

    subgraph Persist["持久化"]
        cfg[(user://<br/>reincarnation.cfg)]
    end

    Entry -->|setup 注入| game
    Entry -->|load_from_disk + apply_to_new_run| reincarnation
    reincarnation -.bonus_talent_points.-> talent
    reincarnation -.start_gold / start_luck.-> player

    game -->|读写属性| player
    game -->|allocate / apply_to_player| talent
    game -->|use_item / market| items_node
    game -->|commit_death / commit_ascension| reincarnation

    game -->|get_random_event<br/>get_hidden_event<br/>get_crush_choices| story
    story --> story_one
    story --> story_more

    game -->|get_available_tasks<br/>start/make_choice/finish<br/>notify_minigame_result| task
    task --> task_easy
    task --> task_normal
    task --> task_hard

    game -.HIDDEN_STORY 多步.-> MG
    task_hard -.awaiting_minigame.-> MG

    reincarnation <-->|ConfigFile| cfg

    classDef entry fill:#fde,stroke:#a35
    classDef core fill:#def,stroke:#359
    classDef sys fill:#efd,stroke:#583
    classDef persist fill:#ffd,stroke:#a83
    class Entry entry
    class player,talent,reincarnation,game,items_node core
    class StorySys,TaskSys,MG sys
    class cfg persist
```

## 关键流向

### 启动序列（main.gd `_ready`）

1. 实例化 7 单例（player / story / task / talent / items / reincarnation / game）
2. `reincarnation.load_from_disk()` 读 `user://reincarnation.cfg`
3. `reincarnation.apply_to_new_run(talent, player)` 注入：
   - `talent.total_points = bonus_talent_points`
   - `player.gold = 40 + bonus_start_gold`
   - `player.talent_luck = bonus_start_luck`
4. 创建 UI（CanvasLayer + Margin + VBox + ScrollContainer）
5. `game.setup(...)` 注入所有依赖

### 局内主循环

- `game.gd` 状态机驱动，State 30+ 个（NAME_INPUT / TALENT_ALLOCATE / FACTION_SELECT / FREE / STORY / TASK_* / RETREAT_SELECT / BREAKTHROUGH_* / EXAM_* / MARKET / HIDDEN_* / CHRONICLE / GAMEOVER / REINCARNATION_CHOICE / ASCENSION）
- 每个 State 重绘 `story_label / stats_label / choices_box`
- 三大系统通过 game.gd 调度：
  - **player** — 数据模型（直接读写）
  - **story** — 事件 dict 返回，game 渲染
  - **task** — dispatcher 路由到 easy/normal/hard handler

### 死亡 / 飞升收尾

- 死亡 → `REINCARNATION_CHOICE` → 三选一 → `commit_death_choice` → save
- 飞升 → `ASCENSION` → 三项全拿 → `commit_ascension` → lives 重置 → save

### 小游戏双入口

- **隐藏事件**（`game.gd`）→ multi-step-events 协议 → 9 minigame 之一
- **困难任务**（`task_hard`）→ `awaiting_minigame` flag → game 拉起 minigame → `notify_minigame_result`

## 文件职责红线（CLAUDE.md 摘录）

| 文件 | Agent | 修改权限 |
|------|-------|---------|
| `story_one.gd` / `story_more.gd` | 剧情 Agent | 仅事件池数据；cultivation 必须 = 0 |
| `task_easy/normal/hard.gd` | 任务 Agent | 仅 TASKS 数组；cultivation 允许 > 0（境界上限 5/40/100/250/500） |
| `player.gd` / `game.gd` / `talent.gd` | 逻辑 Agent | 设计决策不得擅改 |
| `task.gd` | 调度器 | 任务 Agent 不得动 |
| `reincarnation.gd` | meta 单例 | ConfigFile 持久化 |

## Tuning Knobs 速查

- 突破系数 `talent_luck × 0.02 / pt`（player.gd:71）
- 闭关 insight 概率 `0.10 + talent_luck × 0.02`（clampf 0.03~0.30）
- 修罗门 `base.gold ×1.5`（数据填充阶段，handler 无分支）
- 死亡灵石继承 10% / 飞升 100%
- 转世奖励表 `REWARD_POINTS_BY_REALM = [0, 0, 2, 5, 10]` / `REWARD_LUCK_BY_REALM = [0, 0, 1, 3, 6]`
- 飞升固定奖励 `+20 points / +12 luck / 100% gold`
