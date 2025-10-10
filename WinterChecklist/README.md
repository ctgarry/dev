# WinterChecklist

A clean-slate, single-file World of Warcraft addon scaffold that targets **Retail** and **Classic Era** from one repo using flavor-specific TOCs and VS Code tasks.

- **Single Lua file** (`WinterChecklist.lua`)
- **Dual TOCs** (`WinterChecklist_Mainline.toc` for Retail, `WinterChecklist_Vanilla.toc` for Classic Era)
- **Zero taint**, strict namespacing, safe event router
- **VS Code tasks** to zip for CurseForge and install directly into live AddOns folders

> Status: early scaffold. Features will expand incrementally (minimap button, snapshots, import/export schema, etc.).

---

## Features

- Movable/clamped UI frame with saved position
- Zone-aware label (updates on zone/subzone change)
- Slash commands: `/wcl`, `/wcl show`, `/wcl hide`, `/wcl reset`, `/wcl debug`, `/wcl export`, `/wcl import <table>`
- Lightweight Lua serializer/deserializer (safe env)

---

## Repo Layout

```
WinterChecklist.lua
WinterChecklist_Mainline.toc     # Retail
WinterChecklist_Vanilla.toc      # Classic Era
.tools/
  build.ps1                      # build/install script (PowerShell)
.vscode/
  tasks.json                     # VS Code tasks (zip/install)
.dist/                           # output zips (generated)
```

---

## Building & Installing

### Prereqs
- Windows with PowerShell 5+ or PowerShell 7+
- Visual Studio Code (optional but recommended)

### VS Code Tasks
Open the repo in VS Code and run:

- **Zip: Retail → CurseForge** – makes `.dist/WinterChecklist-<version>-Retail.zip`
- **Zip: Classic Era → CurseForge** – makes `.dist/WinterChecklist-<version>-ClassicEra.zip`
- **Install: Retail (live AddOns)** – copies files into `…\_retail_\Interface\AddOns\WinterChecklist\`
- **Install: Classic Era (live AddOns)** – copies files into `…\_classic_era_\Interface\AddOns\WinterChecklist\`

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
/wc
/wc show
/wc hide
/wc reset
/wc debug
/wc export
/wc import {some_table_here}
```

A small window labeled **WinterChecklist** appears; drag to move. Zone name updates as you travel.

---

## Releasing to CurseForge

1. Bump `## Version:` in the target TOC(s).
2. Run the **Zip** task for the flavor you’re publishing.
3. Upload the generated zip from `.dist/`.
4. Fill out changelog & set the correct game flavor on CurseForge.

---

## Contributing / Local Dev

- Keep all runtime code in `WinterChecklist.lua` while the project is single-file.
- If adding assets later, ensure they’re covered by the include list in `.tools/build.ps1`.
- Avoid flavor-specific APIs in Lua; if necessary, gate by `WOW_PROJECT_ID` checks.

---

## License

This project is licensed under the MIT License. See [`LICENSE.txt`](LICENSE.txt) for details.
