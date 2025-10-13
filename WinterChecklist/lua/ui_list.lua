--[[
  @file    lua/ui_list.lua
  @brief   In-frame task list UI (single-column, compact) with Add/Remove/Clear, Import/Export,
           filters (search, All/Incomplete, All/Daily/Weekly), and Up/Down reorder.
]]
local _, NS = ...
local U, L = NS.Util, NS.L
NS.UIList = NS.UIList or {}
local M = NS.UIList

local ROW_H = 24
local ROW_GAP = 4
local FOOTER_H = 40
local HEADER_GAP = 6
local SCROLL_PAD = 6
local CHECKBOX_SIZE = 20

local EDITW = 260
local BTN_W = 96
local DD_W = 128

local function freqMatch(row, want)
  if want == "all" then
    return true
  end
  local f = (row.freq or "all")
  return f == want
end

local function passFilter(row, needle, wantIncomplete, wantFreq)
  if wantIncomplete and row.done then
    return false
  end
  if wantFreq and not freqMatch(row, wantFreq) then
    return false
  end
  if needle and needle ~= "" then
    local s = string.lower(row.text or "")
    if not string.find(s, needle, 1, true) then
      return false
    end
  end
  return true
end

function M:Init(parent)
  if self._inited then
    return
  end
  self._inited = true
  self.parent = parent

  local topOffset = parent._contentTopOffset or 48
  local container = CreateFrame("Frame", nil, parent)
  self.frame = container
  container:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -topOffset)
  container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -12, 12)

  local header = CreateFrame("Frame", nil, container)
  self.header = header

  local filterLabel = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  filterLabel:SetText(L.FILTER_LABEL or "Filter:")
  self.filterLabel = filterLabel

  local search = CreateFrame("EditBox", nil, header, "InputBoxTemplate")
  search:SetAutoFocus(false)
  search:SetSize(EDITW, ROW_H)
  search:SetScript("OnTextChanged", function()
    M:Refresh()
  end)
  self.search = search

  local clearBtn = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
  clearBtn:SetSize(32, ROW_H - 4)
  clearBtn:SetText(L.CLEAR_SHORT or "X")
  clearBtn:SetScript("OnClick", function()
    U.Confirm(L.CLEAR_ALL or "Clear all tasks?", L.YES or "Yes", L.NO or "No", function()
      NS.Tasks:Clear()
      M:Refresh()
    end)
  end)
  self.btnClear = clearBtn

  local freq = CreateFrame("Frame", nil, header, "UIDropDownMenuTemplate")
  self.freq = freq
  self.freqValue = "all"
  UIDropDownMenu_SetWidth(freq, DD_W)
  UIDropDownMenu_SetText(freq, L.FILTER_FREQ_ALL or "All (freq)")
  UIDropDownMenu_Initialize(freq, function()
    local function add(label, value)
      local info = UIDropDownMenu_CreateInfo()
      info.text = label
      info.func = function()
        M.freqValue = value
        UIDropDownMenu_SetText(freq, label)
        M:Refresh()
      end
      info.checked = (M.freqValue == value)
      UIDropDownMenu_AddButton(info)
    end
    add(L.FILTER_FREQ_ALL or "All (freq)", "all")
    add(L.FILTER_FREQ_DAILY or "Daily", "daily")
    add(L.FILTER_FREQ_WEEKLY or "Weekly", "weekly")
  end)

  local inc = CreateFrame("CheckButton", nil, header, "UICheckButtonTemplate")
  inc.text:SetText(L.FILTER_INCOMPLETE or "Incomplete")
  inc:SetScript("OnClick", function()
    M:Refresh()
  end)
  self.onlyIncomplete = inc

  local footer = CreateFrame("Frame", nil, container)
  footer:SetHeight(FOOTER_H)
  self.footer = footer

  local btnExport = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
  btnExport:SetSize(BTN_W, ROW_H)
  btnExport:SetText(L.EXPORT or "Export")
  btnExport:SetScript("OnClick", function()
    local payload = NS.Tasks:Export()
    U.ShowTextPopup(L.EXPORT_TITLE or "Tasks Export", payload)
  end)
  self.btnExport = btnExport

  local btnImport = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
  btnImport:SetSize(BTN_W, ROW_H)
  btnImport:SetText(L.IMPORT or "Import")
  btnImport:SetScript("OnClick", function()
    U.ShowTextPopup(L.IMPORT_TITLE or "Paste Import", "", function(text)
      if text and text ~= "" then
        NS.Tasks:ImportWithPrompt(text)
      end
    end)
  end)
  self.btnImport = btnImport

  local btnAdd = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
  btnAdd:SetSize(BTN_W, ROW_H)
  btnAdd:SetText(L.ADD or "Add")
  btnAdd:SetScript("OnClick", function()
    U.ShowTextPopup(L.ADD_TASK or "Add Task", "", function(text)
      if text and text ~= "" then
        NS.Tasks:Add(text, "all")
        M:Refresh()
      end
    end)
  end)
  self.btnAdd = btnAdd

  local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
  scrollFrame:SetClipsChildren(true)
  self.scrollFrame = scrollFrame
  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetSize(1, 1)
  scrollChild:SetPoint("TOPLEFT")
  scrollFrame:SetScrollChild(scrollChild)
  self.scrollChild = scrollChild

  self.emptyText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  self.emptyText:SetText(L.EMPTY_STATE or "No tasks yet - click Add, or type: /wcl add <task>")
  self.emptyText:Hide()

  self.rows = {}

  local previousSized = parent._OnFrameSized
  parent._OnFrameSized = function(frame)
    if previousSized then
      previousSized(frame)
    end
    if M.Layout then
      M:Layout(frame)
    end
    if M.Refresh then
      M:Refresh()
    end
  end

  scrollFrame:SetScript("OnSizeChanged", function()
    if M.Layout then
      M:Layout(parent)
    end
    if M.Refresh then
      M:Refresh()
    end
  end)

  if M.Layout then
    M:Layout(parent)
  end
  if M.Refresh then
    M:Refresh()
  end
