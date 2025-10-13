# WinterChecklist — Technical Notes (Living Document)

_Last updated: 2025-10-13 07:57_

This living document is a practical companion for developing and maintaining **WinterChecklist**. 
It flows from environment setup to daily workflows, design practices, and quick reference. 
It **does not duplicate** the following specialized docs; consult them alongside this file:

- **BUGS.md** — Source of truth for known issues and UX items.
- **Codex_Bootstrap_Checklist.md** — Minimal steps for bringing Codex online.
- **DEV_NOTES_Codex.md** — Guardrails and working agreements for Codex-driven edits.


## Environment & Tooling

**Workspace-local tools.** Place binaries you rely on under `.tools\bin` and put that ahead of PATH in VS Code:

```json
{
  "terminal.integrated.env.windows": {
    "PATH": "${workspaceFolder}\\.tools\\bin;${env:PATH}"
  }
}
```

**External Lua toolchain (no repo clutter).** Keep Lua/LuaRocks/luacheck out of the repo using a per-user toolchain, e.g. `%LOCALAPPDATA%\hererocks\wcl54`. Optionally add a wrapper script at `.tools\bin\luacheck.bat`:

```bat
@"%LOCALAPPDATA%\hererocks\wcl54\bin\luacheck.bat" %*
```

**Avoid sync-lock pain.** While actively editing with Codex, pause Dropbox/OneDrive for this repo or work outside the sync folder and copy back.

## Formatting & Linting

**Formatter — StyLua**  
Run:
```powershell
.\.tools\bin\stylua .
```
Sample config (`.stylua.toml`):
```toml
column_width = 120
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferDouble"
```

**Linter — Luacheck**  
Run:
```powershell
luacheck . --codes --exclude-files "lib/**"
```
Sample config (`.luacheckrc`):
```lua
std = "lua54"
globals = { "CreateFrame","LibStub","GetLocale","C_AddOns","GameTooltip","SlashCmdList","WinterChecklist" }
exclude_files = { "lib/**" }
codes = { "111","112","113","121","122","211","212","213","214" }
```

**VS Code Tasks** (`.vscode/tasks.json`):
```json
{
  "version": "2.0.0",
  "tasks": [
    { "label": "fmt:stylua", "type": "shell", "command": ".\\.tools\\bin\\stylua ." },
    { "label": "lint:luacheck", "type": "shell", "command": "luacheck . --codes --exclude-files \"lib/**\"" },
    { "label": "fmt+lint", "dependsOn": ["fmt:stylua","lint:luacheck"], "dependsOrder": "sequence" }
  ]
}
```

## Working with Codex (use it, don’t fight it)

- Keep asks **small and single-step** (e.g., “run this one command and paste stdout only”).  
- If a session misbehaves: start a **New Task**; if still odd, **Developer: Reload Window**.  
- Use **DEV_NOTES_Codex.md** for guardrails and **Codex_Bootstrap_Checklist.md** for one-time setup.

**Micro-prompts (safe):**
- Lint only: `Run exactly: luacheck . --codes --exclude-files "lib/**". Paste stdout only.`
- Format only: `Run exactly: .\\.tools\\bin\\stylua .`

## Packaging a Clean Zip

Create `tools\pack.ps1` to produce a distributable that excludes dev files and write a VS Code task to call it. 
(If you want, we can embed the script here or keep it referenced to avoid duplication with README.)

## Lua Practices & Patterns (WinterChecklist)

- **Keep slash commands isolated** in `lua/slash.lua`, not in `WinterChecklist.lua`.
- **Prefer early guards** (e.g., `if not name or name=="" then return end`) to avoid nil churn.
- **Use the namespace table (`NS`)** to share state; avoid `_G` pollution.
- **Don’t mutate arrays while iterating with `ipairs`**; if removing items, use a numeric loop backwards.
- **Colon vs dot**: `:` defines/calls methods with implicit `self`; `.` for plain functions.

## Quick Reference

**What is linting?** Static analysis that flags likely bugs and bad patterns before runtime. We use **luacheck**.  
**Formatter vs Linter?** Formatter (StyLua) rewrites layout; Linter (Luacheck) reports issues.  
**Why vendored tools?** Reliability. Codex and VS Code always find them regardless of system installs.

## Pointers to Other Docs (no duplication)

