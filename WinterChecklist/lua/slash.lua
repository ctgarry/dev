-- slash.lua
-- Centralized slash commands for WinterChecklist. Depends on utils.lua + main NS APIs.

local ADDON_NAME, NS = ...
NS = NS or _G[ADDON_NAME] or {}
_G[ADDON_NAME] = NS

local U = NS.Util

local function show_help()
  U.print("Slash commands:")
  U.print("/wcl help        - Show this help")
  U.print("/wcl toggle      - Toggle the UI")
  U.print("/wcl debug       - Toggle debug logging")
  U.print("/wcl minimap     - Toggle the minimap icon")
  U.print("/wcl profile ... - Profile-related (stub)")
end

local function handle(msg)
  msg = U.trim(msg)
  local cmd, rest = msg:match("^(%S+)%s*(.*)$")
  cmd = (cmd or ""):lower()

  if cmd == "" or cmd == "help" or cmd == "?" then
    show_help()
  elseif cmd == "toggle" or cmd == "ui" then
    NS:ToggleUI()
  elseif cmd == "debug" then
    NS:ToggleDebug()
  elseif cmd == "minimap" then
    NS:ToggleMinimap()
  elseif cmd == "profile" then
    U.print("Profile command not yet implemented. Args: "..(rest or ""))
  else
    U.print("Unknown command. Try /wcl help")
  end
end

-- Register two aliases
local function register(alias)
  local tag = "WINTERCHECKLIST_" .. alias:upper():gsub("[^A-Z0-9]", "_")
  _G["SLASH_"..tag.."1"] = alias
  SlashCmdList[tag] = handle
end

register("/wcl")
register("/winterchecklist")
