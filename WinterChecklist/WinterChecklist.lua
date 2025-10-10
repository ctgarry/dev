-- WinterChecklist.lua
-- Main addon file. Initializes SavedVariables, UI, and integrates Utils.

local ADDON_NAME, NS = ...
NS = NS or _G[ADDON_NAME] or {}
_G[ADDON_NAME] = NS

-- Utilities (must be loaded before this in .toc)
local U = NS.Util

-- SavedVariables declared in .toc as: ## SavedVariables: WinterChecklistDB
WinterChecklistDB = WinterChecklistDB or {}

-- ---------- Defaults & state ----------
local DEFAULTS = {
  debug = false,
  minimap = { hide = false }, -- minimap module will ensure/extend this too
  frame = { x = 400, y = 300, w = 420, h = 300, shown = true },
  profile = { active = "Default" },
}

local function apply_defaults()
  U.copy_missing(WinterChecklistDB, DEFAULTS)
  -- ensure nested defaults exist
  U.copy_missing(WinterChecklistDB.minimap, DEFAULTS.minimap)
  U.copy_missing(WinterChecklistDB.frame,   DEFAULTS.frame)
  U.copy_missing(WinterChecklistDB.profile, DEFAULTS.profile)
end

-- ---------- Printing helpers ----------
function NS:Print(msg) U.print(msg) end
function NS:Debug(fmt, ...) U.debug(fmt, ...) end

-- ---------- Simple UI frame ----------
local UI = {}
NS.UI = UI

local function ensure_frame()
  if UI.frame then return UI.frame end

  local f = CreateFrame("Frame", "WinterChecklistFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local x, y = self:GetCenter()
    WinterChecklistDB.frame.x, WinterChecklistDB.frame.y = x, y
  end)

  local w, h = WinterChecklistDB.frame.w, WinterChecklistDB.frame.h
  f:SetSize(w, h)

  -- Backdrop
  if f.SetBackdrop then
    f:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    f:SetBackdropColor(0,0,0,0.7)
  end

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  title:SetPoint("TOPLEFT", 12, -10)
  title:SetText("|cff33ff99WinterChecklist|r")

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 2, 1)

  -- Sample content
  local body = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  body:SetPoint("TOPLEFT", 16, -36)
  body:SetJustifyH("LEFT")
  body:SetJustifyV("TOP")
  body:SetText("Welcome! Stub UI — populate with zone-aware tasks, import/export, profiles, etc.")

  UI.frame = f
  return f
end

function NS:ShowUI()
  local f = ensure_frame()
  local x, y = WinterChecklistDB.frame.x, WinterChecklistDB.frame.y
  local w, h = WinterChecklistDB.frame.w, WinterChecklistDB.frame.h
  f:SetSize(w, h)
  f:ClearAllPoints()
  if x and y then
    f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
  else
    f:SetPoint("CENTER")
  end
  f:Show()
  WinterChecklistDB.frame.shown = true
end

function NS:HideUI()
  if UI.frame then UI.frame:Hide() end
  WinterChecklistDB.frame.shown = false
end

function NS:ToggleUI()
  if UI.frame and UI.frame:IsShown() then self:HideUI() else self:ShowUI() end
end

function NS:ToggleDebug()
  WinterChecklistDB.debug = not WinterChecklistDB.debug
  self:Print("Debug " .. (WinterChecklistDB.debug and "enabled" or "disabled") .. ".")
end

-- ---------- Events ----------
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
    apply_defaults()
    -- minimap setup now happens in minimap.lua
  elseif event == "PLAYER_LOGIN" then
    if WinterChecklistDB.frame.shown then NS:ShowUI() end
  end
end)

-- NOTE: Do NOT reassign NS.ToggleUI/ToggleDebug here; they are already methods.
