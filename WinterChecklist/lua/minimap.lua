-- minimap.lua
-- Minimap launcher & toggling for WinterChecklist (LibDataBroker + LibDBIcon)

local ADDON_NAME, NS = ...
NS = NS or _G[ADDON_NAME] or {}
_G[ADDON_NAME] = NS

local U = NS.Util

-- Safe LibStub lookups
local hasLDB, LDB = pcall(function() return LibStub("LibDataBroker-1.1") end)
local hasIcon, Icon = pcall(function() return LibStub("LibDBIcon-1.0") end)

local ldbObject

local MINIMAP_DEFAULTS = { hide = false }

local function ensure_minimap_defaults()
  WinterChecklistDB = WinterChecklistDB or {}
  WinterChecklistDB.minimap = U.copy_missing(WinterChecklistDB.minimap, MINIMAP_DEFAULTS)
end

local function setup_minimap()
  if not hasLDB or not hasIcon then
    if not hasLDB then U.debug("LibDataBroker-1.1 missing; minimap launcher disabled.") end
    if not hasIcon then U.debug("LibDBIcon-1.0 missing; minimap icon disabled.") end
    return
  end
  if ldbObject then return end

  ldbObject = LDB:NewDataObject("WinterChecklist", {
    type = "launcher",
    icon = "Interface\\AddOns\\WinterChecklist\\img\\minimap",
    label = "WinterChecklist",
    OnClick = function(_, button)
      if button == "LeftButton" then NS:ToggleUI()
      elseif button == "RightButton" then NS:ToggleDebug() end
    end,
    OnTooltipShow = function(tt)
      tt:AddLine("WinterChecklist")
      tt:AddLine("|cffaaaaaaLeft-click|r toggle UI", 1,1,1)
      tt:AddLine("|cffaaaaaaRight-click|r toggle debug", 1,1,1)
    end,
  })

  Icon:Register("WinterChecklist", ldbObject, WinterChecklistDB.minimap)
  if WinterChecklistDB.minimap.hide then
    Icon:Hide("WinterChecklist")
  else
    Icon:Show("WinterChecklist")
  end
end

function NS:ToggleMinimap()
  if not hasIcon then
    self:Print("LibDBIcon not found; minimap toggle not available.")
    return
  end
  ensure_minimap_defaults()
  WinterChecklistDB.minimap.hide = not WinterChecklistDB.minimap.hide
  if WinterChecklistDB.minimap.hide then
    Icon:Hide("WinterChecklist")
    self:Print("Minimap icon hidden.")
  else
    Icon:Show("WinterChecklist")
    self:Print("Minimap icon shown.")
  end
end

-- Register events to init the minimap after defaults are applied by the core file
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
    ensure_minimap_defaults()
    setup_minimap()
  elseif event == "PLAYER_LOGIN" then
    -- Reapply visibility to be safe
    if hasIcon then
      if WinterChecklistDB.minimap.hide then Icon:Hide("WinterChecklist") else Icon:Show("WinterChecklist") end
    end
  end
end)

-- NOTE: Do NOT reassign NS.ToggleMinimap here; it is already a method.
