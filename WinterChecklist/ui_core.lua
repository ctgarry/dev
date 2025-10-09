--[[
WinterChecklist - ui_core.lua (Classic Era safe)
Purpose: Main UI construction and layout (refactored to smaller builders)
Scope: One filter at top, radios under filter, per-row tiny edit/delete, bottom Add/Import/Export.
Notes:
- Strict namespacing; no leaky globals.
- Plays nice if certain helpers already exist on NS (SimplePrompt, ShowImport/ShowExport, RefreshUI, EnsureDB).
- Light defensive defaults so it can drop in without exploding if helpers are missing.
]]

local addonName, NS = ...
NS = NS or _G.WinterChecklist or {}
_G.WinterChecklist = NS

-- ========= Constants & light defaults =========
local C = NS.C or {}
C.FRAME_W     = C.FRAME_W     or 260
C.FRAME_H     = C.FRAME_H     or 390
C.TOP_H       = C.TOP_H       or 72
C.BOTTOM_H    = C.BOTTOM_H    or 44
C.ROW_H       = C.ROW_H       or 22
C.SCROLL_GAP  = C.SCROLL_GAP  or 2
C.BTN_GAP     = C.BTN_GAP     or 6
C.BTN_H       = C.BTN_H       or 22
C.SEARCH_H    = C.SEARCH_H    or 22
C.FONT        = C.FONT        or "GameFontNormal"
C.NEAR_WHITE  = C.NEAR_WHITE  or 0.95   -- active row text
C.GRAY        = C.GRAY        or 0.55   -- completed row text

NS.C = C

-- ========= Localization shims =========
local L = NS.L or {}
L.FILTER_LABEL = L.FILTER_LABEL or "Filter"
L.HELP_LINKS   = L.HELP_LINKS   or "Help"
L.BTN_ADD      = L.BTN_ADD      or "Add"
L.BTN_IMPORT   = L.BTN_IMPORT   or "Import"
L.BTN_EXPORT   = L.BTN_EXPORT   or "Export"
L.RAD_ALL      = L.RAD_ALL      or "All"
L.RAD_DAILY    = L.RAD_DAILY    or "Daily"
L.RAD_WEEKLY   = L.RAD_WEEKLY   or "Weekly"
L.DLG_ADD_TASK = L.DLG_ADD_TASK or "New task:"
L.DLG_EDIT_TASK= L.DLG_EDIT_TASK or "Edit task:"
NS.L = L

local function T(k) return (L and L[k]) or k end

-- ========= Safe helpers =========
local function EnsureDB()
  if NS.EnsureDB then return NS.EnsureDB() end
  NS.db = NS.db or { tasks = {}, search = "", freq = "all" }
  return NS.db
end

local function DefaultFreq()
  return (EnsureDB().freq == "weekly" and "weekly") or "daily"
end

local function SimplePrompt(owner, title, preset, cb)
  if NS.SimplePrompt then return NS.SimplePrompt(owner, title, preset, cb) end
  -- Fallback: use StaticPopupDialogs with a very simple input
  local key = "WC_PROMPT_" .. tostring(math.random(999999))
  StaticPopupDialogs[key] = {
    text = title,
    button1 = OKAY,
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 256,
    OnAccept = function(self)
      local txt = self.editBox:GetText() or ""
      if cb then pcall(cb, txt) end
    end,
    EditBoxOnEnterPressed = function(self)
      local parent = self:GetParent()
      local txt = self:GetText() or ""
      if cb then pcall(cb, txt) end
      parent:Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }
  StaticPopup_Show(key)
  local dlg = _G["StaticPopup1"] -- best effort to preset
  if dlg and dlg.editBox then dlg.editBox:SetText(preset or "") end
end

local function RefreshUI()
  if NS.RefreshUI then return NS.RefreshUI() end
  -- fallback no-op; our own UI triggers reflow itself when needed
end