- **BUGS.md** — The canonical list of issues and UX polish items.
- **Codex_Bootstrap_Checklist.md** — Minimal steps and verification for Codex.
- **DEV_NOTES_Codex.md** — How we expect Codex to behave (approvals, scope, diffs).
- **README.md** — High-level intro and packaging basics.

## Future Additions

- Lua crib sheet (tables, metatables, events, taint basics) with small, runnable snippets.  
- Retail vs Classic shim matrix (frames, minimap, LDB, SavedVariables).  
- “First Contribution” flow (fmt → lint → small patch → test → pack).  
- Codex micro-prompts gallery (single-step commands + apply-diff pattern).  
- Troubleshooting appendix (common addon errors and their fixes).

## Project Notes (curated extract)

The following is a lightly cleaned extract from the current `NOTES.md`. 
It’s preserved here to keep this document self-contained while the specialized docs remain separate.


# WinterChecklist — Unified Notes & Q&A (Retired Thread Consolidation)

_Last updated: 2025-10-13 07:51_

This document consolidates the recent development thread into a **succinct, numbered reference** and merges it with the current project notes.
It avoids repeating content that already lives in **DEV_NOTES_Codex.md** (guardrails) and **Codex_Bootstrap_Checklist.md** (workflow), and it leaves **BUGS.md** as the authoritative bug log.

---

## 1. Purpose & Scope
- Serve as a **quick reference** for everyday work on WinterChecklist (Classic-first; Retail via shims).
- Capture reliable **env/tooling** steps and **Lua tips** discussed in the thread.
- **Do not** duplicate guardrails or bootstrap steps: see `DEV_NOTES_Codex.md` and `Codex_Bootstrap_Checklist.md` for those details.

## 2. Environment & Tooling (Windows + VS Code)
- **Vendored tools** in repo (predictable and fast):
  - Put binaries in `.tools\bin` and prefer workspace-local PATH.
  - VS Code: `.vscode/settings.json`
    ```json
    {
      "terminal.integrated.env.windows": {
        "PATH": "${workspaceFolder}\\.tools\\bin;${env:PATH}"
      }
    }
    ```
- **External Lua toolchain (no repo clutter)** via Hererocks:
  - Install to user space (example): `%LOCALAPPDATA%\hererocks\wcl54`
  - Optional wrapper in `.tools\bin\luacheck.bat` → `@"%LOCALAPPDATA%\hererocks\wcl54\bin\luacheck.bat" %*`
- Keep the working copy outside active sync during edits (or pause Dropbox/OneDrive) to avoid file locks with Codex.

## 3. Formatting & Linting
- **Format (Stylua):**
  ```powershell
  .\.tools\bin\stylua .
  ```
  `./.stylua.toml` (example):
  ```toml
  column_width = 120
  indent_type = "Spaces"
  indent_width = 2
  quote_style = "AutoPreferDouble"
  ```
- **Lint (Luacheck):**
  ```powershell
  luacheck . --codes --exclude-files "lib/**"
  ```
  `./.luacheckrc` (example):
  ```lua
  std = "lua54"
  globals = ('CreateFrame', 'LibStub', 'GetLocale', 'C_AddOns', 'GameTooltip', 'SlashCmdList', 'WinterChecklist')
  exclude_files = { "lib/**" }
  codes = { "111","112","113","121","122","211","212","213","214" }
  ```
- **VS Code Tasks** (`.vscode/tasks.json`):
  ```json
  {
    "version": "2.0.0",
    "tasks": [
      { "label": "fmt:stylua", "type": "shell", "command": ".\\.tools\\bin\\stylua ." },
      { "label": "lint:luacheck", "type": "shell", "command": "luacheck . --codes --exclude-files \"lib/**\"" },
      { "label": "fmt+lint", "dependsOn": ["fmt:stylua","lint:luacheck"], "dependsOrder": "sequence" }
    ]
  }
  ```

## 4. Codex in VS Code (Use Carefully)
- Prefer **small, single-step asks** (avoid multi-file plans).
- If a session misbehaves: **New Task** → if needed, **Developer: Reload Window**.
- Reference docs (do not duplicate here):
  - **Guardrails:** `DEV_NOTES_Codex.md`
  - **Bootstrap:** `Codex_Bootstrap_Checklist.md`
- **Micro-prompts** (safe):
  - Lint only: `Run exactly: luacheck . --codes --exclude-files "lib/**". Paste stdout only.`
  - Format only: `Run exactly: .\\.tools\\bin\\stylua .`

