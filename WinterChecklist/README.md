# WinterChecklist


A tiny per‑character daily/weekly checklist for World of Warcraft. Works on **Retail** and **Classic Era**. UI includes checkboxes, compact +/E/D controls, minimap toggle, resizable window, help panel, and clickable zone name to open the world map.


## Features
- Daily/Weekly tasks with automatic resets
- Compact UI: add/edit/delete (+/E/D) and checkboxes
- Minimap button to toggle
- Resizable window; draggable
- Help panel with quick tips
- Retail + Classic Era compatible


## Install (manual)
1. Unzip into your WoW AddOns folder as `Interface/AddOns/WinterChecklist/`.
2. Ensure the folder contains:
- `locale_enUS.lua` # localization
- `compat.lua`      # compatibility 
- `util.lua`        # shared helpers, icons, small utils; creates/uses NS
- `storage.lua`     # EnsureDB, profiles, snapshot helpers
- `filters.lua`     # mode-aware + search filtering
- `tasks.lua`       # select/edit/delete/reset task ops
- `import.lua`      # import dialog (opaque + Esc)
- `export.lua`      # export dialog (opaque + Esc)
- `core.lua`        # event frame + slash: calls NS.OnReady, NS.RefreshUI(), etc.
- `ui_core.lua`     # builds Task list window (layout, search/filter, row rendering, selection, keyboard shortcuts)
- `ui_extras.lua`   # builds Minimap button, Options panel, Help popup, and copy/link dialogs
- `WinterChecklist.toc` (Retail)
- `WinterChecklist_ClassicEra.toc` (Classic Era)


If the addon appears as **Out of Date**, bump the `## Interface` number in the `.toc` files to match your client.


## Usage
- Open UI: minimap button (left‑click) or `/wcl show`
- Add task: type a name, pick **Daily** or **Weekly**, click **+**
- Edit/Delete: select a task, change fields, click **E** or **D**
- Toggle done: click a task’s checkbox
- Map: click the zone label (bottom‑left)


### Slash commands (optional)

/wcl show 
/wcl hide 
/wcl add daily 
/wcl add weekly 
/wcl done 
/wcl remove

## Development (VS Code + Dev Container)
This repo includes a `.devcontainer` and a VS Code task to run **Wowless** (a headless WoW UI/Lua runner) so you can test offline.


### Quick start
- In VS Code: **Reopen in Container** (Dev Containers extension)
- First open will auto‑clone & bootstrap Wowless
- Run task: **Ctrl+Shift+B** → *Wowless: Run WinterChecklist*


## Packaging (release zip)
Create a zip named like `WinterChecklist-1.2.1.zip` containing the **folder** `WinterChecklist/` with the files inside. Upload to CurseForge.


## License
MIT — see `LICENSE.txt`.