local function SmallIconBtn(parent, iconName, tipText)
  if NS.SmallIconBtn then return NS.SmallIconBtn(parent, iconName, tipText) end
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(24, C.BTN_H)
  b:SetText("?")
  if tipText then b:SetMotionScriptsWhileDisabled(true); b.tooltipText = tipText end
  return b
end

-- ========= Internal UI state =========
local UI = { controls = {}, rows = {}, filtered = {}, rowW = 0 }

-- ========= Build: Top bar (help only) =========
local function BuildTopBar(root)
  local top = CreateFrame("Frame", nil, root, "BackdropTemplate")
  top:SetPoint("TOPLEFT", root, "TOPLEFT", 8, -8)
  top:SetPoint("TOPRIGHT", root, "TOPRIGHT", -8, -8)
  top:SetHeight(C.TOP_H)
  top:SetScript("OnSizeChanged", function(self)
    local e = UI and UI.controls and UI.controls.searchTop
    if e then e:SetWidth(math.floor(self:GetWidth() * 0.5)) end
  end)
  UI.top = top

  -- Help button (top-right)
  local bHelp = SmallIconBtn(top, "link", T("HELP_LINKS"))
  bHelp:ClearAllPoints()
  bHelp:SetPoint("TOPRIGHT", top, "TOPRIGHT", -24, 0) -- keep off the close button
  bHelp:SetText("?")
  bHelp:SetSize(24, 24)
  UI.controls.bHelp = bHelp

  -- Title (top-left)
  if not UI.controls.title then
    local titleFS = top:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleFS:SetPoint("TOPLEFT", top, "TOPLEFT", 0, -2)
    titleFS:SetText((NS.L and NS.L.TITLE) or "Winter Checklist")
    UI.controls.title = titleFS
  end

  bHelp:SetScript("OnClick", function()
    if NS.ClosePopouts then NS.ClosePopouts("help") end
    if NS.ToggleHelp then NS.ToggleHelp(UI.root) end   -- ToggleHelp shows next to main; its own logic will show if hidden
  end)

  -- Filter label under the title
  local lbl = top:CreateFontString(nil, "ARTWORK", C.FONT)
  lbl:SetPoint("TOPLEFT", top, "TOPLEFT", 0, -18)  -- was 0, 0; move down
  lbl:SetText(T("FILTER_LABEL"))
  UI.controls.filterLabelTop = lbl

  -- Search box immediately under label
  local e = CreateFrame("EditBox", nil, top, "InputBoxTemplate")
  e:SetAutoFocus(false)
  e:SetHeight(C.SEARCH_H)
  e:ClearAllPoints()
  e:SetPoint("TOPLEFT", top, "TOPLEFT", 0, -36)
  e:SetWidth(math.floor((C.FRAME_W - 8) * 0.5))
  e:SetText(EnsureDB().search or "")
  UI.controls.searchTop = e

  e:SetScript("OnTextChanged", function(self)
    local d = EnsureDB()
    d.search = self:GetText() or ""
    -- Refilter & redraw
    NS.FilterAndRebuildList(root)
  end)

    -- Clear icon (⊘) to reset search & filter
  local clearBtn = CreateFrame("Button", nil, top, "UIPanelButtonTemplate")
  clearBtn:SetSize(24, 22)
  clearBtn:SetPoint("LEFT", e, "RIGHT", 4, 0)
  clearBtn:SetText(NS.Icon("cancel"))
  clearBtn:SetScript("OnClick", function()
    local d = EnsureDB()
    d.search = ""
    d.freq = "all"
    if UI.controls and UI.controls.searchTop then UI.controls.searchTop:SetText("") end
    if UI.controls and UI.controls.rbAll then
      UI.controls.rbAll:SetChecked(true)
      if UI.controls.rbDaily then UI.controls.rbDaily:SetChecked(false) end
      if UI.controls.rbWeekly then UI.controls.rbWeekly:SetChecked(false) end
    end
    NS.FilterAndRebuildList(root)
  end)
  UI.controls.clearFilter = clearBtn

  -- Radios under search
  local radios = CreateFrame("Frame", nil, top)
  radios:SetSize(260, 22)
  radios:SetPoint("TOPLEFT", e, "BOTTOMLEFT", 0, -2)
  UI.controls.radios = radios

  local function MakeRadio(text, key, prev)

    local rb = CreateFrame("CheckButton", nil, p, "UIRadioButtonTemplate")
    rb:SetSize(14, 14)

    -- Classic-safe: some templates don’t attach .Text unless the frame is named.
    local label = rb.Text or rb.text
    if not label then
      label = rb:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
      label:SetPoint("LEFT", rb, "RIGHT", 4, 0)
    end
    label:SetText(text)

    local w = label:GetStringWidth() or 24
    rb:SetHitRectInsets(0, -math.max(0, w + 8), 0, 0)

    if prev then
      rb:SetPoint("LEFT", prev.Text or prev.text, "RIGHT", 16, 0)  -- chain after label
    else
      rb:SetPoint("LEFT", p, "LEFT", 0, 0)
    end

    rb:SetChecked(EnsureDB().freq == key)
    rb:SetScript("OnClick", function(selfBtn)
      local d = EnsureDB()
      d.freq = key
      for _, b in ipairs({UI.controls.rbAll, UI.controls.rbDaily, UI.controls.rbWeekly}) do
        if b then b:SetChecked(b == selfBtn) end
      end
      NS.FilterAndRebuildList(root)
    end)
    return rb
  end

  UI.controls.rbAll   = MakeRadio(T("RAD_ALL"),   "all",    nil)
  UI.controls.rbDaily = MakeRadio(T("RAD_DAILY"), "daily",  UI.controls.rbAll)
  UI.controls.rbWeekly= MakeRadio(T("RAD_WEEKLY"),"weekly", UI.controls.rbDaily)

  -- default selection
  local db = EnsureDB()
  if db.filterMode == "WEEKLY" then
    UI.controls.rbWeekly:SetChecked(true)
  elseif db.filterMode == "DAILY" then
    UI.controls.rbDaily:SetChecked(true)
  else
    UI.controls.rbAll:SetChecked(true)
  end
