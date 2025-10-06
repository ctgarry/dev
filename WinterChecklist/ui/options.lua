-- File: options.lua
-- Purpose: Options panel (Settings/InterfaceOptions) with help text, minimap toggle, open button, profile copy, and links.
-- Scope: UI options panel only; no globals; localized strings via T().

local ADDON, NS = ...
NS.UI = NS.UI or {}
local UI = NS.UI

-- ===== Strict localization helper =====
local function T(key)
  local L = NS.L or {}
  assert(L[key], "Missing locale key: " .. tostring(key))
  return L[key]
end

-- ===== Constants (use shared NS.C, provide safe defaults) =====
NS.C = NS.C or {}
local C = NS.C
C.OPT_TITLE_TL_X   = C.OPT_TITLE_TL_X   or 16
C.OPT_TITLE_TL_Y   = C.OPT_TITLE_TL_Y   or -16
C.OPT_SCROLL_TL_X  = C.OPT_SCROLL_TL_X  or 16
C.OPT_SCROLL_TL_Y  = C.OPT_SCROLL_TL_Y  or -48
C.OPT_SCROLL_BR_X  = C.OPT_SCROLL_BR_X  or -36
C.OPT_SCROLL_BR_Y  = C.OPT_SCROLL_BR_Y  or 180
C.OPT_BODY_W       = C.OPT_BODY_W       or 560
C.OPT_BODY_H       = C.OPT_BODY_H       or 1000
C.OPT_BOTTOM_INSET = C.OPT_BOTTOM_INSET or 16
C.OPT_ROW_GAP      = C.OPT_ROW_GAP      or 12
C.OPT_BTN_W        = C.OPT_BTN_W        or 160
C.OPT_BTN_H        = C.OPT_BTN_H        or 22
C.OPT_LINK_W_MIN   = C.OPT_LINK_W_MIN   or 120
C.OPT_LINK_GAP_X   = C.OPT_LINK_GAP_X   or 128
C.DD_WIDTH         = C.DD_WIDTH         or 220
C.DD_LEFT_ADJUST   = C.DD_LEFT_ADJUST   or -16
C.LABEL_BTN_GAP    = C.LABEL_BTN_GAP    or 4

-- ===== Panel =====
local panel = CreateFrame("Frame", "WinterChecklistOptionsPanel")
panel.name = T("TITLE")

-- Title
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", C.OPT_TITLE_TL_X, C.OPT_TITLE_TL_Y)
title:SetText(T("TITLE"))

-- Help text (scrolling body)
local helpScroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
helpScroll:SetPoint("TOPLEFT",     panel, "TOPLEFT",     C.OPT_SCROLL_TL_X, C.OPT_SCROLL_TL_Y)
helpScroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", C.OPT_SCROLL_BR_X, C.OPT_SCROLL_BR_Y)
local body = CreateFrame("Frame", nil, helpScroll); helpScroll:SetScrollChild(body)
body:SetSize(C.OPT_BODY_W, C.OPT_BODY_H)

local helpText = body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
helpText:SetPoint("TOPLEFT"); helpText:SetWidth(C.OPT_BODY_W); helpText:SetJustifyH("LEFT")
helpText:SetText(T("HELP_BODY"))

-- Bottom area (container below help)
local bottomArea = CreateFrame("Frame", nil, panel)
bottomArea:SetPoint("TOPLEFT",     helpScroll, "BOTTOMLEFT",  0, -C.OPT_ROW_GAP)
bottomArea:SetPoint("TOPRIGHT",    helpScroll, "BOTTOMRIGHT", 0, -C.OPT_ROW_GAP)
bottomArea:SetPoint("BOTTOMRIGHT", panel,      "BOTTOMRIGHT", -C.OPT_BOTTOM_INSET, C.OPT_BOTTOM_INSET)
bottomArea:SetPoint("BOTTOMLEFT",  panel,      "BOTTOMLEFT",   C.OPT_BOTTOM_INSET, C.OPT_BOTTOM_INSET)

