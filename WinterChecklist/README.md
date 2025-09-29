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
- `WinterChecklist.lua`
- `WinterChecklist_Mainline.toc` (Retail)
- `WinterChecklist_Vanilla.toc` (Classic Era)


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