end

-- ========= Build: Task list (scroll + rows) =========
local function BuildTaskList(root)
  local list = CreateFrame("Frame", nil, root, "BackdropTemplate")
  list:SetPoint("TOPLEFT", UI.top, "BOTTOMLEFT", 0, -C.SCROLL_GAP)
  -- bottom bar is two rows tall (actions + nav), subtract both
  list:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -8, (C.BOTTOM_H * 2) + 2)

  UI.list = list

  -- Keep row width in sync and rebuild rows when list width changes
  list:SetScript("OnSizeChanged", function(self)
    UI.rowW = (self:GetWidth() or (C.FRAME_W - 32)) - 4
    NS.FilterAndRebuildList(UI.root, true) -- keep scroll
  end)

  local sf = CreateFrame("ScrollFrame", nil, list, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", list, "TOPLEFT", 0, 0)
  sf:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -24, 0)

  local content = CreateFrame("Frame", nil, sf)
  content:SetSize(10, 10)
  sf:SetScrollChild(content)

  UI.scroll = sf
  UI.content = content
end

-- ========= Build: Bottom bar (Zone, Refresh, Add/Import/Export) =========
local function BuildBottomBar(root)
  local bottom = CreateFrame("Frame", nil, root, "BackdropTemplate")
  bottom:SetPoint("BOTTOMLEFT",  root, "BOTTOMLEFT", 8, 8)
  bottom:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -8, 8)
  bottom:SetHeight(C.BOTTOM_H * 2)
  UI.bottom = bottom

  -- Row 1: Add / Import / Export (left→right)
  local actions = CreateFrame("Frame", nil, bottom)
  actions:SetPoint("TOPLEFT",  bottom, "TOPLEFT",  0, 0)
  actions:SetPoint("TOPRIGHT", bottom, "TOPRIGHT", 0, 0)
  actions:SetHeight(C.BOTTOM_H)

  local bAdd = CreateFrame("Button", nil, actions, "UIPanelButtonTemplate")
  bAdd:SetSize(70, C.BTN_H)
  bAdd:SetPoint("LEFT", actions, "LEFT", 0, 0)
  bAdd:SetText(T("BTN_ADD"))
  UI.controls.bAdd = bAdd

  local bImport = CreateFrame("Button", nil, actions, "UIPanelButtonTemplate")
  bImport:SetSize(70, C.BTN_H)
  bImport:SetPoint("LEFT", bAdd, "RIGHT", C.BTN_GAP, 0)
  bImport:SetText(T("BTN_IMPORT"))
  UI.controls.bImport = bImport

  local bExport = CreateFrame("Button", nil, actions, "UIPanelButtonTemplate")
  bExport:SetSize(70, C.BTN_H)
  bExport:SetPoint("LEFT", bImport, "RIGHT", C.BTN_GAP, 0)
  bExport:SetText(T("BTN_EXPORT"))
  UI.controls.bExport = bExport

  -- Reset (clear all checkmarks)
  local bReset = CreateFrame("Button", nil, actions, "UIPanelButtonTemplate")
  bReset:SetSize(70, C.BTN_H)
  bReset:SetPoint("LEFT", bExport, "RIGHT", C.BTN_GAP, 0)
  bReset:SetText(T("BTN_RESET") or "Reset")
  UI.controls.bReset = bReset

  -- Row 2: Zone (left, fixed width, shows current zone & opens map) / Refresh (right)
  local nav = CreateFrame("Frame", nil, bottom)
  nav:SetPoint("BOTTOMLEFT",  bottom, "BOTTOMLEFT",  0, 0)
  nav:SetPoint("BOTTOMRIGHT", bottom, "BOTTOMRIGHT", 0, 0)
  nav:SetHeight(C.BOTTOM_H)

  local zoneBtn = CreateFrame("Button", nil, nav, "UIPanelButtonTemplate")
  zoneBtn:SetSize(140, C.BTN_H) -- fixed width
  zoneBtn:SetPoint("LEFT", nav, "LEFT", 0, 0)
  UI.controls.zoneBtn = zoneBtn

  local refreshBtn = CreateFrame("Button", nil, nav, "UIPanelButtonTemplate")
  refreshBtn:SetSize(90, C.BTN_H)
  refreshBtn:SetPoint("RIGHT", nav, "RIGHT", 0, 0)
  refreshBtn:SetText(NS.L and NS.L.REFRESH_BTN or "Refresh")
  refreshBtn:SetScript("OnClick", function() NS.FilterAndRebuildList(root, true) end)
  UI.controls.refreshBtn = refreshBtn

  local function UpdateZoneButtonText()
    local name = "Zone"
    if C_Map and C_Map.GetBestMapForUnit then
      local id = C_Map.GetBestMapForUnit("player")
      if id and C_Map.GetMapInfo then
        local info = C_Map.GetMapInfo(id)
        if info and info.name then name = info.name end
      end
    end
    -- truncate to fit fixed width (roughly)
    if #name > 14 then name = name:sub(1,14) .. "…" end
    zoneBtn:SetText(name)
  end

  zoneBtn:SetScript("OnClick", function()
    -- open map at current zone (Classic-safe)
    if WorldMapFrame and WorldMapFrame.Show then
      ShowUIPanel(WorldMapFrame)
      local id = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
      if id and WorldMapFrame.SetMapID then WorldMapFrame:SetMapID(id) end
    elseif ToggleWorldMap then
      ToggleWorldMap()
    end
  end)

  -- update label on init / zone changes
  local zf = CreateFrame("Frame")
  zf:RegisterEvent("PLAYER_ENTERING_WORLD")
  zf:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  zf:RegisterEvent("ZONE_CHANGED")
  zf:SetScript("OnEvent", UpdateZoneButtonText)
  C_Timer.After(0.1, UpdateZoneButtonText)

  -- Hook handlers for actions row
  -- Add button: cue format + enforce non-empty/unsupported prefixes
  bAdd:SetScript("OnClick", function()
    if NS.ClosePopouts then NS.ClosePopouts("prompt") end

    local title = T("DLG_ADD_TASK") .. "\n(d: daily, w: weekly;\nleaving off the prefix = daily)"
    SimplePrompt(root, title, "d: ", function(text)
      if not text then return end
      local raw = text:gsub("^%s+", ""):gsub("%s+$","")
      if raw == "" then return end

      -- Accept "d: Task" -> daily, "w: Task" -> weekly, or plain text -> daily.
      -- Prevent duplicates within frequency

      local prefix, body = raw:match("^(%a)%s*:%s*(.+)$")
      local freq = DefaultFreq()
      if prefix then
        local p = prefix:lower()
        if p == "d" then
          freq = "daily"
        elseif p == "w" then
          freq = "weekly"
        else
          -- Unsupported prefix: do nothing (enforce)
          return
        end
        if not body or body == "" then return end
      else
        body = raw -- no prefix: default to daily
      end

      local d = EnsureDB()
      for _, t in ipairs(d.tasks) do
        if (t.frequency or "daily") == freq and (t.text or "") == body then
          if NS.Print then NS.Print("Task already exists in "..freq..": "..body) end
          return
        end
      end
      table.insert(d.tasks, 1, { text = body, frequency = freq, completed = false })

      -- Reset filter/search so new item is visible
      d.search = ""
      d.freq = "all"
      if UI.controls and UI.controls.searchTop then UI.controls.searchTop:SetText("") end
      if UI.controls and UI.controls.rbAll then
        UI.controls.rbAll:Click()
      else
        NS.FilterAndRebuildList(root)
      end

      if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
    end)
  end)

  bImport:SetScript("OnClick", function()
    if NS.ClosePopouts then NS.ClosePopouts("import") end
    if NS.ShowImport then NS.ShowImport(UI.root) end
  end)

  bExport:SetScript("OnClick", function()
    if NS.ClosePopouts then NS.ClosePopouts("export") end
    if NS.ShowExport then NS.ShowExport(UI.root) end
  end)

  bReset:SetScript("OnClick", function()
    StaticPopup_Show("WINTERCHECKLIST_CONFIRM_RESET")
  end)