-- Row 1: Minimap checkbox + Open button
local cbMini = CreateFrame("CheckButton", "WinterChecklistOptions_ShowMinimap", bottomArea, "InterfaceOptionsCheckButtonTemplate")
cbMini:SetPoint("TOPLEFT", bottomArea, "TOPLEFT", 0, 0)
_G["WinterChecklistOptions_ShowMinimapText"]:SetText(T("MINIMAP_SHOW"))

local openBtn = CreateFrame("Button", nil, bottomArea, "UIPanelButtonTemplate")
openBtn:SetSize(C.OPT_BTN_W, C.OPT_BTN_H)
openBtn:ClearAllPoints()
openBtn:SetPoint("TOPRIGHT", bottomArea, "TOPRIGHT", 0, 0)
openBtn:SetPoint("TOP", cbMini, "TOP", 0, 0)
openBtn:SetText(T("BTN_TOGGLE"))

cbMini:SetScript("OnClick", function(self)
  local db = NS.EnsureDB()
  db.showMinimap = self:GetChecked()
  if NS.Minimap and NS.Minimap.UpdateVisibility then
    NS.Minimap.UpdateVisibility(db.showMinimap == false)
  end
end)

openBtn:SetScript("OnClick", function()
  local d = NS.EnsureDB()
  if UI.frame and UI.frame:IsShown() then UI.frame:Hide() else if UI.frame then UI.frame:Show() end end
  d.window = d.window or { w = 460, h = 500, x = 0, y = 0, shown = true }
  if UI.frame then d.window.shown = UI.frame:IsShown() end
end)

-- Row 1b: Lock checkbox (optional, if NS.LockCmd exists)
local cbLock = CreateFrame("CheckButton", "WinterChecklistOptions_Lock", bottomArea, "InterfaceOptionsCheckButtonTemplate")
cbLock:SetPoint("TOPLEFT", cbMini, "BOTTOMLEFT", 0, -C.OPT_ROW_GAP)
_G["WinterChecklistOptions_LockText"]:SetText(T("LOCK_ANCHOR") or "Lock anchor")
cbLock:SetScript("OnClick", function(self)
  local checked = self:GetChecked() and true or false
  local DB = NS.EnsureDB()
  DB.locked = checked
  if NS.LockCmd then NS.LockCmd(checked and "on" or "off") end
end)

-- Row 2: Profiles (dropdown + Copy From)
local profTitle = bottomArea:CreateFontString(nil, "ARTWORK", "GameFontNormal")
profTitle:SetPoint("TOPLEFT", cbLock, "BOTTOMLEFT", 0, -C.OPT_ROW_GAP)
profTitle:SetText(T("PROFILE_MGMT_TITLE"))

local dropdown = CreateFrame("Frame", "WinterChecklistProfileDropdown", bottomArea, "UIDropDownMenuTemplate")
UIDropDownMenu_SetWidth(dropdown, C.DD_WIDTH)
dropdown:ClearAllPoints()
dropdown:SetPoint("TOPLEFT", profTitle, "BOTTOMLEFT", C.DD_LEFT_ADJUST, -6)

local selectedKey = nil
local function CurrentCharKey()
  local name  = UnitName("player") or "Unknown"
  local realm = (GetRealmName and GetRealmName() or ""):gsub("%s+", "")
  return ("%s-%s"):format(name, realm)
end

local function RefreshDropdown()
  local adb = NS.EnsureAccountDB and NS.EnsureAccountDB() or {}
  local items, selfKey = {}, CurrentCharKey()
  if adb and adb.profiles then
    for key, val in pairs(adb.profiles) do
      if key ~= selfKey and val.tasks and #val.tasks > 0 then
        table.insert(items, key)
      end
    end
    table.sort(items)
  end
  UIDropDownMenu_SetText(dropdown, selectedKey or T("PROFILE_SELECT_PROMPT"))
  UIDropDownMenu_Initialize(dropdown, function(self, level)
    for _, key in ipairs(items) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = key
      info.func = function() selectedKey = key; UIDropDownMenu_SetText(dropdown, key) end
      UIDropDownMenu_AddButton(info, level)
    end
  end)
