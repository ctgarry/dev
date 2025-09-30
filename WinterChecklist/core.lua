-- core.lua
local ADDON, NS = ...

-- Root event frame (loads SavedVariables and triggers OnReady)
local f = CreateFrame("Frame")
NS.frame = f

-- Let other files call this; keep it the single init path
NS.OnReady = NS.OnReady or function()
  local db = NS.EnsureDB()

  -- Build main UI once (namespaced to avoid global leaks)
  if NS.CreateMainFrame then NS.CreateMainFrame(db) end

  -- Optional UI helpers exported from ui.lua
  if NS.CreateMinimapButton then NS.CreateMinimapButton(db) end
  if NS.CreateOptionsPanel then NS.CreateOptionsPanel(db) end
  if NS.UpdateZoneText then NS.UpdateZoneText() end

  -- Restore position/size/visibility (no PAD clamp here; UI can clamp)
  if UI and UI.frame and db.window then
    UI.frame:ClearAllPoints()
    UI.frame:SetPoint("CENTER", UIParent, "CENTER", db.window.x or 0, db.window.y or 0)

    local w = db.window.w or 460
    local h = db.window.h or 500
    UI.frame:SetSize(w, h)

    if db.window.shown == false then UI.frame:Hide() else UI.frame:Show() end
  end

  if NS.RefreshUI then NS.RefreshUI() end
  if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
end

-- Early events
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON then
    -- Ensure SavedVariables exist
    WinterChecklistDB = WinterChecklistDB or { tasks = {}, opts = {} }

  elseif event == "PLAYER_LOGIN" then
    if NS.OnReady then NS.OnReady() end
  end
end)

-- Public API table (optional)
NS.API = {}

----------------------------------------------------------------------
-- Slash commands
----------------------------------------------------------------------
SLASH_WINTERCHECKLIST1 = "/wcl"
SLASH_WINTERCHECKLIST2 = "/checklist"
SlashCmdList["WINTERCHECKLIST"] = function(msg)
  local db = NS.EnsureDB()
  msg = NS.STrim(msg or "")

  if msg == "" or msg == "toggle" then
    if UI and UI.frame then
      UI.frame:SetShown(not UI.frame:IsShown())
      db.window = db.window or { w = 460, h = 500, x = 0, y = 0, shown = true }
      db.window.shown = UI.frame:IsShown()
    end
    if NS.RefreshUI then NS.RefreshUI() end
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end

  elseif msg:sub(1, 4) == "add " then
    local text = NS.STrim(msg:sub(5))
    if NS.IsEmpty(text) then
      NS.Print("Cannot add a blank task.")
    else
      table.insert(db.tasks, { text = text, frequency = "daily",  completed = false })
      if NS.RefreshUI then NS.RefreshUI() end
      if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
      NS.Print("Added daily task.")
    end

  elseif msg:sub(1, 5) == "addw " then
    local text = NS.STrim(msg:sub(6))
    if NS.IsEmpty(text) then
      NS.Print("Cannot add a blank task.")
    else
      table.insert(db.tasks, { text = text, frequency = "weekly", completed = false })
      if NS.RefreshUI then NS.RefreshUI() end
      if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
      NS.Print("Added weekly task.")
    end

  elseif msg == "minimap" then
    db.showMinimap = not (db.showMinimap == false)
    if NS.UpdateMinimapVisibility then NS.UpdateMinimapVisibility(db) end
    NS.Print("Minimap button " .. ((db.showMinimap == false) and "hidden" or "shown") .. ".")

  elseif msg == "help" then
    if NS.ToggleHelp then NS.ToggleHelp(UI.frame or UIParent) end

  elseif msg == "reset" or msg == "reset all" then
    if NS.ResetTasks then NS.ResetTasks("all") end
    NS.Print("All tasks reset to incomplete.")

  elseif msg == "reset daily" then
    if NS.ResetTasks then NS.ResetTasks("daily") end
    NS.Print("All daily tasks reset to incomplete.")

  elseif msg == "reset weekly" then
    if NS.ResetTasks then NS.ResetTasks("weekly") end
    NS.Print("All weekly tasks reset to incomplete.")

  elseif msg == "fixframe" or msg == "resetframe" then
    db.window = { w = 460, h = 500, x = 0, y = 0, shown = true }
    if UI and UI.frame then
      UI.frame:ClearAllPoints()
      UI.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
      UI.frame:SetSize(460, 500)
      UI.frame:Show()
    end
    NS.Print("Frame reset to default size & centered.")
    if NS.RefreshUI then NS.RefreshUI() end
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end

  else
    NS.Print("Commands: /wcl (toggle), /wcl add <text>, /wcl addw <text>, /wcl minimap, /wcl reset [daily|weekly|all], /wcl fixframe, /wcl help")
  end
end

----------------------------------------------------------------------
-- World/zone and logout events
----------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("ZONE_CHANGED")
ev:RegisterEvent("ZONE_CHANGED_INDOORS")
ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ev:RegisterEvent("PLAYER_LOGOUT")
ev:SetScript("OnEvent", function(_, event)
  if (event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" or
      event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA") then
    if NS.UpdateZoneText then NS.UpdateZoneText() end
  elseif event == "PLAYER_LOGOUT" then
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
  end
end)
