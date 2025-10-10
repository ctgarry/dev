-- core.lua
-- Purpose: Bootstrap WinterChecklist, wire slash commands, and handle world/zone/login/logout events.
-- Scope: No UI layout here; just init, persistence, and user commands. Strict localization (no fallbacks).

local ADDON_NAME, NS = ...
NS.name = ADDON_NAME

NS.DB = NS.DB or {}
NS.UI = NS.UI or {}
NS.UI.controls = NS.UI.controls or {}

-- tiny logger
function NS.Debug(...)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff7fdfff[WinterChecklist]|r "..table.concat({tostringall(...)}, " ")) end
end

-- ===== Constants (avoid magic numbers) =====
local DEFAULT_WIDTH  = 460
local DEFAULT_HEIGHT = 500
local DEFAULT_X      = 0
local DEFAULT_Y      = 0

-- ===== Strict localization helper (prefer shared NS.T) =====
local T = NS.T or (function(key)
  local L = NS.L or {}
  assert(L[key], "Missing locale key: " .. tostring(key))
  return L[key]
end)

-- Root namespace UI holder (avoid global UI leaks)
NS.UI = NS.UI or {}

-- ===== Root event frame (SavedVariables + OnReady) =====
local f = CreateFrame("Frame")
NS.frame = f

-- --- NEW: safe wrapper so we never touch UI before it's built
local function SafeUpdateZoneText()
  if NS.UpdateZoneText and NS.UI and NS.UI.frame and NS.UI.frame:IsShown() ~= nil then
    NS.UpdateZoneText()
  end
end

-- Single init entry point (called after PLAYER_LOGIN)
NS.OnReady = NS.OnReady or function()
  local db = NS.EnsureDB()  -- storage.lua handles defaults + migrations

  -- Build main UI (namespaced to avoid global leaks)
  local mainFrame = nil
  if NS.CreateMainFrame      then mainFrame = NS.CreateMainFrame() end
  if mainFrame then NS.UI.frame = mainFrame end
  if NS.Minimap and NS.Minimap.Boot then NS.Minimap.Boot(db) end
  -- --- CHANGED: don't call UpdateZoneText here; let events handle it after world is ready

  -- Restore position/size/visibility (UI does its own clamping)
  local UIf = NS.UI and NS.UI.frame
  if UIf and db.window then
    UIf:ClearAllPoints()
    UIf:SetPoint("CENTER", UIParent, "CENTER", db.window.x or DEFAULT_X, db.window.y or DEFAULT_Y)
    UIf:SetSize(db.window.w or DEFAULT_WIDTH, db.window.h or DEFAULT_HEIGHT)
    if db.window.shown == false then UIf:Hide() else UIf:Show() end
  end

  if NS.RefreshUI           then NS.RefreshUI()           end
  if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end

  -- --- NEW: do a micro-defer to update zone text once UI is definitely alive
  if C_Timer and C_Timer.After then
    C_Timer.After(0, SafeUpdateZoneText)
  else
    SafeUpdateZoneText()
  end
end

-- ===== Early events (addon load / login) =====
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON then
    -- No direct DB writes here; storage.lua's EnsureDB() is the single source of truth.
    -- (Keeps defaults/migrations centralized; avoids drift.)
  elseif event == "PLAYER_LOGIN" then
    if NS.OnReady then NS.OnReady() end
  end
end)

-- Public API table (optional expansion point)
NS.API = NS.API or {}