end

local copyBtn = CreateFrame("Button", nil, bottomArea, "UIPanelButtonTemplate")
copyBtn:SetSize(C.OPT_BTN_W, C.OPT_BTN_H)
copyBtn:ClearAllPoints()
copyBtn:SetPoint("TOP",   dropdown,   "TOP",   0, 0)
copyBtn:SetPoint("RIGHT", bottomArea, "RIGHT", 0, 0)
copyBtn:SetText(T("BTN_COPY_FROM"))
copyBtn:SetScript("OnClick", function()
  if not selectedKey then
    if NS.Print then NS.Print(T("MSG_SELECT_PROFILE")) end
    return
  end
  local adb = NS.EnsureAccountDB and NS.EnsureAccountDB() or {}
  local src = adb.profiles and adb.profiles[selectedKey]
  if not (src and src.tasks and #src.tasks > 0) then
    if NS.Print then NS.Print(T("MSG_PROFILE_EMPTY")) end
    return
  end
  local msg = (T("COPY_CONFIRM_FMT")):format(CurrentCharKey(), selectedKey)
  -- Use popup from ui_extras.lua implementation
  if StaticPopup_Show then
    StaticPopup_Show("WCL_COPY_CONFIRM", nil, nil, { msg = msg, srcTasks = src.tasks })
  end
end)

-- Row 3: Links
local linksTitle = bottomArea:CreateFontString(nil, "ARTWORK", "GameFontNormal")
linksTitle:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 16, -C.OPT_ROW_GAP)
linksTitle:SetText(T("HELP_LINKS"))

local function MakeLinkButton(parent, label, url, tooltip, relTo, xOffset)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(C.OPT_LINK_W_MIN, C.OPT_BTN_H)
  b:SetPoint("TOPLEFT", relTo, "BOTTOMLEFT", xOffset or 0, -6)
  b:SetText(label)
  b:SetWidth(math.max(C.OPT_LINK_W_MIN, b:GetTextWidth() + 24))
  b:SetScript("OnClick", function() if NS.ShowCopyLinkPopup then NS.ShowCopyLinkPopup(url) end end)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:SetText(label, 1, 1, 1)
    GameTooltip:AddLine(tooltip, 0.9, 0.9, 0.9, true)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return b
end

local curseBtn = MakeLinkButton(bottomArea, T("LINK_CURSE_LABEL"),  "www.curseforge.com/wow/addons/checklist", T("LINK_CURSE_TIP"), linksTitle, 0)
local gitBtn   = MakeLinkButton(bottomArea, T("LINK_GITHUB_LABEL"), "github.com/ctgarry/dev/tree/main/WinterChecklist", T("LINK_GITHUB_TIP"), linksTitle, C.OPT_LINK_GAP_X)

-- Refresh state when panel shown
local function Refresh()
  local DB = NS.EnsureDB()
  if cbLock then cbLock:SetChecked(DB.locked and true or false) end
  if cbMini then
    local hidden = DB.minimap and DB.minimap.hide
    cbMini:SetChecked(not hidden)
  end
  RefreshDropdown()
end

panel:SetScript("OnShow", Refresh)
panel.refresh = Refresh
panel.okay = function() end
panel.default = function() end

-- Register in Retail/Classic
if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
  local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
  InterfaceOptions_AddCategory(panel)
end

-- Slash to open options panel
SLASH_WINTERCHECKLIST_OPTIONS1 = "/wcoptions"
SLASH_WINTERCHECKLIST_OPTIONS2 = "/wcopt"
SLASH_WINTERCHECKLIST_OPTIONS3 = "/wcoptionspanel"
SlashCmdList["WINTERCHECKLIST_OPTIONS"] = function()
  if Settings and Settings.OpenToCategory then
    Settings.OpenToCategory(panel.name)
  elseif InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel) -- Blizzard quirk
  end
end

-- Keep a reference for other modules/tests
UI.options = UI.options or {}
UI.options.panel = panel
