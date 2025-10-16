# Codex Guardrails (WoW Addon – Classic Era)

## TL;DR (non-negotiables)
- **Do NOT modify** `hello.*` (keep for reference) and **do NOT modify** `lib/` (third-party / shared).
- **Do not remove features.** If a refactor would drop something, stop and ask.
- Keep code **cordoned by responsibility** (e.g., `slash.lua` for slash commands).
- **Short functions**, minimal but useful **block comments**, **no magic numbers**, use **localization** strings (add if missing).
- Update **help screen**, **documentation**, and **slash commands** when behavior changes.
- Assume user is **new to Lua & Codex**; show changes clearly (see “Diff/Commit style” below).
- Think like a **world-class WoW addon dev** (Details!, Healbot, AllTheThings energy) but keep the footprint light.

---

## Scope & Goals
- Primary goal right now: **make the main addon layout readable/clean** (UI polish without breaking behavior).
- Ask if a **screenshot** of current UI would help before large layout changes.
- Leverage good task-tracker UX patterns appropriate for **Classic Era**.

---

## Module / File Boundaries
- `WinterPetCloud.lua`: bootstrap, SavedVariables defaults, event wiring, module glue.
- `lua/utils.lua`: shared helpers (confirm dialogs, trim, etc.).
- `lua/tasks.lua`: SavedVariables, task CRUD, import/export.
- `lua/ui_list.lua`: main checklist frame + footer actions.
- `lua/options.lua`: options panel + profiles.
- `lua/minimap.lua`: LibDBIcon button + tooltip.
- `lua/slash.lua`: slash command registration + handlers.
- `lua/help.lua`: help overlay presentation.
- `i18n/*.lua`: localization strings by locale; never hardcode UI text.
- `lib/`: third-party libs (vendor space, don't edit).
- `tests/` (optional): harnesses/mocks (non-packaged).

Keep related functions grouped; prefer small, cohesive files over long grab-bags.

---

## Coding Standards
- **Line endings**: LF everywhere (see `.gitattributes` below).
- **Comments**: concise block headers for sections; 1–2 lines to explain non-obvious code.
- **Numbers**: lift magic numbers to `local CONST_*` at top of file or a `constants.lua`.
- **Localization**: `L["KEY_NAME"]` for UI & user-visible text; add new keys if missing.
- **Naming**: `NS.` (namespaced) public helpers; avoid leaking globals.
- **Functions**: prefer < 40 lines; extract helpers if longer.
- **UI**: keep anchors sane; no overlapping frames; ESC closes popouts; main window not bound to ESC.

---

## Workflow When Using Codex
1. **Plan**: Summarize intended change in 2–3 bullets; confirm if uncertain.
2. **Touchpoints**: List files you’ll edit; avoid `hello/` and `lib/`.
3. **Apply**: Make small, reviewable edits; keep behavior identical unless explicitly requested.
4. **Update**: If behavior or UI changes, update:
   - `help` screen content
   - documentation notes (this file and/or `README`)
   - slash command help text
5. **Show**: Present a clear diff per change (see next section).
6. **Ask**: Periodically ask clarifying questions that could improve UI/logic/features.

---

## Diff / Commit Style (Light Format)
For each change, present:

**File:** `relative/path.lua`  
**Find:** (3–12 exact lines to locate)

**OLD**
```lua
-- old snippet
```

**NEW**
```lua
-- replacement snippet
```

For insertions:

**ADD**  
_Insert after:_ `anchor line or section name`
```lua
-- new block
```

Keep notes to one bullet if needed (Retail/Classic differences, taint risks).

---

## Help Screen / Docs / Slash Commands
- **Help screen**: Add brief bullets for new options/behaviors.
- **Docs**: Add a 1–2 line note in `README` or this file under a “Changelog” section.
- **Slash**: Add or update `/addon`, `/addon help`, and subcommands in `slash.lua`. Ensure help text lists them.

---

## Feature Retention Checklist (run before commit)
- [ ] No edits to `hello/` or `lib/`.
- [ ] No removed features or hidden regressions.
- [ ] Localization keys added where new UI text appears.
- [ ] Help/docs/ slash help updated if behavior changed.
- [ ] UI remains readable; anchors stable; popouts close with ESC.
- [ ] Functions are short; constants declared; comments added sparsely.

---

## Questions Codex Should Ask Periodically
- “Do you want a **screenshot** review before I commit this UI change?”
- “Should this new label/tooltip be **localized**?”
- “Does this belong on the **help screen** and **/slash help**?”
- “Any **preset** or **template** we should add for this feature?”
- “Classic-era constraints: do we need a **Retail shim** or avoid API X?”

---

## Definition of Done (per change)
- Change implemented & scoped to correct files.
- Tests/manual checks pass (no Lua errors, no taint).
- Visual pass: layout readable at common UI scales.
- Help/docs/slash updated.
- Diff presented in Light Format.

---

## Line Endings Policy (.gitattributes)
Add this at repo root:

```
*.lua     text eol=lf
*.xml     text eol=lf
*.toc     text eol=lf
*.md      text eol=lf
*.txt     text eol=lf
*.json    text eol=lf
*.yaml    text eol=lf
```

**Git config guidance** (developer machines):
- Set `core.autocrlf` to `false` (or `input`) to avoid silent rewrites.
- Let Git enforce LF based on `.gitattributes`. Editors (like VS Code) handle LF on Windows fine.
- Run formatter/linter **after** `.gitattributes` is present; renormalization unnecessary once policy is trusted.

---

## Tools (optional but recommended)
- **Stylua** for formatting (LF, width 100, indent 2).
- **Luacheck** for lint; ignore `.luacheckrc` exceptions only when justified.
- Pre-commit hook (optional): run Stylua, then Luacheck.