-- =====================================================================
-- Slash commands
-- =====================================================================
SLASH_WINTERCHECKLIST1 = "/wcl"
SLASH_WINTERCHECKLIST2 = "/checklist"
SlashCmdList["WINTERCHECKLIST"] = function(msg)
  local db  = NS.EnsureDB()
  msg       = NS.STrim(msg or "")

  local UIf = NS.UI and NS.UI.frame

  -- Toggle window
  if msg == "" or msg == "toggle" then
    if UIf then
      UIf:SetShown(not UIf:IsShown())
      db.window = db.window or { w = DEFAULT_WIDTH, h = DEFAULT_HEIGHT, x = DEFAULT_X, y = DEFAULT_Y, shown = true }
      db.window.shown = UIf:IsShown()
    end
    if NS.RefreshUI           then NS.RefreshUI()           end
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
    SafeUpdateZoneText()

  -- Add daily
  elseif msg:sub(1, 4) == "add " then
    local text = NS.STrim(msg:sub(5))
    if NS.IsEmpty(text) then
      NS.Print(T("CMD_CANNOT_ADD_BLANK"))
    else
      table.insert(db.tasks, { text = text, frequency = "daily",  completed = false })
      if NS.RefreshUI           then NS.RefreshUI()           end
      if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
      NS.Print(T("CMD_ADDED_DAILY"))
    end

  -- Add weekly
  elseif msg:sub(1, 5) == "addw " then
    local text = NS.STrim(msg:sub(6))
    if NS.IsEmpty(text) then
      NS.Print(T("CMD_CANNOT_ADD_BLANK"))
    else
      table.insert(db.tasks, { text = text, frequency = "weekly", completed = false })
      if NS.RefreshUI           then NS.RefreshUI()           end
      if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
      NS.Print(T("CMD_ADDED_WEEKLY"))
    end

  -- Minimap toggle
  elseif msg == "minimap" then
    db.showMinimap = not (db.showMinimap == false)
    if NS.UpdateMinimapVisibility then NS.UpdateMinimapVisibility(db) end
    NS.Print((db.showMinimap == false) and T("CMD_MINIMAP_HIDDEN") or T("CMD_MINIMAP_SHOWN"))

  -- Help popup (keeps text inside UI)
  elseif msg == "help" then
    if NS.ToggleHelp then NS.ToggleHelp(UIf or UIParent) end

  -- Resets
  elseif msg == "reset" or msg == "reset all" then
    if NS.ResetTasks then NS.ResetTasks("all") end
    NS.Print(T("CMD_RESET_ALL"))

  elseif msg == "reset daily" then
    if NS.ResetTasks then NS.ResetTasks("daily") end
    NS.Print(T("CMD_RESET_DAILY"))

  elseif msg == "reset weekly" then
    if NS.ResetTasks then NS.ResetTasks("weekly") end
    NS.Print(T("CMD_RESET_WEEKLY"))

  -- Frame fix
  elseif msg == "fixframe" or msg == "resetframe" then
    db.window = { w = DEFAULT_WIDTH, h = DEFAULT_HEIGHT, x = DEFAULT_X, y = DEFAULT_Y, shown = true }
    if UIf then
      UIf:ClearAllPoints()
      UIf:SetPoint("CENTER", UIParent, "CENTER", DEFAULT_X, DEFAULT_Y)
      UIf:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT)
      UIf:Show()
    end
    NS.Print(T("CMD_FRAME_RESET"))
    if NS.RefreshUI           then NS.RefreshUI()           end
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
    SafeUpdateZoneText()

  -- Fallback to help string
  else
    NS.Print(T("CMD_HELP"))
  end
end

-- =====================================================================
-- World/zone and logout events
-- =====================================================================
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("ZONE_CHANGED")
ev:RegisterEvent("ZONE_CHANGED_INDOORS")
ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ev:RegisterEvent("PLAYER_LOGOUT")
ev:SetScript("OnEvent", function(_, event)
  if (event == "PLAYER_ENTERING_WORLD"
      or event == "ZONE_CHANGED"
      or event == "ZONE_CHANGED_INDOORS"
      or event == "ZONE_CHANGED_NEW_AREA") then
    SafeUpdateZoneText()
  elseif event == "PLAYER_LOGOUT" then
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
  end
end)



-- WinterChecklist 1.5 (Classic Era) — init.lua
local ADDON_NAME = ...
local ADDON = _G[ADDON_NAME] or {}
_G[ADDON_NAME] = ADDON

-- SavedVariables bootstrap
WinterChecklistDB = WinterChecklistDB or {}
local DB = WinterChecklistDB
DB.version = DB.version or 1
if DB.locked == nil then DB.locked = false end
DB.pos = DB.pos or { point="CENTER", rel="UIParent", relPoint="CENTER", x=0, y=0 }
DB.minimap = DB.minimap or { hide=false, angle=225 }

-- Namespace modules
ADDON.UI = ADDON.UI or {}
ADDON.Minimap = ADDON.Minimap or {}

StaticPopupDialogs = StaticPopupDialogs or {}

-- Chat tag helper
local function tag(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffWinterChecklist|r: "..tostring(msg)) end
ADDON.Tag = tag

-- Lock helpers
local function applyLock()
    if ADDON.UI and ADDON.UI.MainFrame and ADDON.UI.MainFrame.ApplyLock then
        ADDON.UI.MainFrame.ApplyLock(DB.locked)
    end
end

local function lockCmd(state)
    if state == "toggle" then DB.locked = not DB.locked
    elseif state == "on" or state == "lock" then DB.locked = true
    elseif state == "off" or state == "unlock" then DB.locked = false
    end
    applyLock()
    tag("Anchor "..(DB.locked and "|cffff5555Locked|r" or "|cff55ff55Unlocked|r"))
end
ADDON.LockCmd = lockCmd

SLASH_WINTERCHECKLIST1 = "/wcl"

SlashCmdList["WINTERCHECKLIST"] = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$","")
  if msg == "lock" then
    if NS.SetLocked then NS.SetLocked(true) end
  elseif msg == "unlock" then
    if NS.SetLocked then NS.SetLocked(false) end
  elseif msg == "toggle" or msg == "" then
    if NS.ToggleMain then NS.ToggleMain() end
  elseif msg == "minimap" then
    if NS.ToggleMinimap then NS.ToggleMinimap() end
  elseif msg == "import" then
    if NS.ShowImport then NS.ShowImport(_G.WC_Main) end
  elseif msg == "export" then
    if NS.ShowExport then NS.ShowExport(_G.WC_Main) end
  elseif msg == "help" then
    if NS.ShowHelp then NS.ShowHelp(_G.WC_Main) end
  else
    if NS.Print then NS.Print("Usage: /wcl [toggle|lock|unlock|minimap|import|export|help]") end
  end
end


-- Event bootstrap — defer UI creation to after login
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    if ADDON.UI and ADDON.UI.CreateMainFrame then
        ADDON.UI.CreateMainFrame(DB)
        applyLock()
    end
    if ADDON.Minimap and ADDON.Minimap.Boot then
        ADDON.Minimap.Boot(DB)
    end
    tag("loaded (v1.5.0)")
end)

