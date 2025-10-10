--[[
  @file    lua/slash.lua
  @brief   /wcl commands to drive core actions.
]]
local ADDON, NS = ...
local L = NS.L

SLASH_WINTERCHECKLIST1 = "/wcl"
SlashCmdList["WINTERCHECKLIST"] = function(msg)
  msg = (msg or ""):lower()
  local cmd, rest = msg:match("^(%S+)%s*(.*)$")
  if not cmd or cmd == "" or cmd == "toggle" then
    NS:ToggleUI()
  elseif cmd == "debug" then
    WinterChecklistDB.debug = not WinterChecklistDB.debug
    NS:Print(WinterChecklistDB.debug and L.DEBUG_ENABLED or L.DEBUG_DISABLED)
  elseif cmd == "minimap" then
    NS:ToggleMinimapIcon()
  elseif cmd == "options" or cmd == "opt" then
    if NS.Options and NS.Options.Open then NS.Options:Open() end
  elseif cmd == "help" or cmd == "?" then
    if NS.Help then NS.Help:Show(NS.frame) end
  else
    NS:Print(L.SLASH_HEADER)
    NS:Print("  " .. L.SLASH_TOGGLE)
    NS:Print("  " .. L.SLASH_DEBUG)
    NS:Print("  " .. L.SLASH_MINIMAP)
    NS:Print("  " .. L.SLASH_OPTIONS)
  end
end
