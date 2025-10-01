-- ui_extras.lua
-- Purpose: Minimap button, Options panel, Help popup, and copy/link dialogs.
-- Scope: UI utilities only. No compat logic here—use compat.lua shims where needed.
-- Notes: Strict localization via T(KEY); no inline fallbacks. No globals. Constants collected in C.

local ADDON, NS = ...

-- ===== Constants (avoid magic numbers) =====
local C = {
  -- Help popup
  HELP_W            = 380,
  HELP_H            = 420,
  HELP_INSET_TL_X   = 8,    -- scrollframe top-left X
  HELP_INSET_TL_Y   = -28,  -- scrollframe top-left Y
  HELP_INSET_BR_X   = -28,  -- scrollframe bottom-right X
  HELP_INSET_BR_Y   = 40,   -- scrollframe bottom-right Y
  HELP_BODY_W       = 320,
  HELP_CLOSE_W      = 90,
  HELP_CLOSE_H      = 22,
  HELP_CLOSE_X      = 8,
  HELP_CLOSE_Y      = 10,
  HELP_OPACITY      = 1.0,
  HELP_REANCHOR_DLY = 0,    -- C_Timer.After delay for re-anchoring

  -- Copy/confirm popups
  COPY_TIMEOUT      = 20,
  POPUP_PREF_INDEX  = 3,

  -- Minimap button
  MINIMAP_SIZE      = 31,
  MINIMAP_RING      = 54,
  MINIMAP_ICON      = 17,
  MINIMAP_POINT_X   = 4,
  MINIMAP_POINT_Y   = -4,
  MINIMAP_ICON_X    = 7,
  MINIMAP_ICON_Y    = -6,
  MINIMAP_BACK_W    = 20,
  MINIMAP_BACK_H    = 20,
  MINIMAP_BACK_X    = 7,
  MINIMAP_BACK_Y    = -5,

  -- Options panel
  OPT_TITLE_TL_X    = 16,
  OPT_TITLE_TL_Y    = -16,
  OPT_SCROLL_TL_X   = 16,
  OPT_SCROLL_TL_Y   = -48,
  OPT_SCROLL_BR_X   = -36,
  OPT_SCROLL_BR_Y   = 180,
  OPT_BODY_W        = 560,
  OPT_BODY_H        = 1000,
  OPT_BOTTOM_INSET  = 16,
  OPT_ROW_GAP       = 12,
  OPT_BTN_W         = 160,
  OPT_BTN_H         = 22,
  OPT_LINK_W_MIN    = 120,
  OPT_LINK_GAP_X    = 128,

  -- Dropdown
  DD_WIDTH          = 220,
  DD_LEFT_ADJUST    = -16,

  -- Generic
  BTN_W_STD         = 90,
  BTN_H_STD         = 22,
  LABEL_BTN_GAP     = 4,
}

-- ===== Strict localization helper =====
local function T(key)
  local L = NS.L or {}
  assert(L[key], "Missing locale key: " .. tostring(key))
  return L[key]
end

-- ===== Localize hot globals =====
local CreateFrame = CreateFrame
local UIParent    = UIParent
local C_Timer     = C_Timer
local GameTooltip = GameTooltip
local ipairs      = ipairs
local pairs       = pairs
local table       = table
local t_insert    = table.insert
local t_sort      = table.sort

-- ===== Shared UI namespace =====
NS.UI = NS.UI or {}
local UI = NS.UI

-- ===== Internal helpers =====
local function MakeOpaqueBackground(frame)
  local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
  bg:SetAllPoints(true)
  bg:SetColorTexture(0, 0, 0, C.HELP_OPACITY)
  return bg
end

local function HideAllPopups()
  if UI.help    then UI.help:Hide()    end
  if UI.context then UI.context:Hide() end
end
NS.HideAllPopups = HideAllPopups

