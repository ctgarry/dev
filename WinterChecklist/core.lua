-- core.lua
-- Purpose: Bootstrap WinterChecklist, wire slash commands, and handle world/zone/login/logout events.
-- Scope: No UI layout here; just init, persistence, and user commands. Strict localization (no fallbacks).

local ADDON, NS = ...

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

-- Single init entry point (called after PLAYER_LOGIN)
NS.OnReady = NS.OnReady or function()
  local db = NS.EnsureDB()  -- storage.lua handles defaults + migrations

  -- Build main UI (namespaced to avoid global leaks)
  local mainFrame = nil
  if NS.CreateMainFrame      then mainFrame = NS.CreateMainFrame(db) end
  if mainFrame then NS.UI.frame = mainFrame end
  if NS.CreateMinimapButton  then NS.CreateMinimapButton(db)  end
  if NS.CreateOptionsPanel   then NS.CreateOptionsPanel(db)   end
  if NS.UpdateZoneText       then NS.UpdateZoneText()         end

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
    if NS.UpdateZoneText then NS.UpdateZoneText() end
  elseif event == "PLAYER_LOGOUT" then
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
  end
end)
