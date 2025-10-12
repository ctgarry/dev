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
    NS.ToggleUI()
  
  elseif cmd == "debug" then
    WinterChecklistDB.debug = not WinterChecklistDB.debug
    NS:Print(WinterChecklistDB.debug and L.DEBUG_ENABLED or L.DEBUG_DISABLED)
  
  elseif cmd == "minimap" then
    NS:ToggleMinimapIcon()
  
  elseif cmd == "options" or cmd == "opt" then
    if NS.Options and NS.Options.Open then NS.Options:Open() end
  
  elseif cmd == "export" then
    if NS.Tasks and NS.Tasks.Export then
      local payload = NS.Tasks:Export()
      if NS.Util and NS.Util.ShowTextPopup then
        NS.Util.ShowTextPopup(L.EXPORT_TITLE or "WinterChecklist — Export", payload)
      else
        NS:Print(L.EXPORT_READY or "Export string ready. Copy from the popup.")
        print(payload)
      end
    end

  elseif cmd == "import" then
    local data = NS.Util and NS.Util.trim(rest or "") or (rest or "")
    if (not data or data == "") and NS.Util and NS.Util.ShowTextPopup then
      NS.Util.ShowTextPopup(L.IMPORT_TITLE or "WinterChecklist — Paste Import", "")
      NS:Print(L.IMPORT_INSTRUCTIONS or "Paste an export string into the popup and click Accept.")
    elseif NS.Tasks and NS.Tasks.ImportWithPrompt then
      NS.Tasks:ImportWithPrompt(data)
    end

  elseif cmd == "help" or cmd == "?" then
    if NS.Help then NS.Help:Show(NS.frame) end

  else
    NS:Print(L.SLASH_HEADER)
    NS:Print("  " .. L.SLASH_TOGGLE)
    NS:Print("  " .. L.SLASH_DEBUG)
    NS:Print("  " .. L.SLASH_MINIMAP)
    NS:Print("  " .. L.SLASH_OPTIONS)
    NS:Print("  /wcl export - Export your tasks")
    NS:Print("  /wcl import <paste> - Import tasks (omit <paste> to open a popup)")
  end
end