## 5. Packaging a Clean Zip
Create `tools\pack.ps1` and a VS Code task to produce a distributable that excludes dev files. (See this doc’s earlier thread steps.)

## 6. Lua Tips & Q&A
- **`ipairs` index vs value:**
  - `for i, row in ipairs(t) do` → need index.
  - `for _, row in ipairs(t) do` → ignore index (use `_`).
- **Don’t mutate arrays during `ipairs`**; use a numeric `for` backwards if removing items.
- **Slash commands stay in `lua/slash.lua`**, not in `WinterChecklist.lua`.
- **Early guards** help avoid nil errors: `if not name or name=="" then return nil end`.
- **Namespaces**: use the shared `NS` table; avoid leaking globals.

## 7. Where to Find Things (avoid duplication)
- **Guardrails / workflow** → `DEV_NOTES_Codex.md`, `Codex_Bootstrap_Checklist.md`.
- **Open bugs & UX work** → `BUGS.md` (source of truth).
- **Readme** → `README.md` for high-level intro and packaging basics.

## 8. Ideas to Add Later
- “Lua patterns” crib sheet: tables, metatables, events, secure/taint basics.
- Retail vs Classic shim matrix (frames, minimap, LDB, SavedVariables).
- “First Contribution” guide: fmt → lint → patch → test → pack.
- Codex micro-prompts gallery (single-step commands + apply-diff flow).
- Troubleshooting appendix (common addon errors and fixes).

---

## Appendix A — Current Project NOTES (lightly cleaned)
# Lua Notes — Core Concepts (from WinterChecklist exploration)

These notes summarize key Lua behaviors and conventions you’ve encountered while reading through **WinterChecklist.lua**.

---

## 1. `local ADDON_NAME, NS = ...`
- `...` = Lua's **varargs** operator — it captures all unnamed arguments passed to a chunk or function.
- In WoW, each addon file is *executed like a function call* where Blizzard passes:
  1. `ADDON_NAME`: a **string** (the addon folder name, e.g. `"WinterChecklist"`)
  2. `NS`: a **shared table** (namespace) common to all files in the same addon.
- `NS.ADDON = ADDON_NAME` stores the name for reference elsewhere.
- This pattern prevents global pollution and provides a shared space for addon data.

---

## 2. `do ... end` — Local scope block
- Creates a **temporary scope** for local variables and function definitions.
- Anything `local` inside the block vanishes after `end`.
- Common uses:
  - Keep helper functions private.
  - Create short‑lived constants or aliases (`local tinsert = table.insert`).
  - Improve speed via local lookups.
  - Group related functions neatly without leaking names.

---

## 3. `tcopy` and `tcopy_missing`
- Custom **deep‑copy / deep‑merge** helpers.
- `tcopy(dst, src)` overwrites `dst` values with those from `src` (recursively).
- `tcopy_missing(dst, src)` fills only *absent* keys (useful for defaults).
- They are exported as `NS.table_copy` / `NS.table_copy_missing` and called under those names.

---

## 4. Function definition styles
| Syntax | Equivalent to | Notes |
|--------|----------------|-------|
| `function NS:Print(...) end` | `NS.Print = function(self, ...) end` | “Method” form; gets `self` automatically. |
| `function NS.Print(...) end` | `NS.Print = function(...) end` | Plain function, no `self`. |
| `local function Foo(...) end; NS.Foo = Foo` | same as above | Useful if you want locals for recursion or testing. |

### Why `:` is used for Print/Debug
- Signals that the function is a **method** on the namespace.
- Keeps the local scope clean (no `local Print` name left behind).
- Automatically passes `self` when you call `NS:Print()`.

---

## 5. `self` and the colon operator
- `:` in **definitions** adds a hidden first parameter named `self`.
- `:` in **calls** passes the left‑hand value as that parameter.
- Example:
  ```lua
  function NS:Debug(msg)
    print(self.ADDON, msg)
  end

  NS:Debug("hi")   -- calls NS.Debug(NS, "hi")
  ```
- Use `.` for plain functions (no implicit `self`), `:` for methods needing context.

---

## 6. General addon best practices illustrated
- **Use locals** wherever possible; avoid polluting `_G` (the global table).
- **Share data/functions** only through the `NS` table.
- **Keep utilities** inside `do ... end` blocks for tidy organization.
- **Alias global functions** (e.g., `local print = print`) inside blocks for performance.
- **Separate configuration and runtime logic** with helpers like `table_copy_missing`.