end

local function ensureRow(index, parent)
  local row = M.rows[index]
  if row then
    return row
  end
  row = CreateFrame("Frame", nil, parent)
  row:SetHeight(ROW_H)

  row.chk = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
  row.chk:SetPoint("LEFT", 0, 0)
  row.chk:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
  row.chk:SetHitRectInsets(0, -6, 0, 0)

  local function mkBtn(width)
    local b = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    b:SetSize(width, ROW_H - 6)
    return b
  end

  row.btnDel = mkBtn(32)
  row.btnDel:SetPoint("RIGHT", row, "RIGHT", 0, 0)
  row.btnDel:SetText(L.DELETE_SHORT or "X")

  row.btnEdit = mkBtn(48)
  row.btnEdit:SetPoint("RIGHT", row.btnDel, "LEFT", -6, 0)
  row.btnEdit:SetText(L.EDIT or "Edit")

  row.btnDown = mkBtn(40)
  row.btnDown:SetPoint("RIGHT", row.btnEdit, "LEFT", -6, 0)
  row.btnDown:SetText(L.MOVE_DOWN or "Down")

  row.btnUp = mkBtn(40)
  row.btnUp:SetPoint("RIGHT", row.btnDown, "LEFT", -6, 0)
  row.btnUp:SetText(L.MOVE_UP or "Up")

  row.txt = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  row.txt:SetPoint("LEFT", row.chk, "RIGHT", 6, 0)
  row.txt:SetPoint("RIGHT", row.btnUp, "LEFT", -8, 0)
  row.txt:SetJustifyH("LEFT")
  row.txt:SetWordWrap(false)

  M.rows[index] = row
  return row
end

