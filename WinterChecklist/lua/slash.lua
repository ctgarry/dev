--[[
  @file    lua/slash.lua
  @brief   /wcl commands to drive core actions.
]]
local _, NS = ...
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
    NS.ToggleMinimapIcon()
  elseif cmd == "options" or cmd == "opt" then
    if NS.Options and NS.Options.Open then
      NS.Options:Open()
    end
  elseif cmd == "export" then
    if NS.Tasks and NS.Tasks.Export then
      local payload = NS.Tasks:Export()
      if NS.Util and NS.Util.ShowTextPopup then
        NS.Util.ShowTextPopup(
          L.EXPORT_COPY_PROMPT or L.EXPORT_TITLE or "WinterChecklist - Export",
          payload,
          nil,
          { multiline = true, width = 440, height = 160, commitOnEnter = false }
        )
      else
        NS:Print(L.EXPORT_READY or "Export string ready. Copy from the popup.")
        print(payload)
      end
    end
  elseif cmd == "import" then
    local data = NS.Util and NS.Util.trim(rest or "") or (rest or "")
    if (not data or data == "") and NS.Util and NS.Util.ShowTextPopup then
      NS.Util.ShowTextPopup(
        L.IMPORT_PASTE_HERE or L.IMPORT_TITLE or "WinterChecklist - Paste Import",
        "",
        function(text)
          if text and text ~= "" and NS.Tasks and NS.Tasks.ImportWithPrompt then
            NS.Tasks:ImportWithPrompt(text)
          else
            if NS.Print and L.IMPORT_NO_DATA then
              NS:Print(L.IMPORT_NO_DATA)
            end
          end
        end,
        { multiline = true, width = 440, height = 160, commitOnEnter = false, button1 = L.IMPORT or "Import" }
      )
      NS:Print(L.IMPORT_INSTRUCTIONS or "Paste an export string into the popup and click Import.")
    elseif NS.Tasks and NS.Tasks.ImportWithPrompt then
      NS.Tasks:ImportWithPrompt(data)
    end
  elseif cmd == "account" or cmd == "shared" then
    if not NS.Profiles or not NS.Profiles.IsOptedIn or not NS.Profiles.SetOptIn then
      return
    end
    local arg = (rest or ""):lower()
    local current = NS.Profiles:IsOptedIn()
    local desired
    local showStatusOnly = false
    if arg == "on" or arg == "enable" or arg == "true" then
      desired = true
    elseif arg == "off" or arg == "disable" or arg == "false" then
      desired = false
    elseif arg == "status" or arg == "state" then
      desired = current
      showStatusOnly = true
    elseif arg == "toggle" or arg == "" then
      desired = not current
    else
      if NS.Print and L.SLASH_ACCOUNT_USAGE then
        NS:Print(L.SLASH_ACCOUNT_USAGE)
      elseif print and L.SLASH_ACCOUNT_USAGE then
        print(L.SLASH_ACCOUNT_USAGE)
      end
      return
    end

    local msg
    if showStatusOnly then
      msg = current and L.SHARED_STATUS_ON or L.SHARED_STATUS_OFF
    else
      NS.Profiles:SetOptIn(desired)
      local usingShared = NS.Profiles:IsOptedIn()
      if desired and not usingShared then
        msg = L.SHARED_STATUS_PENDING or L.SHARED_STATUS_OFF
      else
        msg = usingShared and L.SHARED_STATUS_ON or L.SHARED_STATUS_OFF
      end
    end
    if msg and NS.Print then
      NS:Print(msg)
    elseif msg and print then
      print(msg)
    end
  elseif cmd == "help" or cmd == "?" then
    if NS.Help then
      NS.Help:Show(NS.frame)
    end
  else
    NS:Print(L.SLASH_HEADER)
    NS:Print("  " .. L.SLASH_TOGGLE)
    NS:Print("  " .. L.SLASH_DEBUG)
    NS:Print("  " .. L.SLASH_MINIMAP)
    NS:Print("  " .. L.SLASH_OPTIONS)
    NS:Print("  " .. L.SLASH_ACCOUNT)
    NS:Print("  /wcl export - Export your tasks")
    NS:Print("  /wcl import <paste> - Import tasks (omit <paste> to open a popup)")
  end
end