---

## 7. Mental model summary
- Lua’s modules are just **tables** of functions.
- `:` is syntactic sugar for passing that table as `self`.
- `do ... end` provides a temporary workspace.
- WoW loads each file as a **chunk** with `...` filled automatically.
- Everything is built from simple language features — no classes, no imports; you assemble structures manually.

---

## 8. How locals survive past a `do ... end`

- When a `do ... end` block finishes, **the names** of any locals go out of scope,
  but **the values** they referred to remain alive if something still references them.

- Example:

  ```lua
  do
    local function tcopy(dst, src)
      -- ...
    end
    NS.table_copy = tcopy
  end
  ```

  Here:
  - `tcopy` is a local variable holding a function.
  - `NS.table_copy = tcopy` assigns that same function to `NS.table_copy`.
  - When the block ends, the *name* `tcopy` vanishes,
    but the *function value* remains alive because `NS.table_copy` still points to it.

- Inside `tcopy`, recursive calls (`tcopy(dst[k], v)`) work because Lua keeps an
  **upvalue** reference to the original local function.

- This is how Lua modules “export” functions safely:
  private locals inside a `do ... end`, public handles via `NS.*`.

---

## 9. Some propmts
  - Assume that I have used your three new files word for word. Move all code from winterchecklist.lua having to do with the minimap button into a new file minimap.lua. Do this revision in the same way as you just did the previous revision -- making sure all four files work well together (utils, slash, minimap and winterchecklist) and note the order I should give in the TOC for them. Provide the new files as downloads only, do not display them.

  - You are a seasoned World of Warcraft LUA developer with thousands of successful addons to your credit and a desire to teach the world your skills. Assume that I have taken all those files from the last result word for word. Now use those to please review all LUA files (not lib/) and check for
    • inconsistencies
    • magic numbers that should be declared at the beginning
    • localization that should be handled
    • opportunities to have a tiny bit of code actually as a user preference togglable in the options screen
    • top-of-file descriptors that should be revised or added
    • modest comments that should be added for longer sections of code that don't seem to have any
    • namespace or leaky globals
    • other good practices that keep lean, durable code.
    • good reliance on the 4 lib files we've imported
    • consideration of any other lib files we should import, based on the product direction we are going
  - Complete these recommendations by integrating them into the files you just provided in the last result and but before you link them again as downloadable files, think one more time and be sure we're not missing a better approach.
  - Think about what kind of Checklist features are possible for tasks and activities in a Classic Era Wow addon. What are we missing that someone else might have that we could actually do better! Should there be categories? Drilldowns? Preset libraries? in-frame task list UI (with add/remove/clear + import/export buttons) ?

  - Please note the following
    • As before, you are an experienced LUA developer with billions of successful addons to your credit.
    • Please use a fresh view of 009 zip direct from project files, produce milestone A by merging sensibly the proposed code changes with files from the existing zip.
    • Before committing to the change, pause and think again about all the changes, ask me at least three clarifying questions that might make the release even better. Make sure that you have not dropped any features; avoid over-coding; support classic_era primarily with extensibility to retail; make sure that this leads sensibly to Milestone B.
    • Finally provide the new files in a downloadable link (don't display actual code since we don't want to fill up the browser).
    • Provide a high level overview. Note any recommended changes to the scope of Milestone B.

  - Quick clarifying questions (at least 3)

    - List anatomy: do you want flat tasks first (single list) or top-level categories + tasks right away? (I can keep Milestone A flat and visually group later, or seed simple categories now so B is a pure UI step.)
    - Flat lists are simpler to implement and use initially, making for a faster Milestone A, while categories + tasks provide better organization and scalability but require more UI and logic upfront.
    - Persistence scope: should the task list be per-character only (Classic-standard) or offer an Account-wide list toggle now (useful for raid prep templates)?
    - (Note: Account-wide persistence requires a different SavedVariables structure and may involve migration logic if switching from per-character to account-wide storage. Please specify if you want to support both modes or just one for now.)
    - Persistence scope: should the task list be per-character only (Classic-standard) or offer an Account-wide list toggle now (useful for raid prep templates)?
    - Import/Export default: when a user imports without a category, should it replace the current list (simple, but risks accidental data loss) or merge (smarter, avoids accidental wipes but may cause clutter)?
    - Import/Export default: when a user imports without a category, should it replace the current list (simple) or merge (smarter, avoids accidental wipes)?
    - LDB/minimap text: show “X/Y” (number of completed tasks out of total) always, or “X” when any incomplete; blank when all done (quieter)?
    - Search/filter bar: include a small inline search box in Milestone A (improves discoverability but adds UI complexity), or keep it to the All/Incomplete toggle only (fewer widgets to start)?
    - Sound cues: enable a subtle completion sound by default (LSM = LibSharedMedia, a popular WoW sound/media library), or off by default with a toggle in Options?
    - Retail parity: OK to keep code paths Classic-first and defer Retail testing until after Milestone A (retail shims—compatibility code that adapts Classic code to work in Retail—stay in place)?
    - Visual density: prefer a compact single-column list (space efficient) or two-column when the window is wide (more at-a-glance)? Consider accessibility and readability for users who may benefit from larger fonts or higher contrast.
    - Reorder now vs later: for Milestone A, is Up/Down arrows acceptable (drag in Milestone B), or do you want to skip reordering until B?
