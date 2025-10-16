# WinterPetCloud — A Practical Guide for New WoW Lua Developers (v2)

_Last updated: 2025-10-13 08:18_

This is a **living guide** to building and maintaining the WinterPetCloud addon. It consolidates **everything taught in the retired thread** into one coherent, teachable document. It’s written by a veteran WoW addon developer for a newcomer, with Classic Era first and simple shims for Retail.

> **How to use this document**
> - Read top-to-bottom once; then keep it open while you work.
> - Copy the exact commands and snippets; they’re designed to be safe.
> - Deeper topics (bugs, Codex guardrails, bootstrap checklists) live in their own docs and are linked—not duplicated—here.

---

## What You Need (once)

**Workspace-local tools** — put portable binaries you control under `.tools\bin` and make VS Code see them first:

```json
{
  "terminal.integrated.env.windows": {
    "PATH": "${workspaceFolder}\\.tools\\bin;${env:PATH}"
  }
}
```

**Lua toolchain outside the repo** — keep the repo clean; install luacheck in a per-user toolchain (examples):

- Per-user path: `%LOCALAPPDATA%\hererocks\wpc54`  

  Optional wrapper so tasks can call it without touching global PATH:

  ```bat
  @"%LOCALAPPDATA%\hererocks\wpc54\bin\luacheck.bat" %*
  ```
- Alternative fixed path: `D:\tools\hererocks\wpc54` (adjust the wrapper accordingly).

**Why this setup?** Reproducible builds, zero PATH drama for Codex/VS Code, and no accidental commits of local compilers.

---

## The Everyday Loop (short, repeatable)

1. **Format:**  
   ```powershell
   .\.tools\bin\stylua .
   ```

2. **Lint:**  
   ```powershell
   luacheck . --codes --exclude-files "lib/**"
   ```

3. **Run the addon in game** → `/reload` → `/wpc`

4. **Commit small**: focused diffs, present-tense message, then push.

**VS Code one-click:**

```json
{
  "version": "2.0.0",
  "tasks": [
    {"label":"fmt:stylua","type":"shell","command":".\\.tools\\bin\\stylua ."},
    {"label":"lint:luacheck","type":"shell","command":"luacheck . --codes --exclude-files \"lib/**\""},
    {"label":"fmt+lint","dependsOn":["fmt:stylua","lint:luacheck"],"dependsOrder":"sequence"}
  ]
}
```

**Configs kept in repo for consistency**:

- `.stylua.toml`
  ```toml
  column_width = 120
  indent_type = "Spaces"
  indent_width = 2
  quote_style = "AutoPreferDouble"
  ```
- `.luacheckrc`
  ```lua
  std = "lua54"
  globals = ('CreateFrame', 'LibStub', 'GetLocale', 'C_AddOns', 'GameTooltip', 'SlashCmdList', 'WinterPetCloud')
  exclude_files = lib/**
  codes = ('111', '112', '113', '121', '122', '211', '212', '213', '214')
  ```

---

## Project Shape (what files do)

- **`WinterPetCloud.lua`** — addon entry points, state, top-level orchestration (keep general; *no slash handlers here*).
- **`lua/slash.lua`** — all slash commands (e.g., `/wpc`) live here and call API on the namespace.
- **`lua/ui_list.lua`** — in-frame task list panel (add/remove/clear, import/export).
- **`lua/minimap.lua`** — minimap/LDB integration and “X/Y” display.
- **`lua/utils.lua`** — small helpers; avoid UI or SavedVariables logic here.
- **`local/enUS.lua`** — strings. Every UI label is a localized key here.
- **TOCs** — `*_Mainline.toc` and `*_Vanilla.toc` list the same modules; Classic-first, Retail via shims.

> Keep modules small (<500 lines). Each file starts with: **Name / Purpose / Scope** header. Use `NS` to export public bits; keep helpers `local`.

---

## Lua Patterns You’ll Use Daily

- **Namespace pattern** (WoW loads each file with `...`):
  ```lua
  local ADDON, NS = ...
  ```

- **Method vs function**:
  ```lua
  function NS:Print(msg)  -- method, gets self
    print(self.ADDON, msg)
  end
  NS:Print("hello")       -- passes NS as self
  ```

- **Early guards** (fewer nil errors):
  ```lua
  if not name or name == "" then return end
  ```

- **Safe iteration** (don’t mutate arrays mid-loop with `ipairs`):
  ```lua
  for i = #list, 1, -1 do
    if should_remove(list[i]) then table.remove(list, i) end
  end
  ```

- **Localization habit**:
  ```lua
  local L = WCL_L  -- from local/enUS.lua
  myButton:SetText(L.BTN_ADD)
  ```

---

## Q&A — Answers from the Thread (baked into this guide)

