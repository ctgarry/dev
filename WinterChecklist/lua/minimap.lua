--[[
  @file    lua/minimap.lua
  @brief   LDB launcher + LibDBIcon minimap toggle.
  @deps    LibDataBroker-1.1, LibDBIcon-1.0 (bundled in lib/)
]]
local ADDON, NS = ...
local U = NS.Util
local L = NS.L

local hasLDB, LDB = pcall(function() return LibStub("LibDataBroker-1.1") end)
local hasIcon, Icon = pcall(function() return LibStub("LibDBIcon-1.0") end)

local ICON_PATH = "Interface\\AddOns\\WinterChecklist\\img\\minimap"
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_Snowball_10"

if hasLDB and hasIcon then
  local broker = LDB:NewDataObject(ADDON, {
    type = "launcher",
    text = ADDON,
    icon = ICON_PATH,
    OnClick = function(_, button)
      if button == "LeftButton" then
        NS:ToggleUI()
      else
        if NS.Options and NS.Options.Open then NS.Options:Open() end
      end
    end,
    OnTooltipShow = function(tt)
      tt:AddLine(ADDON)
      tt:AddLine(L.SLASH_TOGGLE, 1,1,1)
      tt:AddLine(L.SLASH_OPTIONS, 1,1,1)
    end
  })
  -- Use fallback icon if custom path missing
  local iconFile = broker.icon
  if not iconFile or not C_Texture.GetAtlasInfo(iconFile) then
    broker.icon = FALLBACK_ICON
  end
  Icon:Register(ADDON, broker, WinterChecklistDB and WinterChecklistDB.minimap or { hide=false })
end

function NS:ToggleMinimapIcon()
  if not hasIcon then return end
  WinterChecklistDB.minimap = WinterChecklistDB.minimap or { hide=false }
  WinterChecklistDB.minimap.hide = not WinterChecklistDB.minimap.hide
  NS:ApplyMinimapVisibility()
end
