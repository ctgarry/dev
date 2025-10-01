-- compat.lua
-- Purpose: Central Retail/Classic shims (project detection, options panel wiring, minimap button, safe wrappers).
-- Scope: Compatibility only — no UI layout or business logic. Keep tiny & dependency-free.
-- Notes: All user-facing strings must go through T(KEY). Prefer presence checks over brittle version compares.

local ADDON, NS = ...

-- ===== Constants (avoid magic numbers) =====
local C = {
  -- Minimap fallback geometry (when LibDBIcon isn't available)
  MINIMAP_BTN_SIZE   = 31,
  MINIMAP_RING_SIZE  = 54,
  MINIMAP_ICON_SIZE  = 18,
  MINIMAP_ICON_X     = 0,
  MINIMAP_ICON_Y     = 0,
  MINIMAP_LEVEL      = 8,
  MINIMAP_STRATA     = "MEDIUM",
}

-- ===== Strict localization helper (assert on missing) =====
local function T(key)
  local L = NS.L or {}
  assert(L[key], "Missing locale key: " .. tostring(key))
  return L[key]
end

-- ===== Localize hot globals =====
local _G              = _G
local UIParent        = UIParent
local CreateFrame     = CreateFrame

-- ====================================================================
-- Project detection (Retail vs Classic family)
-- ====================================================================
local PID          = _G.WOW_PROJECT_ID
local P_MAINLINE   = _G.WOW_PROJECT_MAINLINE
local P_CLASSIC    = _G.WOW_PROJECT_CLASSIC

local function _isMainline()
  if PID and P_MAINLINE then return PID == P_MAINLINE end
  -- Heuristic fallback: Retail has the Settings API
  return type(_G.Settings) == "table" and type(_G.Settings.OpenToCategory) == "function"
end

local function _isClassicAny()
  if PID and P_MAINLINE then return PID ~= P_MAINLINE end
  return not _isMainline()
end

local function _isClassicEra()
  if PID and P_CLASSIC then return PID == P_CLASSIC end
  -- When unsure, treat non-Retail as Classic family
  return _isClassicAny()
end

function NS.IsRetail()       return _isMainline()   end
function NS.IsMainline()     return _isMainline()   end
function NS.IsClassicAny()   return _isClassicAny() end
function NS.IsClassicEra()   return _isClassicEra() end

function NS.GameProject()
  if NS.IsRetail()     then return "Mainline" end
  if NS.IsClassicEra() then return "ClassicEra" end
  return "ClassicFamily"
end

-- ====================================================================
-- Options panel helpers (Retail Settings API vs Classic InterfaceOptions)
-- ====================================================================
local hasSettings = type(_G.Settings) == "table"

-- Create/register an options category from a frame factory (returns a token)
function NS.CreateOptionsCategory(name, factory)
  assert(type(name) == "string" and name ~= "", "Options category requires a non-empty name")
  assert(type(factory) == "function", "Options category requires a frame factory function")

  if hasSettings and type(Settings.RegisterCanvasLayoutCategory) == "function" then
    -- Retail
    local panel = factory(UIParent)
    panel.name = name
    local cat = Settings.RegisterCanvasLayoutCategory(panel, name)
    Settings.RegisterAddOnCategory(cat)
    return cat
  else
    -- Classic family
    local container = _G.InterfaceOptionsFramePanelContainer or UIParent
    local panel = factory(container)
    panel.name = name
    if type(_G.InterfaceOptions_AddCategory) == "function" then
      InterfaceOptions_AddCategory(panel)
    end
    return panel  -- acts as the "category" token on Classic
  end
end

-- Open a previously registered options category
function NS.OpenOptions(category)
  if not category then return end
  if hasSettings and type(Settings.OpenToCategory) == "function" then
    Settings.OpenToCategory(category)
  else
    -- Classic sometimes needs two calls to focus the panel
    if type(_G.InterfaceOptionsFrame_OpenToCategory) == "function" then
      InterfaceOptionsFrame_OpenToCategory(category)
      InterfaceOptionsFrame_OpenToCategory(category)
    end
  end
end

-- ====================================================================
-- World map opener (UI files call this — keep compat here)
-- ====================================================================
function NS.OpenWorldMap()
  -- Retail & modern Classic have WorldMapFrame; older builds use ToggleWorldMap
  if _G.WorldMapFrame and _G.WorldMapFrame:IsShown() ~= nil then
    _G.WorldMapFrame:Show()
    return
  end
  if type(_G.ToggleWorldMap) == "function" then
    ToggleWorldMap()
  end
end

-- ====================================================================
-- AddOn loaded checks (Retail moved to C_AddOns)
-- ====================================================================
local hasCAddOns = type(_G.C_AddOns) == "table"
function NS.IsAddOnLoaded(name)
  if hasCAddOns and type(C_AddOns.IsAddOnLoaded) == "function" then
    return C_AddOns.IsAddOnLoaded(name)
  elseif type(_G.IsAddOnLoaded) == "function" then
    return _G.IsAddOnLoaded(name)
  end
  return false
end

-- ====================================================================
-- Minimap button helper
--   Prefers LibDataBroker + LibDBIcon; falls back to a simple minimap button.
--   db.showMinimap (bool) remains the single toggle exposed to the rest of the addon.
-- ====================================================================
-- opts: { icon=path, label=string (localized), onClick=function(btn, button) }
function NS.TryCreateMinimapButton(db, opts)
  opts = opts or {}
  db   = db or {}
  db.minimap = db.minimap or { hide = (db.showMinimap == false) } -- bridge for LibDBIcon

  -- Prefer LibDataBroker + LibDBIcon when available
  local LDB = _G.LibStub and _G.LibStub:GetLibrary("LibDataBroker-1.1", true)
  local LDI = _G.LibStub and _G.LibStub:GetLibrary("LibDBIcon-1.0", true)
  if LDB and LDI then
    if not NS._ldbObj then
      NS._ldbObj = LDB:NewDataObject(opts.label or T("TITLE"), {
        type  = "launcher",
        icon  = opts.icon or "Interface\\ICONS\\INV_Misc_Note_01",
        OnClick = function(btn, button)
          if type(opts.onClick) == "function" then
            opts.onClick(btn, button)
          elseif _G.SlashCmdList and _G.SlashCmdList.WINTERCHECKLIST then
            _G.SlashCmdList.WINTERCHECKLIST("")
          end
        end,
        OnTooltipShow = function(tt)
          tt:AddLine(opts.label or T("TITLE"))
          tt:AddLine(T("TIP_MINIMAP_TOGGLE"), 1, 1, 1)
        end,
      })
    end
    if not LDI:IsRegistered("WinterChecklist") then
      LDI:Register("WinterChecklist", NS._ldbObj, db.minimap)
    end
    if db.showMinimap == false then LDI:Hide("WinterChecklist") else LDI:Show("WinterChecklist") end
    return
  end

  -- Fallback: simple minimap button (no external libraries)
  if not NS._mini and _G.Minimap then
    local f = CreateFrame("Button", "WinterChecklist_MinimapButton", _G.Minimap)
    f:SetSize(C.MINIMAP_BTN_SIZE, C.MINIMAP_BTN_SIZE)
    f:SetFrameStrata(C.MINIMAP_STRATA)
    f:SetFrameLevel(C.MINIMAP_LEVEL)
    f:SetPoint("TOPLEFT", _G.Minimap, "TOPLEFT", 0, 0)

    local ring = f:CreateTexture(nil, "OVERLAY")
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    ring:SetSize(C.MINIMAP_RING_SIZE, C.MINIMAP_RING_SIZE)
    ring:SetPoint("TOPLEFT", 0, 0)

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(opts.icon or "Interface\\Buttons\\UI-CheckBox-Check")
    icon:SetSize(C.MINIMAP_ICON_SIZE, C.MINIMAP_ICON_SIZE)
    icon:SetPoint("CENTER", C.MINIMAP_ICON_X, C.MINIMAP_ICON_Y)
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    f:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

    f:SetScript("OnClick", function(btn, button)
      if type(opts.onClick) == "function" then
        opts.onClick(btn, button)
      elseif _G.SlashCmdList and _G.SlashCmdList.WINTERCHECKLIST then
        _G.SlashCmdList.WINTERCHECKLIST("")
      end
    end)

    f:SetScript("OnEnter", function(self)
      if _G.GameTooltip then
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText(T("TITLE"), 1, 1, 1)
        GameTooltip:AddLine(T("TIP_MINIMAP_TOGGLE"), .9, .9, .9)
        GameTooltip:Show()
      end
    end)
    f:SetScript("OnLeave", function() if _G.GameTooltip then GameTooltip:Hide() end end)

    -- Simple drag fallback (not a ring anchor)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)

    f:Show()
    NS._mini = f
  end

  if NS._mini then
    if db.showMinimap == false then NS._mini:Hide() else NS._mini:Show() end
  end
end

-- Keep LibDBIcon/Minimap visibility in sync with our single flag
function NS.UpdateMinimapVisibility(db)
  db = db or {}
  local LDI = _G.LibStub and _G.LibStub:GetLibrary("LibDBIcon-1.0", true)
  if LDI then
    if db.showMinimap == false then LDI:Hide("WinterChecklist") else LDI:Show("WinterChecklist") end
  elseif NS._mini then
    NS._mini:SetShown(db.showMinimap ~= false)
  end
end

-- ====================================================================
-- Small safe wrappers
-- ====================================================================

-- Frame:RegisterEvent guard (ignore nil names)
function NS.SafeRegisterEvent(frame, event)
  if frame and event and type(frame.RegisterEvent) == "function" then
    frame:RegisterEvent(event)
  end
end

-- Create a FontString with safe defaults (Classic often needs explicit template)
function NS.SafeCreateFS(parent, layer, template)
  layer    = layer or "OVERLAY"
  template = template or "GameFontNormal"
  return parent:CreateFontString(nil, layer, template)
end