local function DeepCopyTasks(list)
  local out = {}
  for _, t in ipairs(list or {}) do
    out[#out+1] = { text = t.text, frequency = t.frequency, completed = t.completed and true or false }
  end
  return out
end

-- ===== Copy / Link dialogs =====
StaticPopupDialogs["WCL_COPY_LINK"] = {
  text = T("COPY_LINK_TEXT"),
  button1 = OKAY, hasEditBox = true, showAlert = true,
  timeout = 0, whileDead = true, hideOnEscape = true, enterClicksFirstButton = true,
  preferredIndex = C.POPUP_PREF_INDEX,
  OnShow = function(self, data)
    local eb = self.editBox
    eb:SetText(type(data) == "string" and data or "")
    eb:HighlightText()
    eb:SetFocus()
  end,
  EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
}

StaticPopupDialogs["WCL_COPY_CONFIRM"] = {
  text = "", -- set in OnShow
  button1 = YES, button2 = NO,
  OnShow = function(self, data) self.text:SetText(data and data.msg or "") end,
  OnAccept = function(self, data)
    if not data or not data.srcTasks then return end
    local db2 = NS.EnsureDB()
    db2.tasks = DeepCopyTasks(data.srcTasks)
    if NS.RefreshUI then NS.RefreshUI() end
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
  end,
  timeout = C.COPY_TIMEOUT, whileDead = true, hideOnEscape = true, preferredIndex = C.POPUP_PREF_INDEX,
}

function NS.ShowCopyLinkPopup(url) StaticPopup_Show("WCL_COPY_LINK", nil, nil, url) end

-- ===== Help popup =====
function NS.ToggleHelp(parent)
  if UI.help and UI.help:IsShown() then UI.help:Hide(); return end
  HideAllPopups()

  local h = CreateFrame("Frame", nil, parent or UI.frame, "BasicFrameTemplateWithInset")
  h:SetSize(C.HELP_W, C.HELP_H)
  h:SetFrameStrata("DIALOG"); h:SetToplevel(true); h:SetResizable(false)
  if h.TitleText then h.TitleText:SetText(T("HELP_TITLE")) end
  MakeOpaqueBackground(h)

  local function AnchorPopupNearClose(popup, parentFrame)
    local f = parentFrame or UI.frame
    popup:ClearAllPoints()
    local closeBtn = f and _G[((f:GetName() or "") .. "CloseButton")]
    if closeBtn then popup:SetPoint("TOPLEFT", closeBtn, "BOTTOMRIGHT", 8, -6)
    else popup:SetPoint("TOPRIGHT", f or UIParent, "TOPRIGHT", 8, 0) end
  end
  AnchorPopupNearClose(h, parent)
  if C_Timer and C_Timer.After then C_Timer.After(C.HELP_REANCHOR_DLY, function() if h and h:IsShown() then AnchorPopupNearClose(h, parent) end end) end

  local sf = CreateFrame("ScrollFrame", nil, h, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT",     h, "TOPLEFT",     C.HELP_INSET_TL_X, C.HELP_INSET_TL_Y)
  sf:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", C.HELP_INSET_BR_X, C.HELP_INSET_BR_Y)
  local body = CreateFrame("Frame", nil, sf); sf:SetScrollChild(body); body:SetSize(C.HELP_BODY_W, C.HELP_H * 2 + 160)
  local text = body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  text:SetPoint("TOPLEFT"); text:SetWidth(C.HELP_BODY_W); text:SetJustifyH("LEFT"); text:SetText(T("HELP_BODY"))

  local close = CreateFrame("Button", nil, h, "UIPanelButtonTemplate")
  close:SetPoint("BOTTOMLEFT", h, "BOTTOMLEFT", C.HELP_CLOSE_X, C.HELP_CLOSE_Y)
  close:SetSize(C.HELP_CLOSE_W, C.HELP_CLOSE_H)
  close:SetText(T("BTN_CLOSE"))
  close:SetScript("OnClick", function() h:Hide() end)

  h:EnableKeyboard(true); h:SetScript("OnKeyDown", function(self, key) if key == "ESCAPE" then self:Hide() end end)

  UI.help = h; h:Show()
end

-- ===== Minimap button =====
function NS.UpdateMinimapVisibility(db)
  if UI.minimap then UI.minimap:SetShown(db.showMinimap ~= false) end
end

function NS.CreateMinimapButton(db)
  if UI.minimap or not Minimap then return end

  local btn = CreateFrame("Button", "WinterChecklist_MinimapButton", Minimap)
  btn:SetSize(C.MINIMAP_SIZE, C.MINIMAP_SIZE)
  btn:SetFrameStrata("MEDIUM")
  btn:SetFrameLevel(8)
  btn:SetPoint("TOPLEFT", Minimap, "TOPLEFT", C.MINIMAP_POINT_X, C.MINIMAP_POINT_Y)

  local ring = btn:CreateTexture(nil, "OVERLAY")
  ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  ring:SetSize(C.MINIMAP_RING, C.MINIMAP_RING)
  ring:SetPoint("TOPLEFT", 0, 0)

  local back = btn:CreateTexture(nil, "BACKGROUND")
  back:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  back:SetSize(C.MINIMAP_BACK_W, C.MINIMAP_BACK_H)
  back:SetPoint("TOPLEFT", C.MINIMAP_BACK_X, C.MINIMAP_BACK_Y)

  local icon = btn:CreateTexture(nil, "ARTWORK")
  icon:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
  icon:SetSize(C.MINIMAP_ICON, C.MINIMAP_ICON)
  icon:SetPoint("TOPLEFT", C.MINIMAP_ICON_X, C.MINIMAP_ICON_Y)
  icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
  UI.minimapIcon = icon

  btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

  btn:SetScript("OnClick", function()
    local d = NS.EnsureDB()
    if UI.frame:IsShown() then UI.frame:Hide() else UI.frame:Show() end
    d.window = d.window or { w = 460, h = 500, x = 0, y = 0, shown = true }
    d.window.shown = UI.frame:IsShown()
  end)

  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
    GameTooltip:SetText(T("TITLE"), 1, 1, 1)
    GameTooltip:AddLine(T("TIP_MINIMAP_TOGGLE"), .8, .8, .8)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

  UI.minimap = btn
  NS.UpdateMinimapVisibility(db)
end

-- ===== Options panel =====
function NS.CreateOptionsPanel(db)
  local panel = CreateFrame("Frame"); panel.name = T("TITLE")

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", C.OPТ_TITLE_TL_X or C.OPT_TITLE_TL_X, C.OPT_TITLE_TL_Y)
  title:SetText(T("TITLE"))

  -- Help text (scroll)
  local helpScroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
  helpScroll:SetPoint("TOPLEFT",     panel, "TOPLEFT",     C.OPT_SCROLL_TL_X, C.OPT_SCROLL_TL_Y)
  helpScroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", C.OPT_SCROLL_BR_X, C.OPT_SCROLL_BR_Y)

  local body = CreateFrame("Frame", nil, helpScroll); helpScroll:SetScrollChild(body)
  body:SetSize(C.OPT_BODY_W, C.OPT_BODY_H)

  local helpText = body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  helpText:SetPoint("TOPLEFT"); helpText:SetWidth(C.OPT_BODY_W); helpText:SetJustifyH("LEFT")
  helpText:SetText(T("HELP_BODY"))

  -- Bottom area (acts as layout container)
  local bottomArea = CreateFrame("Frame", nil, panel)
  bottomArea:SetPoint("TOPLEFT",     helpScroll, "BOTTOMLEFT",  0, -C.OPT_ROW_GAP)
  bottomArea:SetPoint("TOPRIGHT",    helpScroll, "BOTTOMRIGHT", 0, -C.OPT_ROW_GAP)
  bottomArea:SetPoint("BOTTOMRIGHT", panel,      "BOTTOMRIGHT", -C.OPT_BOTTOM_INSET, C.OPT_BOTTOM_INSET)
  bottomArea:SetPoint("BOTTOMLEFT",  panel,      "BOTTOMLEFT",   C.OPT_BOTTOM_INSET, C.OPT_BOTTOM_INSET)

  -- Row 1: Minimap checkbox + Open button
  local cb = CreateFrame("CheckButton", nil, bottomArea, "InterfaceOptionsCheckButtonTemplate")
  cb:SetPoint("TOPLEFT", bottomArea, "TOPLEFT", 0, 0)
  cb.Text:SetText(T("MINIMAP_SHOW"))
  cb:SetChecked(db.showMinimap ~= false)
  cb:SetScript("OnClick", function(self)
    db.showMinimap = self:GetChecked()
    NS.UpdateMinimapVisibility(db)
  end)

  local open = CreateFrame("Button", nil, bottomArea, "UIPanelButtonTemplate")
  open:SetSize(C.OPT_BTN_W, C.OPT_BTN_H)
  open:ClearAllPoints()
  open:SetPoint("TOPRIGHT", bottomArea, "TOPRIGHT", 0, 0)
  open:SetPoint("TOP", cb, "TOP", 0, 0)
  open:SetText(T("BTN_TOGGLE"))
  open:SetScript("OnClick", function()
    local d = NS.EnsureDB()
    if UI.frame:IsShown() then UI.frame:Hide() else UI.frame:Show() end
    d.window = d.window or { w = 460, h = 500, x = 0, y = 0, shown = true }
    d.window.shown = UI.frame:IsShown()
  end)

  cb.Text:ClearAllPoints()
  cb.Text:SetPoint("LEFT",  cb,   "RIGHT", C.LABEL_BTN_GAP, 0)
  cb.Text:SetPoint("RIGHT", open, "LEFT", -C.LABEL_BTN_GAP*3, 0)
  cb.Text:SetWordWrap(false)

  -- Row 2: Profile management (copy-from)
  local profTitle = bottomArea:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  profTitle:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 0, -C.OPT_ROW_GAP)
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
    local adb = NS.EnsureAccountDB()
    local items, selfKey = {}, CurrentCharKey()
    for key, val in pairs(adb.profiles or {}) do
      if key ~= selfKey and val.tasks and #val.tasks > 0 then
        t_insert(items, key)
      end
    end
    t_sort(items)
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
    local adb = NS.EnsureAccountDB()
    local src = adb.profiles[selectedKey]
    if not (src and src.tasks and #src.tasks > 0) then
      if NS.Print then NS.Print(T("MSG_PROFILE_EMPTY")) end
      return
    end
    local msg = (T("COPY_CONFIRM_FMT")):format(CurrentCharKey(), selectedKey)
    StaticPopup_Show("WCL_COPY_CONFIRM", nil, nil, { msg = msg, srcTasks = src.tasks })
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
    b:SetScript("OnClick", function() NS.ShowCopyLinkPopup(url) end)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
      GameTooltip:SetText(label, 1, 1, 1)
      GameTooltip:AddLine(tooltip, 0.9, 0.9, 0.9, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
  end

  local curseBtn = MakeLinkButton(bottomArea, T("LINK_CURSE_LABEL"),
    "www.curseforge.com/wow/addons/checklist",
    T("LINK_CURSE_TIP"), linksTitle, 0)
  local gitBtn = MakeLinkButton(bottomArea, T("LINK_GITHUB_LABEL"),
    "github.com/ctgarry/dev/tree/main/WinterChecklist",
    T("LINK_GITHUB_TIP"), linksTitle, C.OPT_LINK_GAP_X)

  local belowLinks = gitBtn
  local contrib = bottomArea:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  contrib:SetPoint("TOPLEFT", belowLinks, "BOTTOMLEFT", 0, -C.OPT_ROW_GAP)
  contrib:SetText(T("CONTRIB"))

  panel:SetScript("OnShow", RefreshDropdown)

  -- Settings registration (Retail) vs InterfaceOptions (Classic)
  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, T("TITLE"))
    Settings.RegisterAddOnCategory(category)
  else
    if InterfaceOptions_AddCategory then InterfaceOptions_AddCategory(panel) end
  end

  UI.options = UI.options or {}
  UI.options.panel = panel
end
