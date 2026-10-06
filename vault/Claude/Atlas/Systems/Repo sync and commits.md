---
type: system
created: 2026-10-01
author: claude
tags:
  - system
  - workflow
  - git
---

Up: [[Claude]]

How Claude keeps `~/Documents/GitHub/sword_bound` matching the live place. GitHub is Henry's personal version history; the team works in Roblox Team Create.

- Studio scripts are edited with targeted string replacements (multi_edit or a replaceOnce helper), never whole-script rewrites. Every module keeps its header comment.
- The same edits are replayed on the repo files from the exact Studio edit list (exported from the session transcript), so nothing is retyped.
- A checksum check compares the repo against the live place: CRLF to LF, trailing spaces stripped, then an Adler-style sum in both Luau and Python. Every changed file must match before committing.
- Commits are made as Henry Pham with the Claude co-author lines. Henry pushes himself.
- After each commit, delete `.git/*.lock` and `tmp_obj` files (the device shell leaves them behind).
- Luau gotcha: a `[==[` long string drops a leading newline.
- Animations: AnimationBuilder rebuilds AnimSaves from Specs. They only play in Studio until uploaded and their ids are pasted into AnimationLibrary.Published.
- Testing: `Players.<you>.CombatTestInput` (Studio only) presses Attack / Block / Roll with exact timing from a test script.

The vault itself lives in the repo at `vault/`, so notes get git history too ([[Claude]]).
