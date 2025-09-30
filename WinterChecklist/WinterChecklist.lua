-- WinterChecklist.lua
-- Lightweight checklist addon for Retail & Classic Era.
-- SavedVariablesPerCharacter: WinterChecklistDB
-- For profile management, add to your .toc:
-- ## SavedVariables: WinterChecklistAccountDB

local ADDON, NS = ...
NS = NS or {}

----------------------------------------------------------------------
-- Constants & small utils
----------------------------------------------------------------------
local PAD = 10
local BOTTOM_BAR_H = 48 -- space for radios + zone + refresh
local function STrim(s) if not s then return "" end return (s:gsub("^%s+",""):gsub("%s+$","")) end
local function IsEmpty(s) return STrim(s) == "" end
local function Print(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Checklist|r: "..(msg or "")) end

local function SafeSetResizeBounds(frame, minW, minH, maxW, maxH)
  if frame.SetResizeBounds then frame:SetResizeBounds(minW, minH, maxW, maxH)
  else -- Classic fallback
    frame:SetMinResize(minW, minH)
    -- no max on Classic; SetMaxResize doesn’t exist pre-10.0
  end
end

-- Auto-wrap a row of buttons within a container width (one or more rows)
local function ReflowRow(container, items, padX, padY)
  if not container or not items or #items == 0 then return end
  padX, padY = padX or 6, padY or 6
  local W = container:GetWidth() or 320
  local x, y, rowH = 0, 0, 0
  for _, btn in ipairs(items) do
    btn:ClearAllPoints()
    local bw = btn:GetWidth()
    local bh = btn:GetHeight()
    if x > 0 and (x + bw) > W then x, y, rowH = 0, y + rowH + padY, 0 end
    btn:SetPoint("TOPLEFT", container, "TOPLEFT", x, -y)
    x = x + bw + padX
    if bh > rowH then rowH = bh end
  end
  container:SetHeight(y + rowH)
end

-- Shallow table clone (for profile snapshot copy)
local function Clone(tbl)
  if type(tbl) ~= "table" then return tbl end
  local t = {}
  for k, v in pairs(tbl) do t[k] = (type(v) == "table") and Clone(v) or v end
  return t
end

----------------------------------------------------------------------
-- Saved Vars scaffolding
----------------------------------------------------------------------
WinterChecklistDB = WinterChecklistDB or { items = {}, opts = { minimap = true } }
WinterChecklistAccountDB = WinterChecklistAccountDB or { profiles = {} }

local function GetCharKey()
  local name, realm = UnitName("player"), GetRealmName()
  return ("%s-%s"):format(name or "Unknown", realm or "Realm")
end

----------------------------------------------------------------------
-- Exclusive panel manager (help/import/export/context/popup/options)
----------------------------------------------------------------------
NS._openPanels = {}  -- key -> frame
function NS.RegisterExclusive(key, frame) NS._openPanels[key] = frame end
function NS.OpenExclusive(key, open)
  -- Close all
  for k, f in pairs(NS._openPanels) do if f and f.Hide then f:Hide() end end
  -- Open one
  if open and NS._openPanels[key] and NS._openPanels[key].Show then NS._openPanels[key]:Show() end
end

----------------------------------------------------------------------
-- Copy-to-clipboard popup (StaticPopup with edit box)
----------------------------------------------------------------------
StaticPopupDialogs["WCL_COPY_LINK"] = {
  text = "%s",
  button1 = OKAY,
  hasEditBox = true,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
  OnShow = function(self, data)
    local eb = self.editBox
    eb:SetAutoFocus(true)
    eb:SetText(data or "")
    eb:HighlightText()
    eb:SetFocus()
  end,
  EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
  timeout = 0,
}
function NS.ShowCopyPopup(title, text)
  -- Logically exclusive with other UI
  NS.OpenExclusive("popup", false)
  StaticPopup_Show("WCL_COPY_LINK", title, nil, text)
end

-- Project links (edit to your canonical URLs)
local CURSE_URL  = "https://www.curseforge.com/wow/addons/winterchecklist"
local GITHUB_URL = "https://github.com/ctgarry/dev/tree/main/WinterChecklist"

----------------------------------------------------------------------
-- Main UI
----------------------------------------------------------------------
local main = CreateFrame("Frame", "WCL_Main", UIParent, BackdropTemplateMixin and "BackdropTemplate")
main:SetSize(480, 560)
main:SetPoint("CENTER")
SafeSetResizeBounds(main, 360, 420, 900, 1000)
main:SetMovable(true) main:EnableMouse(true)
main:RegisterForDrag("LeftButton")
main:SetScript("OnDragStart", function(self) self:StartMoving() end)
main:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
main:Hide()

-- Backdrop (opaque for readability)
local bd = { bgFile="Interface/ChatFrame/ChatFrameBackground", edgeFile="Interface/DialogFrame/UI-DialogBox-Border", tile=true, tileSize=16, edgeSize=16, insets={left=5,right=5,top=5,bottom=5} }
main:SetBackdrop(bd)
main:SetBackdropColor(0,0,0,0.75)

-- Title text with counts
local title = main:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOP", 0, -12)
local function UpdateTitle(done, vis)
  title:SetText(("Checklist  |  %d/%d"):format(done or 0, vis or 0))
end

-- Close button
local close = CreateFrame("Button", nil, main, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", 0, 0)

-- Top bar (auto-wrap container)
NS.TopBar = CreateFrame("Frame", nil, main)
NS.TopBar:SetPoint("TOPLEFT", main, "TOPLEFT", PAD, -36)
NS.TopBar:SetPoint("TOPRIGHT", main, "TOPRIGHT", -PAD, -36)
NS.TopBar:SetHeight(32)

-- Search box
local search = CreateFrame("EditBox", nil, NS.TopBar, "InputBoxTemplate")
search:SetSize(180, 26)
search:SetAutoFocus(false)
search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
search:SetScript("OnTextChanged", function(self) NS.searchText = self:GetText(); NS.RefreshList(true) end)

-- + / E / - buttons
local function SmallBtn(parent, label, tooltip)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(28, 26)
  b:SetText(label)
  if tooltip then
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(tooltip, 1,1,1,1,true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  end
  return b
end

local addBtn  = SmallBtn(NS.TopBar, "+", "Add daily item")
local editBtn = SmallBtn(NS.TopBar, "E", "Edit selected")
local delBtn  = SmallBtn(NS.TopBar, "-", "Delete selected")

-- gear/help buttons (open copy-to-clipboard popups)
local gearBtn = SmallBtn(NS.TopBar, "⚙", "Project links")
gearBtn:SetWidth(32)
gearBtn:SetScript("OnClick", function()
  NS.ShowCopyPopup("Copy URL (CurseForge)", CURSE_URL)
end)

local helpBtn = SmallBtn(NS.TopBar, "?", "Source / docs")
helpBtn:SetWidth(28)
helpBtn:SetScript("OnClick", function()
  NS.ShowCopyPopup("Copy URL (GitHub)", GITHUB_URL)
end)

-- Track buttons in order for wrapping
NS.TopBarButtons = { search, addBtn, editBtn, delBtn, gearBtn, helpBtn }

-- Layout widths (after creation, so buttons have sizes)
C_Timer.After(0, function()
  -- Give the search box a reasonable width relative to frame
  local w = main:GetWidth() - (28+28+32+28) - 5*6 -- buttons + gaps
  if w < 140 then w = 140 end
  search:SetWidth(w)
  ReflowRow(NS.TopBar, NS.TopBarButtons, 6, 6)
end)

main:SetScript("OnSizeChanged", function()
  -- Recompute search width on resize
  local w = main:GetWidth() - (28+28+32+28) - 5*6
  if w < 140 then w = 140 end
  search:SetWidth(w)
  ReflowRow(NS.TopBar, NS.TopBarButtons, 6, 6)
  -- Re-anchor scroll container if needed
  if NS.ScrollContainer then
    NS.ScrollContainer:ClearAllPoints()
    NS.ScrollContainer:SetPoint("TOPLEFT", NS.TopBar, "BOTTOMLEFT", 0, -8)
    NS.ScrollContainer:SetPoint("TOPRIGHT", main, "TOPRIGHT", -PAD, -8)
    NS.ScrollContainer:SetPoint("BOTTOMLEFT", main, "BOTTOMLEFT", PAD, PAD + BOTTOM_BAR_H)
  end
end)

----------------------------------------------------------------------
-- Scrollable list (selection, right-click context)
----------------------------------------------------------------------
NS.ScrollContainer = CreateFrame("Frame", nil, main)
NS.ScrollContainer:SetPoint("TOPLEFT", NS.TopBar, "BOTTOMLEFT", 0, -8)
NS.ScrollContainer:SetPoint("TOPRIGHT", main, "TOPRIGHT", -PAD, -8)
NS.ScrollContainer:SetPoint("BOTTOMLEFT", main, "BOTTOMLEFT", PAD, PAD + BOTTOM_BAR_H)

local scroll = CreateFrame("ScrollFrame", "WCL_Scroll", NS.ScrollContainer, "FauxScrollFrameTemplate")
scroll:SetPoint("TOPLEFT") scroll:SetPoint("BOTTOMRIGHT")
local ROW_H, VISIBLE_ROWS = 22, 20
local rows, selIndex = {}, nil

local function MakeRow(i)
  local r = CreateFrame("Button", nil, NS.ScrollContainer)
  r:SetHeight(ROW_H)
  r:SetPoint("LEFT", 0, 0) r:SetPoint("RIGHT", 0, 0)
  if i == 1 then r:SetPoint("TOPLEFT", 0, 0) else r:SetPoint("TOPLEFT", rows[i-1], "BOTTOMLEFT", 0, -2) end
  r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  r.text:SetPoint("LEFT", 6, 0)
  r.bg = r:CreateTexture(nil, "BACKGROUND")
  r.bg:SetAllPoints(r)
  r.bg:SetColorTexture(1,1,1,0) -- transparent; show highlight on selection
  r:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
  r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  r:SetScript("OnClick", function(self, btn)
    local idx = self._index
    if btn == "RightButton" then
      selIndex = idx
      ToggleDropDownMenu(1, nil, NS.ContextMenu, self, 0, 0)
      return
    end
    selIndex = (selIndex == idx) and nil or idx
    NS.RefreshList(false)
  end)
  return r
end

for i=1,VISIBLE_ROWS do rows[i]=MakeRow(i) end

-- Context menu (EasyMenu) – mutually exclusive: hide others before showing
NS.ContextMenu = CreateFrame("Frame", "WCL_Context", UIParent, "UIDropDownMenuTemplate")
local function Menu_Init(self, level)
  if not level then return end
  local info = UIDropDownMenu_CreateInfo()
  if level == 1 then
    info.text = "Make Daily"; info.func = function() NS.MakeSelected("daily") end; UIDropDownMenu_AddButton(info, level)
    info.text = "Make Weekly"; info.func = function() NS.MakeSelected("weekly") end; UIDropDownMenu_AddButton(info, level)
    info.text = "Delete"; info.func = function() NS.DeleteSelected() end; UIDropDownMenu_AddButton(info, level)
  end
end
UIDropDownMenu_Initialize(NS.ContextMenu, Menu_Init, "MENU")
hooksecurefunc("ToggleDropDownMenu", function() NS.OpenExclusive("context", true) end)
NS.RegisterExclusive("context", NS.ContextMenu)

----------------------------------------------------------------------
-- Bottom bar: filters, zone button (opens map), refresh
----------------------------------------------------------------------
local bottom = CreateFrame("Frame", nil, main)
bottom:SetPoint("BOTTOMLEFT", main, "BOTTOMLEFT", PAD, PAD)
bottom:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -PAD, PAD)
bottom:SetHeight(BOTTOM_BAR_H)

local filter = CreateFrame("Frame", nil, bottom)
filter:SetPoint("LEFT") filter:SetSize(220, 24)

local function Radio(parent, text)
  local b = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
  b.Text:SetText(text)
  return b
end

local allRB = Radio(filter, "All")
local dailyRB = Radio(filter, "Daily")
local weeklyRB = Radio(filter, "Weekly")

allRB:SetPoint("LEFT", 0, 0)
dailyRB:SetPoint("LEFT", allRB, "RIGHT", 16, 0)
weeklyRB:SetPoint("LEFT", dailyRB, "RIGHT", 16, 0)

local function SetFilter(kind)
  NS.filter = kind
  allRB:SetChecked(kind=="all")
  dailyRB:SetChecked(kind=="daily")
  weeklyRB:SetChecked(kind=="weekly")
  NS.RefreshList(true)
end
allRB:SetScript("OnClick", function() SetFilter("all") end)
dailyRB:SetScript("OnClick", function() SetFilter("daily") end)
weeklyRB:SetScript("OnClick", function() SetFilter("weekly") end)
SetFilter("all")

-- Zone button
local zoneBtn = CreateFrame("Button", nil, bottom, "UIPanelButtonTemplate")
zoneBtn:SetSize(120, 22)
zoneBtn:SetPoint("CENTER")
zoneBtn:SetText("Zone: Unknown")
zoneBtn:SetScript("OnClick", function()
  if WorldMapFrame and WorldMapFrame.Show then OpenWorldMap() else ToggleWorldMap() end
end)

-- Refresh button
local refreshBtn = CreateFrame("Button", nil, bottom, "UIPanelButtonTemplate")
refreshBtn:SetSize(84, 22)
refreshBtn:SetPoint("RIGHT")
refreshBtn:SetText("Refresh")
refreshBtn:SetScript("OnClick", function() NS.RefreshList(true) end)

----------------------------------------------------------------------
-- Help panel (opaque; anchored to window; ESC closes)
----------------------------------------------------------------------
local help = CreateFrame("Frame", nil, main, BackdropTemplateMixin and "BackdropTemplate")
help:SetPoint("TOPLEFT", main, "TOPLEFT", PAD, -60)
help:SetPoint("TOPRIGHT", main, "TOPRIGHT", -PAD, -60)
help:SetHeight(180)
help:SetBackdrop(bd)
help:SetBackdropColor(0,0,0,0.85)
help:Hide()

help.text = help:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
help.text:SetPoint("TOPLEFT", 12, -10)
help.text:SetJustifyH("LEFT")
help.text:SetText("WinterChecklist Help:\n - Left-click to select; Right-click for actions.\n - /wcl add: add a daily item; /wcl addw: weekly.\n - Import/Export via buttons in Options/gear.")

help:SetPropagateKeyboardInput(true)
help:SetScript("OnKeyDown", function(self, key) if key=="ESCAPE" then self:Hide() end end)

NS.RegisterExclusive("help", help)

----------------------------------------------------------------------
-- Import / Export dialogs (mutually exclusive; width clamp ≤ main)
----------------------------------------------------------------------
local function MakeDialog(name, height)
  local f = CreateFrame("Frame", name, main, BackdropTemplateMixin and "BackdropTemplate")
  f:SetPoint("TOPLEFT", main, "TOPLEFT", PAD, -60)
  f:SetBackdrop(bd)
  f:SetBackdropColor(0,0,0,0.9)
  f:SetHeight(height or 220)
  f:SetWidth(main:GetWidth() - PAD*2) -- initial width; clamped on show
  f:Hide()
  f.eb = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  f.eb:SetAutoFocus(false) f.eb:ClearFocus()
  f.eb:SetMultiLine(true)
  f.eb:SetPoint("TOPLEFT", 10, -10)
  f.eb:SetPoint("BOTTOMRIGHT", -10, 10)
  f.eb:SetText("")
  f:SetPropagateKeyboardInput(true)
  f:SetScript("OnKeyDown", function(self, key) if key=="ESCAPE" then self:Hide() end end)
  return f
end

local function ClampToMainWidth(child)
  local mw = main:GetWidth() or 420
  local maxW = mw - (PAD * 2)
  child:SetClampedToScreen(true)
  child:SetClampRectInsets(8, -8, -8, 8)
  if child:GetWidth() > maxW then child:SetWidth(maxW) end
end

local importDialog = MakeDialog("WCL_Import")
local exportDialog = MakeDialog("WCL_Export")
importDialog:HookScript("OnShow", ClampToMainWidth)
exportDialog:HookScript("OnShow", ClampToMainWidth)
NS.RegisterExclusive("import", importDialog)
NS.RegisterExclusive("export", exportDialog)

----------------------------------------------------------------------
-- Options panel (spacing; mini copy-URL buttons use StaticPopup)
----------------------------------------------------------------------
local options = CreateFrame("Frame", "WCL_Options", main, BackdropTemplateMixin and "BackdropTemplate")
options:SetPoint("TOPLEFT", main, "TOPLEFT", PAD, -60)
options:SetPoint("TOPRIGHT", main, "TOPRIGHT", -PAD, -60)
options:SetHeight(160)
options:SetBackdrop(bd)
options:SetBackdropColor(0,0,0,0.85)
options:Hide()
NS.RegisterExclusive("options", options)

local inner = CreateFrame("Frame", nil, options)
inner:SetPoint("TOPLEFT", 12, -12)
inner:SetPoint("BOTTOMRIGHT", -12, 12)

local r1 = CreateFrame("Frame", nil, inner); r1:SetPoint("TOPLEFT"); r1:SetSize(10, 28)
local r2 = CreateFrame("Frame", nil, inner); r2:SetPoint("TOPLEFT", r1, "BOTTOMLEFT", 0, -10); r2:SetSize(10, 28)

local cGit = CreateFrame("Button", nil, r1, "UIPanelButtonTemplate")
cGit:SetText("Copy GitHub URL"); cGit:SetSize(150, 22)
cGit:SetPoint("LEFT")
cGit:SetScript("OnClick", function() NS.ShowCopyPopup("Copy URL (GitHub)", GITHUB_URL) end)

local cCurse = CreateFrame("Button", nil, r1, "UIPanelButtonTemplate")
cCurse:SetText("Copy CurseForge URL"); cCurse:SetSize(170, 22)
cCurse:SetPoint("LEFT", cGit, "RIGHT", 8, 0)
cCurse:SetScript("OnClick", function() NS.ShowCopyPopup("Copy URL (CurseForge)", CURSE_URL) end)

local miniMapCB = CreateFrame("CheckButton", nil, r2, "UICheckButtonTemplate")
miniMapCB.text:SetText("Show minimap button")
miniMapCB:SetPoint("LEFT")
miniMapCB:SetScript("OnClick", function(self)
  WinterChecklistDB.opts.minimap = self:GetChecked() and true or false
  NS.UpdateMinimapButton()
end)

----------------------------------------------------------------------
-- Data operations: add/edit/delete, daily/weekly toggle, filtering
----------------------------------------------------------------------
local function VisibleItems()
  local out, q = {}, STrim(NS.searchText or "")
  local f = NS.filter or "all"
  for i, it in ipairs(WinterChecklistDB.items) do
    local ok = (f=="all") or (f=="daily" and it.kind=="daily") or (f=="weekly" and it.kind=="weekly")
    if ok then
      if q == "" or (it.text and it.text:lower():find(q:lower(), 1, true)) then
        out[#out+1] = { index=i, text=it.text, kind=it.kind, done=it.done }
      end
    end
  end
  return out
end

function NS.RefreshList(recount)
  local items = VisibleItems()
  local total, done = #items, 0
  for _, it in ipairs(items) do if it.done then done = done + 1 end end
  if recount then UpdateTitle(done, total) end

  FauxScrollFrame_Update(scroll, #items, VISIBLE_ROWS, ROW_H)
  local offset = FauxScrollFrame_GetOffset(scroll)
  for i=1,VISIBLE_ROWS do
    local row = rows[i]
    local idx = i + offset
    local data = items[idx]
    row._index = data and data.index or nil
    row.text:SetText(data and data.text or "")
    if selIndex and data and (data.index == selIndex) then
      row.bg:SetColorTexture(0.2,0.6,1,0.15)
    else
      row.bg:SetColorTexture(1,1,1,0)
    end
    row:SetShown(data ~= nil)
  end
end
scroll:SetScript("OnVerticalScroll", function(self, delta)
  FauxScrollFrame_OnVerticalScroll(self, delta, ROW_H, NS.RefreshList)
end)

function NS.AddItem(kind, text)
  local it = { kind = kind or "daily", text = STrim(text or "New item"), done = false }
  table.insert(WinterChecklistDB.items, it)
  NS.RefreshList(true)
end

function NS.EditSelected()
  if not selIndex then return end
  local it = WinterChecklistDB.items[selIndex]; if not it then return end
  StaticPopupDialogs["WCL_EDIT"] = {
    text = "Edit item text",
    button1 = OKAY, button2 = CANCEL,
    hasEditBox = true, OnShow = function(self) self.editBox:SetText(it.text or "") self.editBox:HighlightText() end,
    OnAccept = function(self) it.text = STrim(self.editBox:GetText()) NS.RefreshList(true) end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
  }
  StaticPopup_Show("WCL_EDIT")
end

function NS.DeleteSelected()
  if not selIndex then return end
  table.remove(WinterChecklistDB.items, selIndex)
  selIndex = nil
  NS.RefreshList(true)
end

function NS.MakeSelected(kind)
  if not selIndex then return end
  local it = WinterChecklistDB.items[selIndex]; if not it then return end
  it.kind = kind
  NS.RefreshList(true)
end

----------------------------------------------------------------------
-- Import/Export logic
----------------------------------------------------------------------
local function ConfirmReplace(cb)
  StaticPopupDialogs["WCL_IMPORT_CONFIRM"] = {
    text = "Import will replace ALL current items. Continue?",
    button1 = YES, button2 = NO, OnAccept = cb,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
  }
  StaticPopup_Show("WCL_IMPORT_CONFIRM")
end

function NS.DoExport()
  local t = {}
  for _, it in ipairs(WinterChecklistDB.items) do
    t[#t+1] = ("%s\t%s\t%s"):format(it.kind or "daily", it.done and "1" or "0", it.text or "")
  end
  exportDialog.eb:SetText(table.concat(t, "\n"))
  NS.OpenExclusive("export", true)
end

function NS.DoImport()
  local raw = importDialog.eb:GetText() or ""
  local lines = {}
  for line in raw:gmatch("[^\r\n]+") do lines[#lines+1] = line end
  local new = {}
  for _, line in ipairs(lines) do
    local kind, done, text = line:match("^(%w+)%s+([01])%s+(.*)$")
    if kind and text then new[#new+1] = { kind=kind, done=(done=="1"), text=text } end
  end
  WinterChecklistDB.items = new
  NS.RefreshList(true)
  NS.OpenExclusive("import", false)
end

----------------------------------------------------------------------
-- Buttons wiring (+ / E / - and import/export/help)
----------------------------------------------------------------------
addBtn:SetScript("OnClick", function() NS.AddItem("daily", "New item") end)
editBtn:SetScript("OnClick", NS.EditSelected)
delBtn:SetScript("OnClick", NS.DeleteSelected)

-- Show Options (where mini copy buttons live)
gearBtn:HookScript("OnClick", function()
  NS.OpenExclusive("options", true)
end)
helpBtn:HookScript("OnClick", function()
  NS.OpenExclusive("help", true)
end)

-- Example Import/Export triggers (you can add small buttons somewhere else if desired)
options:EnableMouse(true)
options:SetScript("OnMouseDown", function(self, btn)
  if btn == "RightButton" then
    -- Right-click on options to open export; left-click import (simple gesture)
    NS.OpenExclusive("export", true)
  else
    NS.OpenExclusive("import", true)
  end
end)

----------------------------------------------------------------------
-- Minimap button (simple round masked check icon)
----------------------------------------------------------------------
local ldb, icon
local function EnsureLDB()
  if ldb then return end
  local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
  if not LDB then return end
  ldb = LDB:NewDataObject("WinterChecklist", {
    type = "launcher",
    icon = 134400, -- generic check icon
    OnClick = function(_, button)
      if button == "LeftButton" then if main:IsShown() then main:Hide() else main:Show() end
      else NS.RefreshList(true) end
    end,
    OnTooltipShow = function(tt) tt:AddLine("WinterChecklist") tt:AddLine("Left: Toggle window") tt:AddLine("Right: Refresh") end,
  })
  local MB = LibStub and LibStub("LibDBIcon-1.0", true)
  if MB then
    icon = MB
    WinterChecklistDB.opts.minimap = WinterChecklistDB.opts.minimap ~= false
    MB:Register("WinterChecklist", ldb, { hide = not WinterChecklistDB.opts.minimap })
  end
end
function NS.UpdateMinimapButton()
  EnsureLDB()
  if not icon then return end
  local hide = not (WinterChecklistDB.opts.minimap ~= false)
  icon:Hide("WinterChecklist"); if not hide then icon:Show("WinterChecklist") end
end

----------------------------------------------------------------------
-- Slash commands (/wcl, /wcl add, /wcl addw, /wcl minimap)
----------------------------------------------------------------------
SLASH_WCL1 = "/wcl"
SlashCmdList["WCL"] = function(msg)
  msg = STrim(msg or "")
  if msg == "add" then NS.AddItem("daily", "New item")
  elseif msg == "addw" then NS.AddItem("weekly", "New weekly")
  elseif msg == "minimap" then
    WinterChecklistDB.opts.minimap = not (WinterChecklistDB.opts.minimap ~= false)
    NS.UpdateMinimapButton()
    Print("Minimap "..(WinterChecklistDB.opts.minimap and "enabled" or "disabled"))
  else
    if main:IsShown() then main:Hide() else main:Show() end
  end
  NS.RefreshList(true)
end

----------------------------------------------------------------------
-- Zone name updater (title button text)
----------------------------------------------------------------------
local function UpdateZone()
  local sub = GetSubZoneText() or ""
  local zone = GetZoneText() or ""
  local label = IsEmpty(sub) and zone or (sub.." - "..zone)
  zoneBtn:SetText("Zone: "..(label ~= "" and label or "Unknown"))
end
local zoneEvents = CreateFrame("Frame")
zoneEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneEvents:RegisterEvent("ZONE_CHANGED")
zoneEvents:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneEvents:RegisterEvent("ZONE_CHANGED_INDOORS")
zoneEvents:SetScript("OnEvent", function() UpdateZone() end)

----------------------------------------------------------------------
-- Profile snapshots (account-wide) + copy-from-profile
----------------------------------------------------------------------
function NS.SaveProfile(name)
  if IsEmpty(name) then return end
  WinterChecklistAccountDB.profiles[name] = Clone(WinterChecklistDB)
  Print("Saved profile: "..name)
end

function NS.LoadProfile(name)
  local p = WinterChecklistAccountDB.profiles[name]
  if not p then Print("No profile named "..name) return end
  WinterChecklistDB = Clone(p)
  NS.RefreshList(true)
  Print("Loaded profile: "..name)
end

----------------------------------------------------------------------
-- Init
----------------------------------------------------------------------
local function OnPlayerLogin()
  EnsureLDB()
  NS.UpdateMinimapButton()
  UpdateZone()
  NS.RefreshList(true)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", OnPlayerLogin)

-- ESC closes topmost exclusive panel (or main if none)
main:SetPropagateKeyboardInput(true)
main:SetScript("OnKeyDown", function(self, key)
  if key == "ESCAPE" then
    local anyShown = false
    for _, frm in pairs(NS._openPanels) do if frm and frm:IsShown() then anyShown = true; frm:Hide() end end
    if not anyShown then self:Hide() end
  end
end)

-- Public API (minimal)
NS.RefreshList = NS.RefreshList
NS.AddItem = NS.AddItem
NS.EditSelected = NS.EditSelected
NS.DeleteSelected = NS.DeleteSelected
NS.MakeSelected = NS.MakeSelected