**Q: What’s the difference between these two?**  
`for i, row in ipairs(self.rows) do` **vs** `for _, row in ipairs(self.rows) do`  
**A:** `ipairs` returns `(index, value)`. Use the first form when you **need the index**; use `_` when you **ignore** it. If you remove items while iterating, switch to a numeric loop backwards to avoid skipping elements.

**Q: What is linting?**  
**A:** Automatic static checks for likely bugs and bad patterns before runtime (undefined globals, unused locals, shadowing, etc.). We use **luacheck**.

**Q: Formatter vs Linter?**  
**A:** Formatter (StyLua) rewrites layout (indentation, quotes, line width) for consistency. Linter (Luacheck) reports issues to fix.

**Q: How do I run a multi-line command in PowerShell?**  
**A:** Paste the block as-is (or type with **Shift+Enter** for a new line). For long commands, you can also use backtick line continuations or save as a `.ps1` script.

**Q: How do I combine multiple PATH entries in VS Code?**  
**A:** Use `;` and put repo tools first. Example:  
```json
{
  "terminal.integrated.env.windows": {
    "PATH": "${workspaceFolder}\\.tools\\bin;${workspaceFolder}\\.hererocks\\bin;${env:PATH}"
  }
}
```

**Q: PowerShell says `.\\.hererocks\bin\luacheck` isn’t recognized.**  
**A:** Call the batch shim with the call operator:  
```powershell
& ".\.hererocks\bin\luacheck.bat" --version
```
Or add that folder to the **current session’s** PATH:  
```powershell
$env:PATH = "$PWD\.hererocks\bin;$env:PATH"
```

**Q: Where would Stylua be if I installed with Scoop/WinGet?**  
**A:** Try:  
```powershell
(Get-Command stylua -ErrorAction SilentlyContinue).Source
where stylua
```
Common paths: `C:\Users\<you>\scoop\shims\stylua.exe` or `...\apps\stylua\current\stylua.exe`. You can copy the exe into `.tools\bin` for reliability.

**Q: Codex hangs / “Unknown MCP notification” / rollout path errors?**  
**A:** Keep Codex on a **short leash** (single-step asks). If sessions corrupt: close VS Code, back up and remove `C:\Users\<you>\.codex\sessions`, recreate it, then **New Task**. The “Unknown MCP notification” line is harmless (just a log from a minor protocol mismatch).

**Q: Can I lint without installing anything system-wide?**  
**A:** Yes. Use a per-user `hererocks` toolchain and vendor Stylua in `.tools\bin`. Alternatively, use Docker for luacheck:
```powershell
docker run --rm -v "${PWD}:/app" -w /app ghcr.io/lunarmodules/luacheck:latest luacheck . --codes --exclude-files "lib/**"
```

---

## Taming Codex (the helpful robot)

Codex can run commands and propose diffs — but don’t let it “plan your life.”

- Ask for **one step** at a time (e.g., “run this exact command and paste stdout only”).  
- If it stalls: **New Task**; if needed, **Developer: Reload Window**.  
- While Codex edits, **pause Dropbox/OneDrive** for this repo (avoid file locks).

**Micro-prompts you can trust**:
- Lint only: `Run exactly: luacheck . --codes --exclude-files "lib/**". Paste stdout only.`
- Format only: `Run exactly: .\.tools\bin\stylua .`

> Deeper guardrails and bootstrap steps live in **DEV_NOTES_Codex.md** and **Codex_Bootstrap_Checklist.md**.

---

## Packaging (clean releases)

Create `tools/pack.ps1` that copies only shipped files and zips them into `dist/`. Keep dev-only folders (like `.tools/`) out. Tie it to a VS Code task for 1‑click builds.

---

## Quality Gates (what “good” looks like)

- **StyLua passes cleanly.**  
- **Luacheck has no error-level issues** (warnings are fine; fix undefined globals and unused locals soon).  
- **No leaky globals.** Everything hangs off `NS` or is `local`.  
- **Classic-safe.** No Retail-only APIs in Classic; use shims or `if` guards.  
- **Strings centralized.** New UI text goes to `local/enUS.lua` first.

---

## Pointers (read these alongside; not duplicated here)

- **BUGS.md** — open issues and UX.  
- **Codex_Bootstrap_Checklist.md** — minimal steps for Codex.  
- **DEV_NOTES_Codex.md** — guardrails, approvals, diff etiquette.  
- **README.md** — high-level overview + packaging basics.  

---

## Where This Is Going (study guide)

- Add a **Lua crib sheet** (tables, metatables, events, taint basics) with runnable snippets.  
- Build a **Classic-first shim matrix** for Retail differences (frames, minimap, LDB, SavedVariables).  
- Formalize a **First Contribution** path: fmt → lint → tiny patch → test → pack → PR.  
- Collect **Codex micro-prompts** (single-step commands + “apply this exact diff” patterns).  
- Add a **Troubleshooting appendix** with common addon errors and fixes from BUGS history.  
