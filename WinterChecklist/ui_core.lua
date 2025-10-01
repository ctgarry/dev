-- ui_core.lua
-- Purpose: Main checklist window (layout, search/filter, rows, selection, keyboard).
-- Scope: UI only. No compat logic (use compat.lua shims like NS.OpenWorldMap). Strict localization via T().
-- Notes: No globals. All user-facing strings go through T(KEY). No magic numbers — centralize in C.

local ADDON, NS = ...

-- ===== Constants (avoid magic numbers) =====
local C = {
  -- Layout paddings & sizes
  PAD                 = 12,
  TOP_BAR_H           = 48,
  TITLE_OFFSET_Y      = -30,
  LIST_TOP_OFFSET     = 82,     -- distance from frame top to list top
  BOTTOM_BAR_H        = 72,
  ROW_H               = 24,
  ROW_BG              = {0, 0, 0, 0.12},
  ROW_HILITE          = {0.2, 0.4, 0.8, 0.25},

  -- Window bounds & resize
  MIN_W               = 360, MIN_H = 320,
  MAX_W               = 1100, MAX_H = 1000,
  RESIZE_GRIP         = 16,
  GRIP_OFFSET_X       = -3,
  GRIP_OFFSET_Y       =  3,

  -- Buttons & inputs
  BTN_H               = 22,
  BTN_W_MINI          = 28,
  BTN_W_STD           = 90,
  BTN_GAP             = 6,
  SEARCH_H            = 22,

  -- Scrollframe margins
  SCROLL_L            =  4,
  SCROLL_T            = -4,
  SCROLL_R            = -28,
  SCROLL_B            =  4,

  -- Prompt dialog
  PROMPT_W            = 360,
  PROMPT_H            = 140,
  PROMPT_OFFSET_Y     = 30,
  PROMPT_EDIT_W       = 320,
  PROMPT_EDIT_H       = 24,
  PROMPT_BTN_INSET    = 10,

  -- Context menu
  CTX_W               = 160,
  CTX_H               = 110,
  CTX_BTN_W           = 140,
  CTX_BTN_H           = 22,
  CTX_OFFSET_Y        = 6,
  CTX_BTN_1_Y         = -12,
  CTX_BTN_STEP        = 24,     -- vertical spacing between buttons

  -- Radios
  RADIO_ALL_X         = 0,
  RADIO_DAILY_X       = 70,
  RADIO_WEEKLY_X      = 150,

  -- Default window state (persisted in DB.window)
  DEFAULT_W           = 460,
  DEFAULT_H           = 500,
  DEFAULT_X           = 0,
  DEFAULT_Y           = 0,
}

-- ===== Strict localization helper (assert on missing keys) =====
local function T(key)
  local L = NS.L or {}
  assert(L[key], "Missing locale key: " .. tostring(key))
  return L[key]
end

-- ===== Localize hot globals =====
local CreateFrame   = CreateFrame
local UIParent      = UIParent
local unpack        = unpack
local ipairs        = ipairs
local t_insert      = table.insert

-- ===== Shared UI namespace =====
NS.UI = NS.UI or { controls = {} }
local UI = NS.UI

-- ===== Helpers =====
local function SafeSetResizeBounds(frame, minW, minH, maxW, maxH)
  if frame.SetResizeBounds then frame:SetResizeBounds(minW, minH, maxW, maxH)
  elseif frame.SetMinResize then frame:SetMinResize(minW, minH) end
end

local function PersistWindowSize(frame)
  local d = NS.EnsureDB()
  d.window = d.window or { w = C.DEFAULT_W, h = C.DEFAULT_H, x = C.DEFAULT_X, y = C.DEFAULT_Y, shown = UI.frame and UI.frame:IsShown() or true }
  d.window.w, d.window.h = frame:GetSize()
end

local function PersistWindowPos(frame)
  local px, py = UIParent:GetCenter()
  local x,  y  = frame:GetCenter()
  local d = NS.EnsureDB()
  d.window = d.window or { w = C.DEFAULT_W, h = C.DEFAULT_H, x = C.DEFAULT_X, y = C.DEFAULT_Y, shown = UI.frame and UI.frame:IsShown() or true }
  d.window.x, d.window.y = x - px, y - py
