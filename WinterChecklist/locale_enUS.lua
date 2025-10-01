-- locale_enUS.lua
-- English strings for WinterChecklist. All UI and CLI text should go through NS.L[...] via a strict T(key) helper.

local ADDON, NS = ...
NS.L = {}  -- non-additive: replace entirely each load
local L = NS.L

-- ===== UI: general =====
L.FILTER_LABEL          = "Filter:"
L.TITLE                 = "Checklist"
L.ZONE_PREFIX           = "Zone: %s"
L.ZONE_UNKNOWN          = "—"

-- ===== Buttons / controls =====
L.BTN_ADD               = "+"
L.BTN_CLOSE             = "Close"
L.BTN_COPY_FROM         = "Copy From Selected"
L.BTN_DELETE            = "-"
L.BTN_EDIT              = "E"
L.BTN_GEAR_TIP          = "Tools / Import/Export"
L.BTN_HELP              = "?"
L.BTN_REFRESH           = "Refresh"
L.BTN_TOGGLE            = "Toggle Checklist"
L.MINIMAP_SHOW          = "Show minimap button"

-- ===== Dialogs / prompts =====
L.DLG_ADD_TASK          = "Add Task"
L.DLG_CANCEL            = "Cancel"
L.DLG_EDIT_TASK         = "Edit Task"
L.DLG_ENTER_TEXT        = "Please enter text."
L.DLG_OK                = "OK"
L.COPY_LINK_TEXT        = "Ctrl+A, Ctrl+C to Copy to your Clipboard."

-- ===== Messages (UI guidance) =====
L.MSG_PROFILE_EMPTY     = "Selected profile is empty."
L.MSG_SELECT_PROFILE    = "Select a profile to copy from."
L.MSG_SELECT_TO_DELETE  = "Click a task first, then press - to delete."
L.MSG_SELECT_TO_EDIT    = "Click a task first, then press E to edit."

-- ===== Filters =====
L.FILTER_ALL            = "All"
L.FILTER_DAILY          = "Daily"
L.FILTER_WEEKLY         = "Weekly"

-- ===== Help / links =====
L.CONTRIB               = "Active Contributors: |cffffffffbcgarry, wizardowl, beahbabe|r"
L.HELP_LINKS            = "Links"
L.HELP_TITLE            = "Checklist — Help"
L.LINK_CURSE_LABEL      = "Curse"
L.LINK_CURSE_TIP        = "Click to copy the CurseForge page URL."
L.LINK_GITHUB_LABEL     = "GitHub"
L.LINK_GITHUB_TIP       = "Click to copy the addon source URL."

-- Multiline help body (UI uses as a single block)
L.HELP_BODY = table.concat({
  "|cffffff00Quick UI how-to|r",
  "• Use the search box to filter tasks.",
  "• Radio buttons at the bottom filter: All / Daily / Weekly.",
  "• + to add, E to edit selected, - to delete.",
  "• Right-click a row for actions.",
  "• Click a task's checkbox to mark complete/incomplete.",
  "• Drag the window by its title; drag the bottom-right corner to resize.",
  "• Zone button → opens the world map.",
  "• Minimap button → toggles this window (can be hidden).",
  "",
  "|cffffff00Commands|r",
  "/wcl → toggle the window",
  "/wcl add <text> → add a daily task",
  "/wcl addw <text> → add a weekly task",
  "/wcl minimap → toggle the minimap button",
  "/wcl reset [daily|weekly|all] → reset tasks",
  "/wcl fixframe → reset window position/size",
  "/wcl help → show this help",
  "",
  "|cffffd200Developer Notes|r",
  "Quick reset: |cffffff78/wcl fixframe|r resets size & position. Or hard reset with:",
  "|cffaaaaaa/run if WinterChecklistDB then WinterChecklistDB.window=nil end ReloadUI()|r",
}, "\n")

-- ===== CLI / slash feedback =====
L.CMD_ADDED_DAILY       = "Added daily task."
L.CMD_ADDED_WEEKLY      = "Added weekly task."
L.CMD_CANNOT_ADD_BLANK  = "Cannot add a blank task."
L.CMD_FRAME_RESET       = "Frame reset to default size & centered."
L.CMD_HELP              = "Commands: /wcl (toggle), /wcl add <text>, /wcl addw <text>, /wcl minimap, /wcl reset [daily|weekly|all], /wcl fixframe, /wcl help"
L.CMD_MINIMAP_HIDDEN    = "Minimap button hidden."
L.CMD_MINIMAP_SHOWN     = "Minimap button shown."
L.CMD_RESET_ALL         = "All tasks reset to incomplete."
L.CMD_RESET_DAILY       = "All daily tasks reset to incomplete."
L.CMD_RESET_WEEKLY      = "All weekly tasks reset to incomplete."

-- ===== Import / Export =====
L.DLG_EXPORT            = "Export"
L.DLG_IMPORT            = "Import"
L.DLG_CLOSE             = "Close"
L.EXPORT_NOTE           = "Press Ctrl-A then Ctrl-C to copy. Paste anywhere to save."
L.IE_PROMPT             = "Import or Export?"
L.IMPORT_ABORT_BADLINE  = "Import aborted: bad line: %s"
L.IMPORT_INSTRUCTIONS   = "Import format:\n- Lines starting with 'd: ' = daily task\n- Lines starting with 'w: ' = weekly task\n- Any other line is INVALID and will abort the import."

-- ===== Default sample tasks (shown on first run) =====
L.SAMPLE_DAILY_TASK     = "Sample daily: Turn in daily quest"
L.SAMPLE_WEEKLY_TASK    = "Sample weekly: Kill world boss"
