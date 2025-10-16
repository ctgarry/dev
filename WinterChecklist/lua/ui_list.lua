--[[
  @file    lua/ui_list.lua
  @brief   In-frame task list UI (single-column, compact) with Add/Remove/Clear, Import/Export,
           filters (search, All/Incomplete, All/Daily/Weekly), and Up/Down reorder.
]]
local _, NS = ...
local U, L = NS.Util, NS.L
NS.UIList = NS.UIList or {}
local M = NS.UIList

local ROW_H = 22
local ROW_GAP = 4
local FOOTER_H = 44
local HEADER_GAP = 6
local SCROLL_PAD = 6
local CHECKBOX_SIZE = 18

local EDITW = 280
local BTN_W = 100

local LIST_BACKDROP = {
  bgFile = "Interface\\FrameGeneral\\UI-Background-Parchment",
  edgeFile = nil,
  tile = false,
  edgeSize = 0,
  insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

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

  local host = parent.content or parent
  local topOffset = parent._contentTopOffset or 32
  local container = CreateFrame("Frame", nil, host, "BackdropTemplate")
  self.frame = container
  container:SetPoint("TOPLEFT", host, "TOPLEFT", 8, -topOffset)
  container:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -8, 12)
  container:SetBackdrop(LIST_BACKDROP)
  container:SetBackdropColor(0.98, 0.95, 0.88, 0.98)
  container:SetFrameLevel((host:GetFrameLevel() or 1) + 1)

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
    if M.search then
      M.search:SetText("")
      M.search:ClearFocus()
    end
  end)
  clearBtn:SetScript("OnEnter", function(btn)
    if GameTooltip and L.CLEAR_SEARCH then
      GameTooltip:SetOwner(btn, "ANCHOR_TOP")
      GameTooltip:SetText(L.CLEAR_SEARCH, 1, 1, 1)
    end
  end)
  clearBtn:SetScript("OnLeave", function()
    if GameTooltip then
      GameTooltip:Hide()
    end
  end)
  self.btnClear = clearBtn

  self.freqValue = "all"
  local freqRow = CreateFrame("Frame", nil, header)
  freqRow:SetHeight(ROW_H)
  self.freqRow = freqRow
  self.freqButtons = {}

  local freqOptions = {
    { value = "all", label = L.FILTER_FREQ_ALL or "All" },
    { value = "daily", label = L.FILTER_FREQ_DAILY or "Daily" },
    { value = "weekly", label = L.FILTER_FREQ_WEEKLY or "Weekly" },
  }
  local prevAnchor
  for _, opt in ipairs(freqOptions) do
    local radio = CreateFrame("CheckButton", nil, freqRow, "UIRadioButtonTemplate")
    if radio.text then
      radio.text:ClearAllPoints()
      radio.text:SetPoint("LEFT", radio, "RIGHT", 4, 0)
      radio.text:SetJustifyH("LEFT")
      radio.text:SetFontObject("GameFontHighlightSmall")
      radio.text:SetText(opt.label)
    end
    radio:SetHitRectInsets(0, -12, 0, 0)
    if prevAnchor then
      radio:SetPoint("LEFT", prevAnchor, "RIGHT", 24, 0)
    else
      radio:SetPoint("LEFT", freqRow, "LEFT", 0, 0)
    end
    radio:SetScript("OnClick", function(btn)
      if not btn:GetChecked() then
        btn:SetChecked(true)
        return
      end
      PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 857)
      M:SetFrequency(opt.value)
    end)
    self.freqButtons[opt.value] = radio
    prevAnchor = (radio.text or radio)
  end

  local inc = CreateFrame("CheckButton", nil, freqRow, "UICheckButtonTemplate")
  inc.text:SetText(L.FILTER_INCOMPLETE or "Incomplete")
  inc.text:SetFontObject("GameFontHighlightSmall")
  if prevAnchor then
    inc:SetPoint("LEFT", prevAnchor, "RIGHT", 28, 0)
  else
    inc:SetPoint("LEFT", freqRow, "LEFT", 0, 0)
  end
  inc:SetHitRectInsets(0, -12, 0, 0)
  inc:SetScript("OnClick", function(selfBtn)
    PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 857)
    M:Refresh()
  end)
  self.onlyIncomplete = inc
  self:SetFrequency("all")

  local footer = CreateFrame("Frame", nil, container)
  footer:SetHeight(FOOTER_H)
  self.footer = footer

  local btnAdd = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
  btnAdd:SetSize(BTN_W, ROW_H)
  btnAdd:SetText(L.ADD or "Add")
  btnAdd:SetScript("OnClick", function()
    U.ShowTextPopup(L.ADD_TASK or "Add Task", "", function(text)
      if text and text ~= "" then
        NS.Tasks:Add(text, "all")
        M:Refresh()
      end
    end, { multiline = false })
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
  local scrollBar = scrollFrame.ScrollBar
  if scrollBar then
    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -18)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 18)
    scrollBar:Show()
  end
  self.scrollBar = scrollBar

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
  row.chk:ClearAllPoints()
  row.chk:SetPoint("LEFT", row, "LEFT", 0, 0)
  row.chk:SetPoint("TOP", row, "TOP", 0, -2)
  row.chk:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
  row.chk:SetHitRectInsets(-4, -12, -4, -4)

  local function mkTextBtn(width, label)
    local b = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    b:SetSize(width, ROW_H - 4)
    b:SetText(label)
    b:SetMotionScriptsWhileDisabled(true)
    return b
  end
  local function mkIconBtn(direction, tooltip)
    local b = CreateFrame("Button", nil, row, "UIPanelSquareButton")
    b:SetSize(18, 18)
    b:SetMotionScriptsWhileDisabled(true)
    if SquareButton_SetIcon then
      SquareButton_SetIcon(b, direction)
    else
      b:SetText(direction == "UP" and "^" or "v")
    end
    if tooltip then
      b:SetScript("OnEnter", function(btn)
        if GameTooltip then
          GameTooltip:SetOwner(btn, "ANCHOR_TOP")
          GameTooltip:SetText(tooltip, 1, 1, 1, true)
        end
      end)
      b:SetScript("OnLeave", function()
        if GameTooltip then
          GameTooltip:Hide()
        end
      end)
    end
    return b
  end
  local function mkGlyphBtn(texture, tooltip)
    local b = CreateFrame("Button", nil, row, "UIPanelSquareButton")
    b:SetSize(20, 20)
    b:SetMotionScriptsWhileDisabled(true)
    if b.icon then
      b.icon:SetTexture(texture)
      b.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    else
      local icon = b:CreateTexture(nil, "ARTWORK")
      icon:SetAllPoints()
      icon:SetTexture(texture)
      icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
      b.icon = icon
    end
    if tooltip then
      b:SetScript("OnEnter", function(btn)
        if GameTooltip then
          GameTooltip:SetOwner(btn, "ANCHOR_TOP")
          GameTooltip:SetText(tooltip, 1, 1, 1, true)
        end
      end)
      b:SetScript("OnLeave", function()
        if GameTooltip then
          GameTooltip:Hide()
        end
      end)
    end
    return b
  end

  row.btnDel = mkTextBtn(26, L.DELETE_SHORT or "x")
  row.btnDel:SetPoint("RIGHT", row, "RIGHT", 0, 0)
  row.btnDel:SetScript("OnEnter", function(btn)
    if GameTooltip then
      GameTooltip:SetOwner(btn, "ANCHOR_TOP")
      GameTooltip:SetText(L.DELETE_TASK or "Delete task", 1, 0.2, 0.2, true)
    end
  end)
  row.btnDel:SetScript("OnLeave", function()
    if GameTooltip then
      GameTooltip:Hide()
    end
  end)

  row.btnEdit = mkGlyphBtn("Interface\\Buttons\\UI-GuildButton-MOTD-Up", L.EDIT_TASK or "Edit task")
  row.btnEdit:SetPoint("RIGHT", row.btnDel, "LEFT", -4, 0)

  row.btnDown = mkIconBtn("DOWN", L.MOVE_DOWN or "Move down")
  row.btnDown:SetPoint("RIGHT", row.btnEdit, "LEFT", -6, 0)

  row.btnUp = mkIconBtn("UP", L.MOVE_UP or "Move up")
  row.btnUp:SetPoint("RIGHT", row.btnDown, "LEFT", -4, 0)

  row.txt = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  row.txt:SetPoint("LEFT", row.chk, "RIGHT", 6, 0)
  row.txt:SetPoint("RIGHT", row.btnUp, "LEFT", -10, 0)
  row.txt:SetJustifyH("LEFT")
  row.txt:SetWordWrap(false)

  M.rows[index] = row
  return row
