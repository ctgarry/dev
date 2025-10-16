# WinterChecklist

A clean-slate, modular World of Warcraft addon scaffold that targets **Retail** and **Classic Era** from one repo using flavor-specific TOCs and VS Code tasks.

- **Modular Lua stack** (`WinterChecklist.lua` bootstrap + `lua/` modules for UI, tasks, slash commands, minimap, options)
- **Dual TOCs** (`WinterChecklist_Mainline.toc` for Retail, `WinterChecklist_Vanilla.toc` for Classic Era)
- **Bundled libraries** via `lib/` (LibStub, LibDataBroker, LibDBIcon, LibSharedMedia) with strict namespacing to stay taint-free
- **VS Code tasks** to zip for CurseForge and install directly into live AddOns folders
- **Developer docs** under `.tools/notes/` (technical guide, bug log, Codex guardrails, bootstrap checklist)

> Status: active alpha. Core UI, minimap integration, import/export, and profile tooling are in place; polish and content are evolving.

---

## Features

- Movable, resizable UI frame with saved position, scrollable task list, search, frequency filter, and footer actions (Add / Import / Export / Clear)
- Inline help overlay and zone-aware header so tasks stay contextual while you travel
- Minimap icon (LibDBIcon) plus options panel toggles for account-wide mode, locking the UI, showing help, and sound feedback on task add
- Account-wide or per-character task storage with character copy tools, safe import/export serializer, and reorderable rows
- Slash commands: `/wcl`, `/wcl toggle`, `/wcl options`, `/wcl minimap`, `/wcl debug`, `/wcl export`, `/wcl import`, `/wcl help`

---

## Repo Layout

```
WinterChecklist.lua
WinterChecklist_Mainline.toc     # Retail
WinterChecklist_Vanilla.toc      # Classic Era
lua/                             # UI, tasks, minimap, slash, utils modules
i18n/
  enUS.lua                       # localization strings
lib/                             # bundled libs (LibStub, LDB, DBIcon, LSM)
.tools/
  build.ps1                      # build/install script (PowerShell)
  notes/                         # developer guides, bug log, guardrails
.vscode/
  tasks.json                     # VS Code tasks (zip/install)
.dist/                           # output zips (generated)
```

---

## Developer Notes & Guides

- `.tools/notes/WinterChecklist-Technical-Notes.md` - living technical guide for building and maintaining the addon
- `.tools/notes/DEV_NOTES_Codex.md` - guardrails, coding standards, and workflow expectations
- `.tools/notes/Codex_Bootstrap_Checklist.md` - repeatable bootstrap steps for a clean Codex workspace
- `.tools/notes/BUGS.md` - running bug and observation log with status checkpoints

---

## Building & Installing

### Prereqs
- Windows with PowerShell 5+ or PowerShell 7+
- Visual Studio Code (optional but recommended)

### VS Code Tasks
Open the repo in VS Code and run:

- **Zip: Retail -> CurseForge** - makes `.dist/WinterChecklist-<version>-Retail.zip`
- **Zip: Classic Era -> CurseForge** - makes `.dist/WinterChecklist-<version>-ClassicEra.zip`
- **Install: Retail (live AddOns)** - copies files into `.\_retail_\Interface\AddOns\WinterChecklist\`
- **Install: Classic Era (live AddOns)** - copies files into `.\_classic_era_\Interface\AddOns\WinterChecklist\`

> Tasks call `.tools/build.ps1` which:
> - Picks the correct TOC for the flavor
> - Renames it to `WinterChecklist.toc` in the destination
> - Copies the project files with sane include/exclude rules
> - (Zip mode) packages with a proper `WinterChecklist/` folder at the archive root

### Running the Script Manually
```powershell
# Zip for Classic Era
pwsh -NoProfile -File .tools/build.ps1 -Flavor classic_era -Mode zip

# Install to live Retail AddOns
pwsh -NoProfile -File .tools/build.ps1 -Flavor retail -Mode install
```

Override default WoW install paths if needed:
```powershell
pwsh -NoProfile -File .tools/build.ps1 -Flavor retail -Mode install -RetailDir "D:\Games\World of Warcraft\_retail_"
pwsh -NoProfile -File .tools/build.ps1 -Flavor classic_era -Mode install -ClassicEraDir "E:\WoW\_classic_era_"
```

> If PowerShell complains about execution policy, run once as admin:
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
> ```

---

## Multi-TOC Setup

The game auto-selects the appropriate TOC by suffix:
- Retail reads `WinterChecklist_Mainline.toc`
- Classic Era reads `WinterChecklist_Vanilla.toc`

The build script copies only the chosen TOC and writes it out as `WinterChecklist.toc` in the zip/install output.

---

## Usage In-Game

Open chat and use:
```
/wcl
/wcl toggle
/wcl options
/wcl minimap
/wcl debug
/wcl export
/wcl import <paste or leave empty for popup>
/wcl help
```

A small window labeled **WinterChecklist** appears; drag to move. Zone name updates as you travel.

---

## Releasing to CurseForge

1. Bump `## Version:` in the target TOC(s).
2. Run the **Zip** task for the flavor you're publishing.
3. Upload the generated zip from `.dist/`.
4. Fill out changelog & set the correct game flavor on CurseForge.

---

## Contributing / Local Dev

- Keep `WinterChecklist.lua` focused on bootstrap + glue; place feature work in purpose-built modules under `lua/`.
- Add user-facing text to `i18n/enUS.lua` (and future locale files) instead of hardcoding strings.
- Treat `lib/` as vendor space; update via upstream drops, not manual edits.
- If adding assets later, ensure they're covered by the include list in `.tools/build.ps1`.
- Avoid flavor-specific APIs in Lua; if necessary, gate by `WOW_PROJECT_ID` checks.
- Line endings: `.gitattributes` pins `.lua`/`.toc` files to LF. Leave editors on LF so Git stays quiet across platforms.

---

## License

This project is licensed under the MIT License. See [`LICENSE.txt`](LICENSE.txt) for details.
