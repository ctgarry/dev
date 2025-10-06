-- WinterChecklist 1.5 — options.lua (immediate apply + opener uses panel ref)
local ADDON_NAME = ...
local ADDON = _G[ADDON_NAME] or {}
_G[ADDON_NAME] = ADDON

local panel = CreateFrame("Frame", "WinterChecklistOptionsPanel")
panel.name = "WinterChecklist"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("WinterChecklist")

local function makeCheckbox(parent, name, label, x, y, onClick)
    local cb = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    local textFS = _G[name .. "Text"]
    if not textFS then
        textFS = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        textFS:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    end
    textFS:SetText(label)
    cb.Text = textFS
    if onClick then
        cb:SetScript("OnClick", function(self) onClick(self:GetChecked() and true or false) end)
    end
    return cb
end

local function refresh()
    local DB = _G.WinterChecklistDB or {}
    if _G.WinterChecklistOptions_Lock then
        _G.WinterChecklistOptions_Lock:SetChecked(DB.locked and true or false)
    end
    if _G.WinterChecklistOptions_ShowMinimap then
        local hidden = DB.minimap and DB.minimap.hide
        _G.WinterChecklistOptions_ShowMinimap:SetChecked(not hidden)
    end
end

-- Immediate apply handlers
local cbLock = makeCheckbox(panel, "WinterChecklistOptions_Lock", "Lock anchor", 16, -48, function(checked)
    local DB = _G.WinterChecklistDB or {}
    DB.locked = checked and true or false
    if ADDON.LockCmd then ADDON.LockCmd(DB.locked and "on" or "off") end
end)

local cbMini = makeCheckbox(panel, "WinterChecklistOptions_ShowMinimap", "Show minimap button", 16, -78, function(checked)
    local DB = _G.WinterChecklistDB or {}
    DB.minimap = DB.minimap or {}
    DB.minimap.hide = (not checked) and true or false
    if ADDON.Minimap and ADDON.Minimap.UpdateVisibility then
        ADDON.Minimap.UpdateVisibility(DB.minimap.hide)
    end
end)

panel:SetScript("OnShow", refresh)
panel.refresh = refresh
panel.okay = function() end  -- immediate apply; nothing to do
panel.default = function() end

-- Register in whichever system exists
if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
end

-- Slash to open options using the panel ref
SLASH_WINTERCHECKLIST_OPTIONS1 = "/wcoptions"
SLASH_WINTERCHECKLIST_OPTIONS2 = "/wcopt"
SLASH_WINTERCHECKLIST_OPTIONS3 = "/wcoptionspanel"
SlashCmdList["WINTERCHECKLIST_OPTIONS"] = function()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(panel.name)
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel) -- call twice; Blizzard quirk
    end
end