end

local function CreateResizeGrip(frame)
  local grip = CreateFrame("Button", nil, frame)
  grip:SetPoint("BOTTOMRIGHT", C.GRIP_OFFSET_X, C.GRIP_OFFSET_Y)
  grip:SetSize(C.RESIZE_GRIP, C.RESIZE_GRIP)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  frame:SetResizable(true)
  grip:SetScript("OnMouseDown", function(self) self:GetParent():StartSizing("BOTTOMRIGHT") end)
  grip:SetScript("OnMouseUp", function(self) local p = self:GetParent(); p:StopMovingOrSizing(); PersistWindowSize(p) end)
end

-- Forward declare
local ShowContextForRow

-- Title count (TITLE (done/visible))
local function UpdateTitleCount()
  if not UI.frame or not UI.frame.TitleText then return end
  local vis, done = 0, 0
  for _, t in ipairs(UI.filtered or {}) do
    vis = vis + 1; if t.completed then done = done + 1 end
  end
  UI.frame.TitleText:SetText( ("%s (%d/%d)"):format(T("TITLE"), done, vis) )
end

-- Build the rows under the scroll child
local function buildRows(tasks)
  if not UI.listParent then return end

  -- clear existing rows
  if UI._rows then for _, r in ipairs(UI._rows) do r:Hide() end end
  UI._rows = {}

  local parent = UI.listParent
  local y = -4

  local function makeRow(i, t)
    local r = CreateFrame("Button", nil, parent, "BackdropTemplate")
    r:SetSize(parent:GetWidth() - 8, C.ROW_H)
    r:SetPoint("TOPLEFT", 0, y)
    r:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8x8" })
    r:SetBackdropColor(unpack(C.ROW_BG))

    local cb = CreateFrame("CheckButton", nil, r, "ChatConfigCheckButtonTemplate")
    cb:SetPoint("LEFT", 4, 0)
    cb:SetChecked(t.completed and true or false)
    cb:SetScript("OnClick", function(self)
      t.completed = self:GetChecked() and true or false
      if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
      UpdateTitleCount()
    end)

    local fs = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    fs:SetJustifyH("LEFT")
    fs:SetWidth(r:GetWidth() - 48)
    fs:SetText(t.text or "")

    r:SetScript("OnClick", function(self, btn)
      UI.lastClickedIndex = i
      -- highlight selection
      for _, rr in ipairs(UI._rows or {}) do rr:SetBackdropColor(unpack(C.ROW_BG)) end
      self:SetBackdropColor(unpack(C.ROW_HILITE))
      if btn == "RightButton" and ShowContextForRow then
        ShowContextForRow(parent, r, t)
      end
    end)
    r:RegisterForClicks("LeftButtonUp","RightButtonUp")

    return r
  end

  for i, t in ipairs(tasks or {}) do
    local row = makeRow(i, t)
    if UI.lastClickedIndex == i then row:SetBackdropColor(unpack(C.ROW_HILITE)) end
    t_insert(UI._rows, row)
    y = y - (C.ROW_H + 2)
  end
  parent:SetSize(parent:GetWidth(), math.max(1, -y))
  UpdateTitleCount()
end