end

-- ========= Row factory =========
local function MakeRow(parent, i, task, root)
  local r  = CreateFrame("Frame", nil, parent)
  r:SetSize(UI.rowW, C.ROW_H)

  -- Checkbox
  local cb = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
  cb:SetPoint("LEFT", 4, 0)
  cb:SetChecked(task.completed or false)

  -- Task text
  local fs = r:CreateFontString(nil, "OVERLAY", C.FONT)
  fs:SetPoint("LEFT", cb, "RIGHT", 6, 0)
  fs:SetPoint("RIGHT", r, "RIGHT", -52, 0)      -- reserve space for tiny buttons
  fs:SetJustifyH("LEFT")
  fs:SetWordWrap(false)                          -- single line only (no wrapping)
  fs:SetNonSpaceWrap(false)
  fs:SetMaxLines(1)
  fs:SetText(task.text or "")

  r.fs = fs; r.task = task
  function r:UpdateTextColor()
    local c = self.task.completed and NS.C.GRAY or NS.C.NEAR_WHITE
    self.fs:SetTextColor(c, c, c)
  end

  r:UpdateTextColor()

  -- Tiny edit (✎) and delete (🗑) on right
  local editBtn = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
  editBtn:SetFrameLevel(r:GetFrameLevel()+2)
  editBtn:SetSize(20, C.BTN_H - 8)
  editBtn:SetPoint("RIGHT", r, "RIGHT", -28, 0)
  editBtn:SetText(NS.Icon and NS.Icon("edit") or "E") --editBtn:SetText("✎")

  local delBtn = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
  delBtn:SetFrameLevel(r:GetFrameLevel()+2)
  delBtn:SetSize(20, C.BTN_H - 8)
  delBtn:SetPoint("RIGHT", r, "RIGHT", -4, 0)
  delBtn:SetText(NS.Icon and NS.Icon("trash") or "X") --delBtn:SetText("🗑")

  -- Width for text (leave ~48px for tiny buttons)
  fs:SetWidth(UI.rowW - 48 - cb:GetWidth() - 10)

  -- Handlers
  cb:SetScript("OnClick", function(selfBtn)
    -- use the arg rather than closing over `cb`
    local checked = selfBtn:GetChecked() and true or false

    r.task.completed = checked
    r:UpdateTextColor()

    if NS.OnTaskToggled then NS.OnTaskToggled(r.task) end
    if NS.SaveTasks then NS.SaveTasks(EnsureDB().tasks) end
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
  end)


  editBtn:SetScript("OnClick", function()
    SimplePrompt(root, T("DLG_EDIT_TASK"), task.text or "", function(newText)
      if newText and newText ~= "" then
        task.text = newText
        fs:SetText(newText)
        if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
      end
    end)
  end)

  delBtn:SetScript("OnClick", function()
    local d = EnsureDB()
    -- remove the concrete task object from d.tasks
    for idx, t in ipairs(d.tasks or {}) do
      if t == task then
        table.remove(d.tasks, idx)
        break
      end
    end
    NS.FilterAndRebuildList(root)
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
  end)

  -- Clicking row toggles checkbox (not when clicking buttons)
  r:SetScript("OnMouseUp", function(_, btn)
    if btn == "LeftButton" then
      local focus = GetMouseFocus()
      if focus ~= editBtn and focus ~= delBtn and focus ~= cb then
        cb:Click()
      end
    end
  end)

  r.cb, r.fs, r.editBtn, r.delBtn, r.task = cb, fs, editBtn, delBtn, task
  return r
