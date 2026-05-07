---
name: 小狗修仙 — Project Context
description: Core project facts for 小狗修仙 — text xianxia life-sim in Godot 4.6
type: project
---

小狗修仙 is a text-based sandbox xianxia life-sim built in Godot 4.6 with pure code-driven UI (no external art assets). All UI is GDScript-generated Controls.

**Why:** Indie solo/small project targeting PC (Steam/itch) and Android.

**How to apply:** All UX proposals must be implementable as GDScript UI code (Buttons, Labels, VBoxContainers, ScrollContainers). No sprites, no animations, no hover states. Minimum button height 68px (UITheme.BTN_H = 68). Minimum font size FONT_BODY = 28. All interaction design must support touch (64px minimum tap target per technical-preferences.md, actual impl uses 68px). No gamepad. Keyboard/mouse + touch only.

Current GDD status (as of 2026-04-23):
- origin-mechanism.md: In Design — the opening sect-selection / exam flow is the active design area
- faction-system.md: not yet written — exam form and pass threshold are undefined downstream dependencies
- psychology-distraction.md: redesign-draft — mind initial value not yet confirmed
- task-system.md: reverse-documented from code — fully implemented in task.gd

The opening flow (起点机制) goes: talent screen → [proposed] sect selection → exam → main loop. Currently game.gd starts directly at State.TALENT with no sect/rogue selection screen implemented yet.