---

## 10. Solo Git Workflow

  - Branching: Keep main clean. Create feature branches (git checkout -b feature/luacheck) for work, merge back once tested.
  - Status checks: Run git status often to confirm what’s staged/unstaged; catch accidental changes early.
  - Small commits: Group related edits; git add -p helps stage only the intended hunks.
  - Commit messages: Use present tense summaries (“Add luacheck globals”). Include context if needed in the body.
  - Sync cycle: For remotes, git fetch + git pull --rebase before starting, git push after review/testing.
  - Housekeeping: Clean temp files before committing; keep .gitignore updated. Tag releases with git tag when ready to package.
  - Recovery: If something goes wrong, use git stash, git commit --amend, or new branches instead of destructive resets.

## 11. BLizzard Global Namespace

  - Think of _G as Lua’s global environment table. In WoW, Blizzard populates _G with every API object, frame, and constant before your addon runs. So when you write local UIParent = _G.UIParent, you’re pulling the value Blizzard registered into that table. Conceptually it’s the shared “global namespace” rather than a special Blizzard object—Lua simply treats all globals as keys on _G, and Blizzard uses that to expose its API.

## 12. luacheck from inside Codex / VSCode

 - 1) Put Codex on a leash (copy-paste one of these)

    Use one micro-prompt at a time. These stop it from planning big workflows.

    Just run luacheck (single command, no edits):
     - Execute exactly this command and nothing else, in one step:
       luacheck . --codes --exclude-files "lib/**"
       Return only the raw stdout. If the command is not found, stop and ask me—do not install or plan anything.

    Just run Stylua (single command, no edits):
     - Execute exactly this command and nothing else:
       .\\.tools\\bin\\stylua .
       Return only the raw stdout. If unavailable, stop and ask.

    If it still “plans”:
     - Do not generate a plan. Do not install anything. Run exactly the one shell command I provided and paste only stdout. If you need more info, ask me first.

    (Your environment already shows approval_policy: on-request, so these prompts should keep it to a single step.)

  - 2) Kill the current runaway task cleanly
    • In VS Code, close the Codex panel tab, then reopen it → New Task.
    • If it won’t stop, Developer: Reload Window.
    • Avoid Delete Session (that’s what triggered the MCP rollout errors earlier).

  - 3) Keep momentum without Codex (fast local loop)
    You’re already green here:
       .\.tools\bin\stylua .
       luacheck . --codes --exclude-files "lib/**"

    If you want the warnings captured for review:
       luacheck . --codes --exclude-files "lib/**" | Tee-Object -FilePath .\.tools\luacheck-last.txt

  - 4) Next milestone without waiting on Codex
    If you want, I’ll drop a rebased, line-exact patch for Pillar #1 (task panel add/remove/clear + import/export + SavedVariables) using our light format (File / Find / OLD / NEW). You can apply it manually or hand it to Codex to “apply exactly.” No planning, no installs.

  - 5) If Codex times out again
    Use this tiny diagnostic ask (it’s safe and quick):
      - Print the absolute current working directory with pwd (PowerShell). Paste only the path. Do not do anything else.
    If that returns instantly, follow with the single luacheck command above.

## 13. Instructions to Codex for how to work on this project

  - Please start working incrementally with the bug list, while protecting your memory usage against Codex crashes or freezes, and ping me for approvals only as required.

## 14. Other task list addons
  These are wonderful inspirations:
  - https://www.curseforge.com/wow/addons/nys-todolist