end

-- ========= Filtering & rebuild =========
function NS.FilterAndRebuildList(root, keepScroll)
  local d = EnsureDB()
  local all = d.tasks or {}

  -- Compute filter
  local txt = (d.search or ""):lower()
  local freq = d.freq or "all"

  wipe(UI.filtered)
  for _, t in ipairs(all) do
    local okText = (txt == "") or ((t.text or ""):lower():find(txt, 1, true) ~= nil)
    local okFreq = (freq == "all") or ((t.frequency or "daily") == freq)
    if okText and okFreq then
      table.insert(UI.filtered, t)
    end
  end

  -- Rebuild rows
  for _, row in ipairs(UI.rows) do
    row:Hide()
    row:SetParent(nil)
  end
  wipe(UI.rows)

  local content = UI.content
  local y = -2
  local i = 1
  UI.rowW = (UI.list:GetWidth() or (C.FRAME_W - 32)) - 4

  for _, task in ipairs(UI.filtered) do
    local r = MakeRow(content, i, task, root)
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
    r:SetPoint("RIGHT", content, "RIGHT", 0, y)
    r:Show()
    table.insert(UI.rows, r)
    y = y - C.ROW_H
    i = i + 1
  end

  content:SetHeight(math.max(10, (#UI.rows * C.ROW_H) + 6))

  if not keepScroll and UI.scroll and UI.scroll.ScrollBar then
    UI.scroll.ScrollBar:SetValue(0)
  end
end

-- ========= Orchestrator =========
function NS.CreateMainFrame(parent)

  local p = (type(parent) == "userdata" and parent.GetObjectType and parent) or UIParent
  local tpl = BackdropTemplateMixin and "BackdropTemplate" or nil
  local f   = CreateFrame("Frame", "WC_Main", p, tpl)

  -- WoW-like frame border + translucent interior (≈20% see-through)
  if f.SetBackdrop then
    f:SetBackdrop({
      bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 12,
      insets   = { left=4, right=4, top=4, bottom=4 },
    })
    f:SetBackdropColor(0, 0, 0, 0.80) -- 0.80 alpha = ~20% transparency
  end

  f:SetSize(C.FRAME_W, C.FRAME_H)
  f:SetPoint("CENTER")

  -- Drag & resize
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetClampedToScreen(true)

  if f.SetResizable then
      f:SetResizable(true)
  end

  if f.SetResizeBounds then
    f:SetResizeBounds(260, 320, 900, 900)
  elseif f.SetMinResize then
    f:SetMinResize(260, 320)
  else
      -- last-ditch clamp
      f._wcMinW, f._wcMinH = 320, 320
      if not f._wcMinSizeHooked then
          f._wcMinSizeHooked = true
          f:HookScript("OnSizeChanged", function(fr, w, h)
              if w < 260 or h < 320 then
                  fr:SetSize((w < 260) and 260 or w, (h < 320) and 320 or h)
              end
          end)
      end
  end
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop",  f.StopMovingOrSizing)

  -- Bottom-right resize grabber
  local rh = CreateFrame("Button", nil, f)
  rh:SetPoint("BOTTOMRIGHT", -2, 2)
  rh:SetSize(16, 16)
  rh:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  rh:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  rh:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  rh:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
  rh:SetScript("OnMouseUp",   function() f:StopMovingOrSizing(); NS.FilterAndRebuildList(f, true) end)

  -- Top-right close “X”
  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)

  UI.root = f

  BuildTopBar(f)
  BuildTaskList(f)
  UI.rowW = UI.list and (UI.list:GetWidth() or (C.FRAME_W - 32)) or (C.FRAME_W - 32)
  BuildBottomBar(f)

  -- Initial build
  C_Timer.After(0, function() NS.FilterAndRebuildList(f) end)

  -- Store for external calls
  f.UI = UI
  return f
end

-- Keep a thin alias if older code calls RefreshUI directly
NS.RefreshUI = NS.RefreshUI or function()
  if UI.root then NS.FilterAndRebuildList(UI.root, true) end
end

-- WC_RESET_CONFIRM_INLINE
if not StaticPopupDialogs["WINTERCHECKLIST_CONFIRM_RESET"] then
  StaticPopupDialogs["WINTERCHECKLIST_CONFIRM_RESET"] = {
    text = "Are you sure you want to uncheck all tasks?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
      if NS and NS.ResetTasks then
        -- use current filter if you want: NS.GetActiveFilter() or "all"
        NS.ResetTasks("all")
      end
    end,
    timeout = 0,
    hideOnEscape = true,
    whileDead = true,
    preferredIndex = 3,
  }
end

-- WC_IMPORT_MULTILINE_INLINE
function NS.BuildImportBox(parent)
  local box = CreateFrame("ScrollFrame", nil, parent, "InputScrollFrameTemplate")
  box:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -40)
  box:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -16, 50)
  box.EditBox:SetAutoFocus(false)
  box.EditBox:SetMultiLine(true)
  box.EditBox:SetWidth(box:GetWidth())
  box:SetClipsChildren(true)
  box.EditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  parent._ImportBox = box
  parent:HookScript("OnSizeChanged", function()
    if parent._ImportBox then parent._ImportBox.EditBox:SetWidth(parent._ImportBox:GetWidth()) end
  end)
end

function NS.ParseImport(text)
  if not text or text == "" then return nil, "empty" end
  local tasks, n = {}, 0
  for raw in string.gmatch(text, "([^\n]+)") do
    local line = NS.SanitizeText((raw or ""):gsub("\r",""))
    line = (line:gsub("^%s+",""):gsub("%s+$",""))
    if line ~= "" then
      local freq, body = line:match("^%s*(all|daily|weekly)%s*|%s*(.+)$")
      if not body then body = line:match("^%s*[%-%*]%s*(.+)$"); freq = body and "all" or nil end
      if not body then body, freq = line, "all" end
      n = n + 1
      tasks[n] = { text = body, frequency = freq, completed = false }
    end
  end
  if n == 0 then return nil, "no valid lines" end
  return tasks
end

