--[[
  @file    lua/minimap.lua
  @brief   LDB launcher + LibDBIcon minimap toggle.
  @deps    LibDataBroker-1.1, LibDBIcon-1.0 (bundled in lib/)
]]
local ADDON, NS = ...
local U = NS.Util
local L = NS.L

local hasLDB, LDB = pcall(function() return LibStub("LibDataBroker-1.1") end)

local ICON_PATH = "Interface\\AddOns\\WinterChecklist\\img\\minimap"
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_Snowball_10"

-- Helper to compute done/total for broker text
local function WCL_Counts()
  if not NS.Tasks or not NS.Tasks.GetAll then return 0, 0 end
  local total, done = 0, 0
  for _, row in ipairs(NS.Tasks:GetAll()) do
    total = total + 1
    if row.done then done = done + 1 end
  end
  return done, total
end

local hasLDB, LDB = pcall(function() return LibStub("LibDataBroker-1.1") end)
local hasIcon, Icon = pcall(function() return LibStub("LibDBIcon-1.0") end)

if hasLDB and hasIcon then
  local d, tt = WCL_Counts()
  local broker = LDB:NewDataObject(ADDON, {
    type  = "launcher",
    label = ADDON,
    text  = ("WCL %d/%d"):format(d, tt),
    icon  = ICON_PATH,
    OnClick = function(_, button)
      if button == "RightButton" then
        if NS.Options and NS.Options.Open then NS.Options:Open() end
      elseif IsShiftKeyDown() then
        WinterChecklistDB.debug = not WinterChecklistDB.debug
        if NS.Print then NS:Print(WinterChecklistDB.debug and (L.DEBUG_ENABLED or "Debug ON") or (L.DEBUG_DISABLED or "Debug OFF")) end
      else
        if NS.ToggleUI then NS:ToggleUI() end
      end
    end,
    OnTooltipShow = function(tt)
      tt:AddLine(ADDON)
      tt:AddLine(L.SLASH_TOGGLE or "/wcl - toggle", 1,1,1)
      tt:AddLine(L.SLASH_OPTIONS or "/wcl options - open Options", 1,1,1)
    end
  })

  -- Fallback icon if path is missing/invalid
  if not broker.icon or broker.icon == "" then
    broker.icon = FALLBACK_ICON
  end

  Icon:Register(ADDON, broker, WinterChecklistDB and WinterChecklistDB.minimap or { hide=false })
end

-- Allow UI to refresh the broker text after task changes
function NS.EnhanceMinimapText()
  if not hasLDB then return end
  local d, tt = WCL_Counts()
  local obj = LDB and LDB.GetDataObjectByName and LDB:GetDataObjectByName(ADDON)
  if obj then obj.text = ("WCL %d/%d"):format(d, tt) end
end

function NS:ToggleMinimapIcon()
  if not hasIcon then return end
  WinterChecklistDB.minimap = WinterChecklistDB.minimap or { hide=false }
  WinterChecklistDB.minimap.hide = not WinterChecklistDB.minimap.hide
  NS:ApplyMinimapVisibility()
end
