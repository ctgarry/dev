# Codex Bootstrap Checklist (WoW Addon – Classic Era)

A short, repeatable playbook to keep Codex stable and aligned. Pair this with `DEV_NOTES_Codex.md` at repo root.

---

## 0) One‑time setup
- Place **`DEV_NOTES_Codex.md`** at repo root. Treat it as Codex’s source of truth.
- Enforce **LF line endings** with `.gitattributes` (snippet below).
- Optional but recommended: install **Stylua** (formatter) and **Luacheck** (linter).

**`.gitattributes`**
```
*.lua     text eol=lf
*.xml     text eol=lf
*.toc     text eol=lf
*.md      text eol=lf
*.txt     text eol=lf
*.json    text eol=lf
*.yaml    text eol=lf
```
Git config tip: set `core.autocrlf` to `false` (or `input`).

---

## 1) Open a *small* workspace
- In VS Code, **open the addon folder only** (not the entire monorepo).
- Exclude heavy files/dirs to reduce Codex scanning load.

**`.vscode/settings.json` (optional)**
```json
{
  "files.exclude": {
    "**/*.log": true,
    "**/*.zip": true,
    "**/*.png": true,
    "**/*.jpg": true,
    "**/node_modules": true,
    "**/.git": false
  }
}
```

**`.gitignore` (suggested)**
```
*.log
*.zip
*.png
*.jpg
.cache/
tmp/
node_modules/
```

---

## 2) Kickoff script (first message to Codex)
Paste this at the start of each session:

> **Use `DEV_NOTES_Codex.md` as guardrails.** Work only on files I list. Do not touch `hello/` or `lib/`. Use *light diff format* (File / Find / OLD→NEW or ADD). Keep functions short, avoid magic numbers, use localization keys, and update help/docs/slash when behavior changes. Start by proposing a 2–3 bullet plan before editing.

If UI is involved, add:
> Before layout changes, ask if I want to provide a **screenshot** for review.

---

## 3) The safe change loop
1. **Plan** – Codex writes a 2–3 bullet plan; you approve or tweak.
2. **Patch** – Codex returns a *small* diff in light format.
3. **Apply** – You paste/commit locally; run Stylua/Luacheck yourself.
4. **Verify** – Launch WoW; confirm no errors/taint; UI looks right.
5. **Update** – If behavior changed, Codex updates help/docs/slash.
6. **Repeat** – Next small change.

> Ask Codex to **avoid running tools** or long automated sequences. Keep changes focused to 1–2 files per pass.

---

## 4) Light diff format (reminder)
**File:** `relative/path.lua`  
**Find:** (3–12 exact lines)

**OLD**
```lua
-- old snippet
```

**NEW**
```lua
-- replacement
```

Insertions:

**ADD**  
_Insert after:_ `anchor line`
```lua
-- new block
```

Keep notes to one bullet if needed (Retail vs Classic differences, taint risks).

---

## 5) UI change protocol
- Ask for **screenshot** if anchors/layout are unclear.
- Ensure: no overlapping frames, stable anchors, ESC closes popouts (not main window), readable at common scales.
- Localize any new labels/tooltips; add to help screen + `/slash help`.

---

## 6) Crash‑resistant habits
- **Reload Window** (`Ctrl+Shift+P → Developer: Reload Window`) if Codex slows.
- Keep conversations **short and specific**; avoid multi‑file refactors in one go.
- Close large files/tabs; keep repo clean (logs/binaries ignored/excluded).
- If Codex starts “running hundreds of steps,” stop it and request **plan + patch only**.

---

## 7) Triage when Codex crashes
- Reopen the **small addon folder** in a fresh VS Code window.
- Disable other heavy extensions temporarily: `code --disable-extensions` (test).
- Check **Help → Toggle Developer Tools → Console**; copy errors if recurring.
- Create a **minimal repro** repo with just `ui/main.lua` + `slash.lua`; test Codex there.

---

## 8) Optional tool configs (drop‑ins)
**`stylua.toml`**
```toml
column_width = 100
indent_type = "Spaces"
indent_width = 2
line_endings = "Unix"
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
```

**`.luacheckrc`**
```lua
std = "lua54"
globals = { "CreateFrame", "SlashCmdList", "UIParent", "GameTooltip", "C_Timer" }
ignore = { "631" } -- allow line too long warnings if needed
max_line_length = 120
```

---

## 9) Definition of Done (per change)
- Patch applied; no edits to `hello/` or `lib/`.
- No features removed; no regressions/taint.
- Stylua/Luacheck clean (or justified ignores).
- UI validated; help/docs/slash updated as needed.
- Diff recorded in commit or `DEV_NOTES_Codex.md` change log.