function M:Refresh()
  if not self.frame then
    return
  end

  local tasks = NS.Tasks:GetAll()
  local needle = string.lower(self.search and (self.search:GetText() or "") or "")
  local wantInc = self.onlyIncomplete and self.onlyIncomplete:GetChecked()
  local wantFreq = self.freqValue or "all"
  local scrollChild = self.scrollChild
  if not scrollChild then
    return
  end

  for _, row in ipairs(self.rows) do
    row:Hide()
  end

  local idx = 1
  local offset = 0
  self.visibleCount = 0
  for i, rec in ipairs(tasks) do
    if passFilter(rec, needle, wantInc, wantFreq) then
      local row = ensureRow(idx, scrollChild)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -offset)
      row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -offset)
      row:Show()
      self.visibleCount = self.visibleCount + 1

      row.txt:SetText(rec.text or "")
      if rec.done then
        row.txt:SetTextColor(0.6, 0.6, 0.6)
      else
        row.txt:SetTextColor(1, 1, 1)
      end

      row.chk:SetChecked(rec.done and true or false)
      row.chk:SetScript("OnClick", function(btn)
        NS.Tasks:ToggleDone(i, btn:GetChecked())
      end)

      row.btnUp:SetEnabled(i > 1)
      row.btnUp:SetScript("OnClick", function()
        NS.Tasks:MoveUp(i)
        M:Refresh()
      end)

      row.btnDown:SetEnabled(i < #tasks)
      row.btnDown:SetScript("OnClick", function()
        NS.Tasks:MoveDown(i)
        M:Refresh()
      end)

      row.btnEdit:SetScript("OnClick", function()
        U.ShowTextPopup(L.EDIT_TASK or "Edit Task", rec.text or "", function(newText)
          if newText and newText ~= "" then
            NS.Tasks:Edit(i, newText)
            M:Refresh()
          end
        end)
      end)

      row.btnDel:SetScript("OnClick", function()
        U.Confirm(L.DELETE_TASK or "Delete this task?", L.YES or "Yes", L.NO or "No", function()
          NS.Tasks:RemoveByIndex(i)
          M:Refresh()
        end)
      end)

      offset = offset + ROW_H + ROW_GAP
      idx = idx + 1
    end
  end

  local totalHeight
  if self.visibleCount > 0 then
    totalHeight = (self.visibleCount * ROW_H) + ((self.visibleCount - 1) * ROW_GAP)
  else
    totalHeight = ROW_H
  end

  local frameHeight = (self.scrollFrame and self.scrollFrame:GetHeight()) or totalHeight
  self.scrollChild:SetHeight(math.max(totalHeight, frameHeight))
  if self.scrollFrame then
    self.scrollFrame:UpdateScrollChildRect()
  end

  if self.emptyText then
    if self.visibleCount == 0 then
      self.emptyText:Show()
    else
      self.emptyText:Hide()
    end
  end

  if NS.EnhanceMinimapText then
    NS.EnhanceMinimapText()
  end
end

function M:Layout(parent)
  if not parent or not self.frame then
    return
  end
  local frame = self.frame

  local labelHeight = 0
  if self.filterLabel then
    self.filterLabel:ClearAllPoints()
    self.filterLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    labelHeight = self.filterLabel:GetStringHeight() or 0
  end
  if labelHeight <= 0 then
    labelHeight = 12
  end

  if self.search then
    self.search:ClearAllPoints()
    self.search:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -(labelHeight + HEADER_GAP))
    self.search:SetHeight(ROW_H)
    self.search:SetWidth(EDITW)
  end
  if self.filterLabel and self.search then
    self.filterLabel:SetPoint("BOTTOMLEFT", self.search, "TOPLEFT", 0, HEADER_GAP)
  end

  if self.btnClear and self.search then
    self.btnClear:ClearAllPoints()
    self.btnClear:SetPoint("LEFT", self.search, "RIGHT", 6, 0)
    self.btnClear:SetHeight(ROW_H - 4)
    self.btnClear:SetWidth(32)
  end

  if self.freq then
    self.freq:ClearAllPoints()
    local anchor = self.btnClear or self.search
    self.freq:SetPoint("LEFT", anchor, "RIGHT", 12, -2)
    UIDropDownMenu_SetWidth(self.freq, DD_W)
  end

  if self.onlyIncomplete then
    self.onlyIncomplete:ClearAllPoints()
    self.onlyIncomplete:SetPoint("LEFT", self.freq, "RIGHT", 8, 0)
    if self.onlyIncomplete.text and self.onlyIncomplete.text.SetTextColor then
      self.onlyIncomplete.text:SetTextColor(1, 1, 1)
    end
  end

  if self.footer then
    self.footer:ClearAllPoints()
    self.footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    self.footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    self.footer:SetHeight(FOOTER_H)
  end

  if self.btnAdd and self.footer then
    self.btnAdd:ClearAllPoints()
    self.btnAdd:SetPoint("RIGHT", self.footer, "RIGHT", 0, 0)
    self.btnAdd:SetHeight(ROW_H)
    self.btnAdd:SetWidth(BTN_W)
  end
  if self.btnImport and self.btnAdd then
    self.btnImport:ClearAllPoints()
    self.btnImport:SetPoint("RIGHT", self.btnAdd, "LEFT", -8, 0)
    self.btnImport:SetHeight(ROW_H)
    self.btnImport:SetWidth(BTN_W)
  end
  if self.btnExport and self.btnImport then
    self.btnExport:ClearAllPoints()
    self.btnExport:SetPoint("RIGHT", self.btnImport, "LEFT", -8, 0)
    self.btnExport:SetHeight(ROW_H)
    self.btnExport:SetWidth(BTN_W)
  end

  if self.scrollFrame and self.footer then
    local topOffset = labelHeight + HEADER_GAP + ROW_H + HEADER_GAP
    self.scrollFrame:ClearAllPoints()
    self.scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -topOffset)
    self.scrollFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -topOffset)
    self.scrollFrame:SetPoint("BOTTOMLEFT", self.footer, "TOPLEFT", 0, HEADER_GAP)
    self.scrollFrame:SetPoint("BOTTOMRIGHT", self.footer, "TOPRIGHT", 0, HEADER_GAP)

    local scrollWidth = self.scrollFrame:GetWidth()
      - ((self.scrollFrame.ScrollBar and self.scrollFrame.ScrollBar:GetWidth()) or 18)
      - SCROLL_PAD
    if scrollWidth < 0 then
      scrollWidth = 0
    end
    if self.scrollChild then
      self.scrollChild:SetWidth(scrollWidth)
    end
    if self.emptyText then
      self.emptyText:ClearAllPoints()
      self.emptyText:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 4, -4)
      self.emptyText:SetWidth(math.max(scrollWidth - 8, 0))
    end
  end
end
