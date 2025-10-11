--[[
  @file        WinterChecklist.lua
  @brief       Bootstrap, SavedVariables defaults, main frame, and cross-module glue.
  @addon       WinterChecklist
  @author      CTG + ChatGPT
  @notes       Keep this file skinny. UI specifics live in lua/*.lua modules.
]]

local ADDON, NS = ...
NS = NS or {}
_G[ADDON] = NS

-- Namespaces ------------------------------------------------------------------
NS.Util  = NS.Util  or {}      -- from lua/utils.lua
NS.Const = NS.Const or {}      -- constants collected here
local U, C = NS.Util, NS.Const

-- Flavor helpers
function NS.IsRetail()
  local v = (select(4, GetBuildInfo())) or 0
  return v >= 100000
end
function NS.IsClassic()
  return not NS.IsRetail()
end

-- Localization table (enUS sets NS.L; fallback to key if missing)
NS.L = NS.L or setmetatable({}, { __index = function(t, k) return k end })
local L = NS.L

-- SavedVariables container (declared in TOC via ## SavedVariables)
WinterChecklistDB = WinterChecklistDB or {}

-- Constants -------------------------------------------------------------------
C.FRAME_W_DEFAULT   = 420
C.FRAME_H_DEFAULT   = 320
C.HELP_BTN_W        = 24
C.HELP_BTN_H        = 20
C.TITLE_MARGIN_X    = 12
C.TITLE_MARGIN_Y    = -10
C.BACKDROP = {
  bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

-- LibSharedMedia --------------------------------------------------------------
local hasLSM, LSM = pcall(function() return LibStub("LibSharedMedia-3.0") end)
NS.Media = NS.Media or {}
local M = NS.Media
M.hasLSM = hasLSM and type(LSM) == "table"
M.LSM = M.hasLSM and LSM or nil

function M:GetSoundList()
  if not self.hasLSM then return {} end
  local list = self.LSM:List("sound") or {}
  table.sort(list)
  return list
end

function M:FetchSound(name)
  if not self.hasLSM or not name or name == "" then return nil end
  return self.LSM:Fetch("sound", name, true) -- allowDefault=true
end

function M:PlayTaskAdded()
  local ui = WinterChecklistDB.ui or {}
  if ui.soundOnAdd == false then return end
  local file = self:FetchSound(ui.soundName)
  if file then
    PlaySoundFile(file, "SFX")
  else
    -- Fallback to a Blizzard soundkit
    if PlaySound then PlaySound(SOUNDKIT and SOUNDKIT.READY_CHECK or 8959) end
  end
end

-- Defaults --------------------------------------------------------------------
local DEFAULTS = {
  debug = false,
  minimap = { hide = false },
  frame = {
    w = C.FRAME_W_DEFAULT, h = C.FRAME_H_DEFAULT,
    point = "CENTER", relPoint = "CENTER", x = 0, y = 0,
    shown = true,
  },
  ui = { locked = false, showHelp = true, soundOnAdd = true, soundName = "" },
  profile = { active = "Default" },
  chars = {}, -- populated in tasks.lua
}

-- Utilities -------------------------------------------------------------------
local function apply_defaults(dst, src)
  for k,v in pairs(src) do
    if type(v) == "table" then
      dst[k] = dst[k] or {}
      apply_defaults(dst[k], v)
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
end

local function restore_position(frame, conf)
  conf = conf or WinterChecklistDB.frame
  frame:ClearAllPoints()
  if conf and conf.point and conf.relPoint then
    frame:SetPoint(conf.point, UIParent, conf.relPoint, conf.x or 0, conf.y or 0)
  else
    frame:SetPoint("CENTER")
  end
end

local function store_position(frame, conf)
  conf = conf or WinterChecklistDB.frame
  local p, _, rp, x, y = frame:GetPoint(1)
  conf.point, conf.relPoint, conf.x, conf.y = p or "CENTER", rp or "CENTER", x or 0, y or 0
end

-- Logging
function NS:Print(msg)
  if msg == nil then return end
  DEFAULT_CHAT_FRAME:AddMessage(("|cff00ccff%s:|r %s"):format(ADDON, tostring(msg)))
end
function NS:DPrint(msg) if WinterChecklistDB and WinterChecklistDB.debug then NS:Print(msg) end end

-- Main Frame ------------------------------------------------------------------
local function CreateMainFrame()
  if NS.frame then return end
  local f = CreateFrame("Frame", ADDON.."MainFrame", UIParent, "BackdropTemplate")
  f:SetSize(WinterChecklistDB.frame.w, WinterChecklistDB.frame.h)
  f:SetBackdrop(C.BACKDROP)
  restore_position(f)

  -- Dragging (respects the 'locked' option)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self)
    if not WinterChecklistDB.ui.locked then self:StartMoving() end
  end)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    store_position(self)
  end)

  -- Title
  local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", C.TITLE_MARGIN_X, C.TITLE_MARGIN_Y)
  title:SetText(L.ADDON_NAME)

  -- Help button
  local helpBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  helpBtn:SetSize(C.HELP_BTN_W, C.HELP_BTN_H)
  helpBtn:SetPoint("TOPRIGHT", -8, -8)
  helpBtn:SetText("?")
  helpBtn:SetScript("OnClick", function() if NS.Help then NS.Help:Show(f) end end)
  f.helpBtn = helpBtn

  -- Body stub (placeholder for tasks UI later)
  local body = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  body:SetWidth(WinterChecklistDB.frame.w - 24)
  body:SetJustifyH("LEFT")
  body:SetText("|cffaaaaaa" .. L.TASKS_HEADER .. " — " .. L.HELP_SUMMARY_BODY .. "|r")

  -- Close
  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 0, 0)

  NS.frame = f
  if WinterChecklistDB.frame.shown then f:Show() else f:Hide() end
  NS:RefreshMainUIForOptions()
end

-- Apply UI prefs to the already-built main frame
function NS:RefreshMainUIForOptions()
  if not NS.frame then return end
  local locked   = WinterChecklistDB.ui and WinterChecklistDB.ui.locked
  local showHelp = WinterChecklistDB.ui and (WinterChecklistDB.ui.showHelp ~= false)
  NS.frame.helpBtn:SetShown(showHelp)
  NS.frame:SetAlpha(locked and 0.97 or 1.0)
end

function NS:ShowUI() if NS.frame then NS.frame:Show(); WinterChecklistDB.frame.shown = true end end
function NS:HideUI() if NS.frame then NS.frame:Hide(); WinterChecklistDB.frame.shown = false end end
function NS:ToggleUI() if NS.frame and NS.frame:IsShown() then NS:HideUI() else NS:ShowUI() end end

-- Minimap visibility helper used by options/minimap
function NS:ApplyMinimapVisibility()
  local ok, Icon = pcall(function() return LibStub("LibDBIcon-1.0") end)
  if ok and Icon and WinterChecklistDB.minimap then
    if WinterChecklistDB.minimap.hide then Icon:Hide("WinterChecklist")
    else Icon:Show("WinterChecklist") end
  end
end

-- Events ----------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON then
    apply_defaults(WinterChecklistDB, DEFAULTS)
    WinterChecklistDB.accountWide = WinterChecklistDB.accountWide or true -- default ON per user
  elseif event == "PLAYER_LOGIN" then
    CreateMainFrame()
    if NS.BootstrapUIList then NS.BootstrapUIList() end  -- attach the in-frame task list
    NS:ApplyMinimapVisibility()
  end
end)


-- Simple notify hook for task changes
function NS.NotifyTasksChanged(reason)
  if NS.Debug and type(NS.Debug) == "function" then NS:Debug("Tasks changed: "..(reason or "?")) end
  -- Future: dispatch to listeners if needed
end


-- DB defaults & migration
function NS.MigrateDB()
  WinterChecklistDB = WinterChecklistDB or {}
  WinterChecklistDB.version = WinterChecklistDB.version or 1
  WinterChecklistDB.chars = WinterChecklistDB.chars or {}
end

-- Enhance main frame behaviors (ESC close + clamp on drag stop)
function NS.EnhanceMainFrame()
  local f = NS.frame
  if not f then return end
  -- ESC to close without needing a global name
  f:EnableKeyboard(true)
  if f.SetPropagateKeyboardInput then
    f:SetPropagateKeyboardInput(true)  -- Retail; not present in Classic 1.15
  end
  f:HookScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then self:Hide() end
  end)
  -- Clamp to screen
  if f.SetClampedToScreen then f:SetClampedToScreen(true) end
  f:HookScript("OnDragStop", function(self)
    if NS.Util and NS.Util.ClampToScreen then NS.Util.ClampToScreen(self) end
  end)
end

-- Enhance minimap clicks
function NS.EnhanceMinimapButtonClicks()
  local btn = _G["LibDBIcon10_"..(ADDON or "WinterChecklist")]
  if not btn then return end
  btn:RegisterForClicks("AnyUp")
  btn:SetScript("OnClick", function(_, button)
    if button == "RightButton" then
      if NS.Options and NS.Options.Open then NS.Options:Open() end
    else
      if IsShiftKeyDown() then
        WinterChecklistDB.debug = not WinterChecklistDB.debug
        if NS.Print then NS:Print(WinterChecklistDB.debug and (NS.L.DEBUG_ENABLED or "Debug ON") or (NS.L.DEBUG_DISABLED or "Debug OFF")) end
      else
        if NS.ToggleUI then NS:ToggleUI() end
      end
    end
  end)
end


-- Milestone A UI: attach list controls
function NS.BootstrapUIList()
  if not NS.frame then return end
  if NS.UIList and NS.UIList.Init then NS.UIList:Init(NS.frame) end
end
