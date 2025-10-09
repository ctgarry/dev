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

-- Slash /wc
SLASH_WINTERCHECKLIST1 = "/wc"
SlashCmdList["WINTERCHECKLIST"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "lock" or msg == "unlock" or msg == "toggle" or msg == "on" or msg == "off" then
        lockCmd(msg) ; return
    elseif msg == "minimap" then
        DB.minimap.hide = not DB.minimap.hide
        if ADDON.Minimap and ADDON.Minimap.UpdateVisibility then ADDON.Minimap.UpdateVisibility(DB.minimap.hide) end
        tag("Minimap button "..(DB.minimap.hide and "hidden" or "shown")) ; return
    elseif msg == "import" then if NS.ShowImport then NS.ShowImport(_G.WC_Main) end
    elseif msg == "export" then if NS.ShowExport then NS.ShowExport(_G.WC_Main) end
    elseif msg == "" or msg == "help" then
      tag("commands: lock | unlock | toggle | minimap | import | export")
    else
      if NS.ToggleMain then NS.ToggleMain() end
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