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
    end
    tag("commands: lock | unlock | toggle | minimap")
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
