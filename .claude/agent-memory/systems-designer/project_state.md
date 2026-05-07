---
name: Project State — 小狗修仙 GDD Blockers
description: Critical blocking dependencies and implementation gaps in the GDD suite as of 2026-04-27
type: project
---

As of 2026-04-27:

- `faction-system.md` is the single most critical blocker. It exists but has [To be designed] for: 考核系统, faction_affinity data structure, 归属变更流程, Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria.
- `origin-mechanism.md` is "In Review" but has 3 unresolved structural issues found in adversarial review (see session log).
- `psychology-distraction.md` has no concrete initial value for player.mind — 100 is a placeholder that origin-mechanism.md is already using.
- The live codebase has already implemented faction selection WITHOUT an exam system — it is a direct choice with prestige awarded from a FACTIONS constant in game.gd. This diverges from the GDD's "exam" model.
- faction_affinity does not exist anywhere in the codebase. The current implementation conflates it with player.prestige (global), which is a major design gap.

**Why:** faction-system.md was never fully drafted. All dependent systems are blocked on it.
**How to apply:** When reviewing or drafting any system that touches faction, affinity, or exam mechanics, note that the codebase already has a working but GDD-divergent implementation. Proposals must address the gap between live code and design intent.