end

function M:SetFrequency(freq)
  self.freqValue = freq or "all"
  if self.freqButtons then
    for value, radio in pairs(self.freqButtons) do
      if radio.SetChecked then
        radio:SetChecked(value == self.freqValue)
      end
    end
  end
  if self.Refresh then
    self:Refresh()
  end
end

function M:Refresh()
  if not self.frame then
    return
  end

  local tasks = NS.Tasks:GetAll() or {}
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
        end, { multiline = false })
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

  if self.btnClear then
    local hasText = needle and needle ~= ""
    self.btnClear:SetEnabled(hasText)
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

  local freqHeight = 0
  if self.freqRow and self.search then
    self.freqRow:ClearAllPoints()
    local offsetY = labelHeight + HEADER_GAP + ROW_H + 8
    self.freqRow:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -offsetY)
    self.freqRow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -offsetY)
    self.freqRow:SetHeight(ROW_H)
    freqHeight = ROW_H + 8
  end

  if self.footer then
    self.footer:ClearAllPoints()
    self.footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    self.footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    self.footer:SetHeight(FOOTER_H)
  end

  if self.btnAdd and self.footer then
    self.btnAdd:ClearAllPoints()
    self.btnAdd:SetPoint("CENTER", self.footer, "CENTER", 0, 0)
    self.btnAdd:SetHeight(ROW_H)
    self.btnAdd:SetWidth(BTN_W)
  end

  if self.scrollFrame and self.footer then
    local topOffset = labelHeight + HEADER_GAP + ROW_H + HEADER_GAP + freqHeight + HEADER_GAP
    self.scrollFrame:ClearAllPoints()
    self.scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -topOffset)
    self.scrollFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -topOffset)
    self.scrollFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, FOOTER_H + 6)
    self.scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, FOOTER_H + 6)

    local scrollWidth = self.scrollFrame:GetWidth()
      - ((self.scrollBar and self.scrollBar:GetWidth()) or 18)
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
