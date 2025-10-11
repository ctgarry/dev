--[[
  @file    local/enUS.lua
  @brief   American English strings. Missing keys fall back to key name.
]]
local ADDON, NS = ...
local L = {}
NS.L = setmetatable(L, { __index = function(t, k) return k end })

-- General
L.ADDON_NAME         = "WinterChecklist"
L.OK                 = "OK"
L.CANCEL             = "Cancel"
L.CLOSE              = "Close"
L.HELP               = "Help"
L.DEBUG_ENABLED      = "Debug enabled."
L.DEBUG_DISABLED     = "Debug disabled."

-- Slash / help
L.SLASH_HEADER       = "Slash commands:"
L.SLASH_TOGGLE       = "/wcl toggle      - Toggle the UI"
L.SLASH_DEBUG        = "/wcl debug       - Toggle debug logging"
L.SLASH_MINIMAP      = "/wcl minimap     - Toggle the minimap icon"
L.SLASH_OPTIONS      = "/wcl options     - Open Options"

-- Options
L.OPT_PANEL_TITLE    = "WinterChecklist"
L.OPT_MINIMAP        = "Show minimap icon"
L.OPT_DEBUG          = "Enable debug logging"
L.OPT_LOCK_FRAME     = "Lock main window (disable drag)"
L.OPT_SHOW_HELP      = "Show help button on main window"
L.OPT_FEEDBACK_SECTION = "Feedback"
L.OPT_SOUND_ON_ADD   = "Play sound when adding a task"
L.OPT_SOUND_SELECT   = "Task-added sound"
L.OPT_SOUND_NONE     = "None"
L.OPT_PROFILE_COPY   = "Copy tasks from another character"
L.OPT_FROM_CHARACTER = "From character"
L.OPT_COPY_BUTTON    = "Copy Tasks"

-- Tasks
L.TASKS_HEADER       = "Tasks"
L.TASKS_PLACEHOLDER  = "Add a new task..."
L.TASKS_ADDED        = "Task added: %s"
L.TASKS_REMOVED      = "Task removed: %s"
L.TASKS_COPIED_FMT   = "Copied tasks from %s."

-- Help
L.HELP_SUMMARY_TITLE = "WinterChecklist — Quick Summary"
L.HELP_SUMMARY_BODY  = "Track short checklist items per character. Use Options for details, profiles, and minimap."

L.FILTER_FREQ_ALL    = "Filter Freq All"
L.FILTER_FREQ_DAILY  = "Filter Freq Daily"
L.FILTER_FREQ_WEEKLY = "Filter Freq Weekly"
L.FILTER_INCOMPLETE  = "Filter Incomplete"
L.CLEAR              = "Clear"
L.IMPORT             = "Import"
L.EXPORT             = "Export"
L.ADD_TASK           = "Add Task"
L.EDIT_TASK          = "Edit Task"
L.DELETE_TASK        = "Delete Task"
L.OPT_ACCOUNT_WIDE   = "Opt Account Wide"
L.IMPORT_MERGE_OR_REPLACE = "Import Merge Or Replace"
L.IMPORT_REPLACE     = "Import Replace"