-- ===== Main frame constructor =====
local function CreateMainFrame(db)
  if UI.frame then return end

  local f = CreateFrame("Frame", "WinterChecklistFrame", UIParent, "BasicFrameTemplateWithInset")
  f:SetClampedToScreen(true)
  SafeSetResizeBounds(f, C.MIN_W, C.MIN_H, C.MAX_W, C.MAX_H)
  f:SetPoint("CENTER", UIParent, "CENTER", db.window.x or C.DEFAULT_X, db.window.y or C.DEFAULT_Y)
  f:SetSize(db.window.w or C.DEFAULT_W, db.window.h or C.DEFAULT_H)
  f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); PersistWindowPos(self) end)
  f:SetScript("OnSizeChanged", function(self) PersistWindowSize(self) end)
  if f.TitleText then f.TitleText:SetText(T("TITLE")) end
  CreateResizeGrip(f)

  -- Esc/Delete shortcuts (Esc closes, Delete removes selected row)
  f:EnableKeyboard(true)
  f:SetPropagateKeyboardInput(true)
  f:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
      self:Hide()
      local d = NS.EnsureDB(); d.window.shown = false
    elseif key == "DELETE" then
      local idx = UI.lastClickedIndex
      if idx and UI.filtered and UI.filtered[idx] then
        local toDelete = UI.filtered[idx]
        local d = NS.EnsureDB()
        for i,t in ipairs(d.tasks) do if t == toDelete then table.remove(d.tasks, i); break end end
        UI.lastClickedIndex = nil
        if NS.RefreshUI then NS.RefreshUI() end
        if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
      end
    end
  end)

  UI.frame = f

  -- ===== Top bar =====
  local top = CreateFrame("Frame", nil, f)
  top:SetPoint("TOPLEFT",  f, "TOPLEFT",  C.PAD, C.TITLE_OFFSET_Y)
  top:SetPoint("TOPRIGHT", f, "TOPRIGHT", -C.PAD, C.TITLE_OFFSET_Y)
  top:SetHeight(C.TOP_BAR_H)

  local function MakeBtn(parent, label, w)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w or C.BTN_W_MINI, C.BTN_H)
    b:SetText(label)
    return b
  end

  -- Search (top)
  local searchTop = CreateFrame("EditBox", nil, top, "InputBoxTemplate")
  searchTop:SetAutoFocus(false)
  searchTop:SetHeight(C.SEARCH_H)
  searchTop:SetText(db.search or "")
  UI.controls.searchTop = searchTop

  -- Buttons
  local bAdd  = MakeBtn(top, T("BTN_ADD"))
  local bEdit = MakeBtn(top, T("BTN_EDIT"))
  local bDel  = MakeBtn(top, T("BTN_DELETE"))
  local bGear = (NS.SmallIconBtn and NS.SmallIconBtn(top, "gear", T("BTN_GEAR_TIP"))) or MakeBtn(top, "⚙", C.BTN_W_MINI)
  local bHelp = MakeBtn(top, T("BTN_HELP"))

  -- Dynamic layout: right-aligned buttons, search fills the rest
  local function RelayoutTop()
    local w = top:GetWidth()
    local pad = C.BTN_GAP
    local buttons = { bHelp, bGear, bDel, bEdit, bAdd } -- laid out right->left
    local total = 0
    for _,b in ipairs(buttons) do total = total + b:GetWidth() end
    total = total + pad * (#buttons - 1)

    for _,b in ipairs(buttons) do b:ClearAllPoints() end
    searchTop:ClearAllPoints()

    local minSearch = 160
    if w >= total + minSearch then
      local x = w
      for _, b in ipairs(buttons) do
        x = x - b:GetWidth()
        b:SetPoint("TOPLEFT", top, "TOPLEFT", x, 0)
        x = x - pad
      end
      searchTop:SetPoint("LEFT",  top, "LEFT",  0, 0)
      searchTop:SetPoint("RIGHT", buttons[#buttons], "LEFT", -pad, 0)
      searchTop:SetHeight(C.SEARCH_H)
    else
      searchTop:SetPoint("TOPLEFT",  top, "TOPLEFT", 0, 0)
      searchTop:SetPoint("TOPRIGHT", top, "TOPRIGHT", 0, 0)
      searchTop:SetHeight(C.SEARCH_H)
      local x = 0
      for _, b in ipairs({ bAdd, bEdit, bDel, bGear, bHelp }) do
        b:SetPoint("TOPLEFT", top, "TOPLEFT", x, -28) -- row 2
        x = x + b:GetWidth() + pad
      end
    end
  end
  if C_Timer and C_Timer.After then C_Timer.After(0, RelayoutTop) end
  top:SetScript("OnSizeChanged", RelayoutTop)

  searchTop:SetScript("OnTextChanged", function(self)
    local d = NS.EnsureDB()
    d.search = self:GetText() or ""
    if NS.RefreshUI then NS.RefreshUI() end
    if UI.controls.searchBottom and UI.controls.searchBottom:GetText() ~= d.search then
      UI.controls.searchBottom:SetText(d.search)
    end
  end)

  -- Add/Edit/Delete behavior
  local function DefaultFreq()
    local d = NS.EnsureDB()
    return (d.filterMode == "WEEKLY") and "weekly" or ((d.filterMode == "DAILY") and "daily" or "daily")
  end

  local function SimplePrompt(parent, title, initialText, onOK)
    if NS.HideAllPopups then NS.HideAllPopups() end
    local p = CreateFrame("Frame", nil, parent, "BasicFrameTemplateWithInset")
    p:SetSize(C.PROMPT_W, C.PROMPT_H)
    p:SetPoint("CENTER", parent, "CENTER", 0, C.PROMPT_OFFSET_Y)
    p:EnableMouse(true); p:SetMovable(true); p:RegisterForDrag("LeftButton")
    p:SetScript("OnDragStart", p.StartMoving); p:SetScript("OnDragStop", p.StopMovingOrSizing)
    if p.TitleText then p.TitleText:SetText(title) end

    local eb = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
    eb:SetAutoFocus(true)
    eb:SetSize(C.PROMPT_EDIT_W, C.PROMPT_EDIT_H)
    eb:SetPoint("TOP", p, "TOP", 0, -40)
    eb:SetText(initialText or "")
    eb:HighlightText()

    local ok = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    ok:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -C.PROMPT_BTN_INSET, C.PROMPT_BTN_INSET-2)
    ok:SetSize(C.BTN_W_STD, C.BTN_H)
    ok:SetText(T("DLG_OK"))

    local cancel = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    cancel:SetPoint("RIGHT", ok, "LEFT", -C.BTN_GAP, 0)
    cancel:SetSize(C.BTN_W_STD, C.BTN_H)
    cancel:SetText(T("DLG_CANCEL"))

    ok:SetScript("OnClick", function()
      local s = eb:GetText() or ""
      local t = NS.STrim and NS.STrim(s) or s
      if (NS.IsEmpty and NS.IsEmpty(t)) or t == "" then
        if NS.Print then NS.Print(T("DLG_ENTER_TEXT")) end
        return
      end
      if onOK then onOK(t) end
      p:Hide(); p:SetParent(nil)
    end)
    cancel:SetScript("OnClick", function() p:Hide() end)
    eb:SetScript("OnEnterPressed", ok:GetScript("OnClick"))
    eb:SetScript("OnEscapePressed", cancel:GetScript("OnClick"))
    p:EnableKeyboard(true)
    p:SetScript("OnKeyDown", function(self, key) if key == "ESCAPE" then cancel:Click() end end)
  end

  bAdd:SetScript("OnClick", function()
    SimplePrompt(f, T("DLG_ADD_TASK"), "", function(text)
      local d = NS.EnsureDB()
      t_insert(d.tasks, { text = text, frequency = DefaultFreq(), completed = false })
      if NS.RefreshUI then NS.RefreshUI() end
      if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
    end)
  end)

  bEdit:SetScript("OnClick", function()
    local idx = UI.lastClickedIndex
    if not idx or not UI.filtered or not UI.filtered[idx] then
      if NS.Print then NS.Print(T("MSG_SELECT_TO_EDIT")) end
      return
    end
    local task = UI.filtered[idx]
    SimplePrompt(f, T("DLG_EDIT_TASK"), task.text or "", function(text)
      task.text = text
      if NS.RefreshUI then NS.RefreshUI() end
      if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
    end)
  end)

  bDel:SetScript("OnClick", function()
    local idx = UI.lastClickedIndex
    if not idx or not UI.filtered or not UI.filtered[idx] then
      if NS.Print then NS.Print(T("MSG_SELECT_TO_DELETE")) end
      return
    end
    local toDelete = UI.filtered[idx]
    local d = NS.EnsureDB()
    for i,t in ipairs(d.tasks) do if t == toDelete then table.remove(d.tasks, i); break end end
    UI.lastClickedIndex = nil
    if NS.RefreshUI then NS.RefreshUI() end
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
  end)

  bHelp:SetScript("OnClick", function() if NS.ToggleHelp then NS.ToggleHelp(f) end end)
  bGear:SetScript("OnClick", function() if NS.ShowImportExport then NS.ShowImportExport(f) end end)

  -- ===== List area =====
  local listBG = CreateFrame("Frame", nil, f, "InsetFrameTemplate3")
  listBG:SetPoint("TOPLEFT",     f, "TOPLEFT",     C.PAD, -C.LIST_TOP_OFFSET)
  listBG:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -C.PAD, C.BOTTOM_BAR_H)

  local scroll = CreateFrame("ScrollFrame", nil, listBG, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",     listBG, "TOPLEFT",     C.SCROLL_L, C.SCROLL_T)
  scroll:SetPoint("BOTTOMRIGHT", listBG, "BOTTOMRIGHT", C.SCROLL_R, C.SCROLL_B)
  local scrollChild = CreateFrame("Frame", nil, scroll)
  scroll:SetScrollChild(scrollChild)
  scrollChild:SetSize(1, 1)
  UI.listParent = scrollChild

  -- Keep row widths correct when the frame resizes
  local function _refreshRowsOnResize()
    if UI.filtered then buildRows(UI.filtered) end
  end
  listBG:SetScript("OnSizeChanged", _refreshRowsOnResize)

  -- ===== Bottom bar =====
  local bottom = CreateFrame("Frame", nil, f)
  bottom:SetPoint("LEFT",   f, "LEFT",   C.PAD, 0)
  bottom:SetPoint("RIGHT",  f, "RIGHT", -C.PAD, 0)
  bottom:SetPoint("BOTTOM", f, "BOTTOM", 0, C.PAD/2)
  bottom:SetHeight(C.BOTTOM_BAR_H - C.PAD/2)

  -- Filter label + bottom search
  local filterLabel = bottom:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  filterLabel:SetPoint("BOTTOMLEFT", bottom, "BOTTOMLEFT", 0, 44)
  filterLabel:SetText(T("FILTER_LABEL"))

  local searchBottom = CreateFrame("EditBox", nil, bottom, "InputBoxTemplate")
  searchBottom:SetAutoFocus(false)
  searchBottom:SetHeight(C.SEARCH_H)
  searchBottom:SetPoint("LEFT",  filterLabel, "RIGHT", C.BTN_GAP, 0)
  searchBottom:SetPoint("RIGHT", bottom, "RIGHT", 0, 44)
  searchBottom:SetText(db.search or "")
  UI.controls.searchBottom = searchBottom

  searchBottom:SetScript("OnTextChanged", function(self)
    local d = NS.EnsureDB()
    d.search = self:GetText() or ""
    if NS.RefreshUI then NS.RefreshUI() end
    if UI.controls.searchTop and UI.controls.searchTop:GetText() ~= d.search then
      UI.controls.searchTop:SetText(d.search)
    end
  end)

  -- Radios
  local radios = CreateFrame("Frame", nil, bottom)
  radios:SetSize(260, 22)
  radios:SetPoint("BOTTOMLEFT", bottom, "BOTTOMLEFT", 0, 22)

  local function makeRadio(parent, label, x, mode)
    local r = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
    r:SetPoint("LEFT", parent, "LEFT", x, 0)
    local lab = r.Text or r.text or _G[(r:GetName() or "") .. "Text"]
    if not lab then lab = r:CreateFontString(nil, "ARTWORK", "GameFontHighlight"); lab:SetPoint("LEFT", r, "RIGHT", 2, 0) end
    lab:SetText(label); r._labelFS = lab
    r:SetScript("OnClick", function()
      if not r:GetChecked() then r:SetChecked(true) end
      for _, other in ipairs(parent._all or {}) do if other ~= r then other:SetChecked(false) end end
      local d = NS.EnsureDB()
      d.filterMode = mode
      if NS.RefreshUI then NS.RefreshUI() end
    end)
    r.mode = mode
    return r
  end

  radios._all   = {}
  radios.all    = makeRadio(radios, T("FILTER_ALL"),    C.RADIO_ALL_X,    "ALL")
  radios.daily  = makeRadio(radios, T("FILTER_DAILY"),  C.RADIO_DAILY_X,  "DAILY")
  radios.weekly = makeRadio(radios, T("FILTER_WEEKLY"), C.RADIO_WEEKLY_X, "WEEKLY")
  t_insert(radios._all, radios.all); t_insert(radios._all, radios.daily); t_insert(radios._all, radios.weekly)
  UI.radios = radios

  -- Zone button
  local zoneBtn = CreateFrame("Button", nil, bottom, "UIPanelButtonTemplate")
  zoneBtn:SetPoint("BOTTOMLEFT", bottom, "BOTTOMLEFT", 0, 0)
  zoneBtn:SetSize(180, C.BTN_H)
  zoneBtn:SetText( (T("ZONE_PREFIX")):format(T("ZONE_UNKNOWN")) )
  zoneBtn:SetScript("OnClick", function() if NS.OpenWorldMap then NS.OpenWorldMap() end end)
  UI.controls.zoneBtn = zoneBtn

  -- Refresh button
  local refreshBtn = CreateFrame("Button", nil, bottom, "UIPanelButtonTemplate")
  refreshBtn:SetPoint("BOTTOMRIGHT", bottom, "BOTTOMRIGHT", 0, 0)
  refreshBtn:SetSize(110, C.BTN_H)
  if NS.IconText then
    refreshBtn:SetText(NS.IconText("refresh") .. " " .. T("BTN_REFRESH"))
  else
    refreshBtn:SetText(T("BTN_REFRESH"))
  end
  refreshBtn:SetScript("OnClick", function() if NS.RefreshUI then NS.RefreshUI() end end)
  UI.controls.refresh = refreshBtn

  -- Initialize radios from DB
  radios.all:SetChecked((db.filterMode or "ALL") == "ALL")
  radios.daily:SetChecked(db.filterMode == "DAILY")
  radios.weekly:SetChecked(db.filterMode == "WEEKLY")
end

-- Export constructor for core.lua
NS.CreateMainFrame = CreateMainFrame

-- ===== Namespaced UI API =====
function NS.RefreshUI()
  local db = NS.EnsureDB()
  local list = NS.FilterTasks(NS.GetTasks(), db.search or "", db.filterMode)
  UI.filtered = list
  buildRows(list)
  UpdateTitleCount()
end

function NS.UpdateZoneText()
  local zone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or ""
  if NS.IsEmpty and NS.IsEmpty(zone) then zone = T("ZONE_UNKNOWN") end
  if UI.controls.zoneBtn then UI.controls.zoneBtn:SetText( (T("ZONE_PREFIX")):format(zone) ) end
end

-- ===== Context menu (row) =====
ShowContextForRow = function(parent, row, task)
  if NS.HideAllPopups then NS.HideAllPopups() end
  local f = CreateFrame("Frame", nil, parent, "BasicFrameTemplateWithInset")
  f:SetSize(C.CTX_W, C.CTX_H)
  f:SetPoint("BOTTOMLEFT", row, "TOPLEFT", 0, C.CTX_OFFSET_Y)

  local function addBtn(label, yOff, onClick)
    local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    b:SetSize(C.CTX_BTN_W, C.CTX_BTN_H)
    b:SetPoint("TOPLEFT", f, "TOPLEFT", 10, yOff)
    b:SetText(label)
    b:SetScript("OnClick", function() onClick(); f:Hide() end)
    return b
  end

  addBtn(T("FILTER_DAILY"),  C.CTX_BTN_1_Y + 0 * -C.CTX_BTN_STEP, function()
    task.frequency = "daily"
    if NS.RefreshUI then NS.RefreshUI() end
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
  end)
  addBtn(T("FILTER_WEEKLY"), C.CTX_BTN_1_Y + 1 * -C.CTX_BTN_STEP, function()
    task.frequency = "weekly"
    if NS.RefreshUI then NS.RefreshUI() end
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
  end)
  addBtn(T("BTN_DELETE"),    C.CTX_BTN_1_Y + 2 * -C.CTX_BTN_STEP, function()
    local db = NS.EnsureDB()
    for i,t in ipairs(db.tasks) do if t == task then table.remove(db.tasks, i); break end end
    UI.lastClickedIndex = nil
    if NS.RefreshUI then NS.RefreshUI() end
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
  end)

  UI.context = f; f:Show()
end