-- WC_ROW_LAYOUT_HELPER
function NS._ApplyRowLayout(row, checkbox, text, editBtn, deleteBtn)
  if not (row and checkbox and text and deleteBtn and editBtn) then return end
  deleteBtn:ClearAllPoints(); deleteBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
  editBtn:ClearAllPoints();   editBtn:SetPoint("RIGHT", deleteBtn, "LEFT", -6, 0)
  text:ClearAllPoints()
  text:SetPoint("LEFT", checkbox, "RIGHT", 6, 0)
  text:SetPoint("RIGHT", editBtn, "LEFT", -6, 0)
  if text.SetJustifyH then text:SetJustifyH("LEFT") end
  if text.SetWordWrap then text:SetWordWrap(false) end
  if text.SetMaxLines then text:SetMaxLines(1) end
  if row.SetResizeBounds then row:SetResizeBounds(300, 18) end
end

-- WC_SLASH_COMMANDS
SLASH_WINTERCHECKLIST1 = "/wc"
SLASH_WINTERCHECKLIST2 = "/winterchecklist"
SlashCmdList["WINTERCHECKLIST"] = function(msg)
  msg = (msg or ""):lower()
  if msg == "help" or msg == "?" then if NS.ShowHelp then NS.ShowHelp() end
  elseif msg == "import" then if NS.ShowImport then NS.ShowImport() end
  elseif msg == "export" then if NS.ShowExport then NS.ShowExport() end
  elseif msg == "reset"  then StaticPopup_Show("WINTERCHECKLIST_CONFIRM_RESET")
  else if NS.ToggleMain then NS.ToggleMain() end end
end

-- WC_MOUSE_DIM
if frame and not frame._wcDimHooked then
  frame._wcDimHooked = true
  frame:SetScript("OnUpdate", function(self)
    local over = MouseIsOver(self)
    local target = over and 1 or 0.5
    if math.abs((self._alpha or 1) - target) > 0.02 then
      self._alpha = target
      self:SetAlpha(target)
      if target < 1 then
        if _G.importPopup then _G.importPopup:Hide() end
        if _G.exportPopup then _G.exportPopup:Hide() end
        if _G.helpFrame   then _G.helpFrame:Hide()   end
      end
    end
  end)
end

-- WC_COMBAT_TOGGLE
do
  local function WC_CombatToggle(ev)
    if not frame then return end
    if ev == "PLAYER_REGEN_DISABLED" then frame:Hide() else frame:Show() end
  end
  local _f = CreateFrame("Frame")
  _f:RegisterEvent("PLAYER_REGEN_DISABLED")
  _f:RegisterEvent("PLAYER_REGEN_ENABLED")
  _f:SetScript("OnEvent", function(_, ev) WC_CombatToggle(ev) end)
end

-- WC_BUMP_FOR_BLIZZ_WINDOWS
do
  local bump, saved = 260, nil
  local watch = { MailFrame, QuestFrame, CharacterFrame, FriendsFrame, SpellBookFrame, PVEFrame }
  for _,wf in ipairs(watch) do
    if wf and wf.HookScript then
      wf:HookScript("OnShow", function()
        if frame and frame:IsShown() and not saved then
          saved = { frame:GetPoint(1) }
          frame:ClearAllPoints()
          frame:SetPoint(saved[1], saved[2], saved[3], (saved[4] or 0)+bump, saved[5] or 0)
        end
      end)
      wf:HookScript("OnHide", function()
        if frame and saved then
          frame:ClearAllPoints()
          frame:SetPoint(unpack(saved))
          saved = nil
        end
      end)
    end
  end
end

-- WC_FRAME_MIN_BOUNDS
if frame and (frame.SetResizeBounds or frame.SetMinResize) then
  if frame.SetResizeBounds then frame:SetResizeBounds(360, 300) else
    if frame.SetMinResize then frame:SetMinResize(360, 300) end
  end
end