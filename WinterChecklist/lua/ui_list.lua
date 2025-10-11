
--[[
  @file    lua/ui_list.lua
  @brief   In-frame task list UI (single-column, compact) with Add/Remove/Clear, Import/Export,
           filters (search, All/Incomplete, All/Daily/Weekly), and Up/Down reorder.
]]
local ADDON, NS = ...
local U, L = NS.Util, NS.L
NS.UIList = NS.UIList or {}
local M = NS.UIList

local ROW_H = 20
local HEADER_H = 32
local PAD = 8

local function counts()
  if not NS.Tasks or not NS.Tasks.GetAll then return 0,0 end
  local t = NS.Tasks:GetAll()
  local total, done = 0,0
  for _,r in ipairs(t) do total=total+1; if r.done then done=done+1 end end
  return done, total
end

local function freqMatch(row, want)
  if want == "all" then return true end
  local f = (row.freq or "all")
  return f == want
end

local function passFilter(row, needle, wantIncomplete, wantFreq)
  if wantIncomplete and row.done then return false end
  if wantFreq and not freqMatch(row, wantFreq) then return false end
  if needle and needle ~= "" then
    local s = string.lower(row.text or "")
    if not string.find(s, needle, 1, true) then return false end
  end
  return true
end

function M:Init(parent)
  if self._inited then return end
  self._inited = true
  self.parent = parent

  -- Header controls ------------------------------------------------------------
  local f = CreateFrame("Frame", nil, parent)
  self.frame = f
  f:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -40)
  f:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -12, 12)

  local search = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  search:SetSize(160, 20)
  search:SetAutoFocus(false)
  search:SetPoint("TOPLEFT", 0, 0)
  search:SetScript("OnTextChanged", function() M:Refresh() end)
  self.search = search

  local freq = CreateFrame("Frame", nil, f, "UIDropDownMenuTemplate")
  freq:SetPoint("TOPLEFT", search, "TOPRIGHT", 8, 4)
  UIDropDownMenu_SetWidth(freq, 110)
  UIDropDownMenu_SetText(freq, L.FILTER_FREQ_ALL or "All (freq)")
  self.freq = freq
  self.freqValue = "all"
  UIDropDownMenu_Initialize(freq, function(self2, level)
    local function add(txt, val)
      local info = UIDropDownMenu_CreateInfo()
      info.text = txt; info.func = function() M.freqValue = val; UIDropDownMenu_SetText(freq, txt); M:Refresh() end
      info.checked = (M.freqValue == val); UIDropDownMenu_AddButton(info)
    end
    add(L.FILTER_FREQ_ALL or "All (freq)", "all")
    add(L.FILTER_FREQ_DAILY or "Daily", "daily")
    add(L.FILTER_FREQ_WEEKLY or "Weekly", "weekly")
  end)

  local inc = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  inc:SetPoint("LEFT", freq, "RIGHT", 6, -2)
  inc.text:SetText(L.FILTER_INCOMPLETE or "Incomplete")
  inc:SetScript("OnClick", function() M:Refresh() end)
  self.onlyIncomplete = inc

  -- Buttons: Add / Clear / Import / Export ------------------------------------
  local btnAdd = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  btnAdd:SetSize(60, 20); btnAdd:SetPoint("TOPRIGHT", -0, 0); btnAdd:SetText(L.ADD or "Add")
  btnAdd:SetScript("OnClick", function()
    U.ShowTextPopup(L.ADD_TASK or "Add Task", "", function(text)
      if text and text ~= "" then
        NS.Tasks:Add(text, "all")
        M:Refresh()
      end
    end)
  end)

  local btnClear = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  btnClear:SetSize(60, 20); btnClear:SetPoint("RIGHT", btnAdd, "LEFT", -6, 0); btnClear:SetText(L.CLEAR or "Clear")
  btnClear:SetScript("OnClick", function()
    U.Confirm(L.CLEAR_ALL or "Clear all tasks?", L.YES or "Yes", L.NO or "No", function() NS.Tasks:Clear(); M:Refresh() end)
  end)

  local btnImport = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  btnImport:SetSize(60, 20); btnImport:SetPoint("RIGHT", btnClear, "LEFT", -6, 0); btnImport:SetText(L.IMPORT or "Import")
  btnImport:SetScript("OnClick", function()
    U.ShowTextPopup(L.IMPORT_TITLE or "Paste Import", "", function(s) if s and s ~= "" then NS.Tasks:ImportWithPrompt(s) end end)
  end)

  local btnExport = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  btnExport:SetSize(60, 20); btnExport:SetPoint("RIGHT", btnImport, "LEFT", -6, 0); btnExport:SetText(L.EXPORT or "Export")
  btnExport:SetScript("OnClick", function()
    local payload = NS.Tasks:Export()
    U.ShowTextPopup(L.EXPORT_TITLE or "Tasks Export", payload)
  end)

  -- Scroll area ----------------------------------------------------------------
  local scroll = CreateFrame("Frame", nil, f)
  scroll:SetPoint("TOPLEFT", search, "BOTTOMLEFT", 0, -PAD)
  scroll:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -(HEADER_H))
  scroll:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
  self.scroll = scroll

  self.rows = {}
  self:Refresh()
end

local function ensureRow(i, parent)
  local row = M.rows[i]
  if row then return row end
  row = CreateFrame("Frame", nil, parent)
  row:SetSize(parent:GetWidth(), ROW_H)
  row.chk = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
  row.chk:SetPoint("LEFT", 0, 0)
  row.txt = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  row.txt:SetPoint("LEFT", row.chk, "RIGHT", 4, 0)
  row.txt:SetJustifyH("LEFT")
  row.txt:SetWidth(parent:GetWidth() - 180)

  -- Right-side controls: Up / Down / Edit / Delete
  local function mkBtn(w, label)
    local b = CreateFrame("Button", nil, row, "UIPanelButtonTemplate"); b:SetSize(w, ROW_H-6); return b
  end
  row.btnUp = mkBtn(24);    row.btnUp:SetPoint("RIGHT", -96, 0); row.btnUp:SetText("↑")
  row.btnDown = mkBtn(24);  row.btnDown:SetPoint("RIGHT", -68, 0); row.btnDown:SetText("↓")
  row.btnEdit = mkBtn(36);  row.btnEdit:SetPoint("RIGHT", -36, 0); row.btnEdit:SetText(L.EDIT or "Edit")
  row.btnDel = mkBtn(28);   row.btnDel:SetPoint("RIGHT", -4, 0); row.btnDel:SetText("✕")

  M.rows[i] = row
  return row
end

function M:Refresh()
  if not self.frame then return end
  local t = NS.Tasks:GetAll()
  local needle = string.lower(self.search:GetText() or "")
  local wantInc = self.onlyIncomplete:GetChecked() and true or false
  local wantFreq = self.freqValue or "all"

  -- Layout visible rows
  local y = -2
  local idx = 1
  for i, row in ipairs(self.rows) do row:Hide() end

  for i, rec in ipairs(t) do
    if passFilter(rec, needle, wantInc, wantFreq) then
      local r = ensureRow(idx, self.scroll)
      r:ClearAllPoints()
      r:SetPoint("TOPLEFT", self.scroll, "TOPLEFT", 0, y)
      y = y - ROW_H - 2
      r:Show()

      r.txt:SetText(rec.text or "")
      r.chk:SetChecked(rec.done and true or false)
      r.chk:SetScript("OnClick", function(self2) NS.Tasks:ToggleDone(i, self2:GetChecked()); end)

      r.btnUp:SetEnabled(i > 1)
      r.btnUp:SetScript("OnClick", function() NS.Tasks:MoveUp(i); M:Refresh() end)

      r.btnDown:SetEnabled(i < #t)
      r.btnDown:SetScript("OnClick", function() NS.Tasks:MoveDown(i); M:Refresh() end)

      r.btnEdit:SetScript("OnClick", function()
        U.ShowTextPopup(L.EDIT_TASK or "Edit Task", rec.text or "", function(newText)
          if newText and newText ~= "" then NS.Tasks:Edit(i, newText); M:Refresh() end
        end)
      end)

      r.btnDel:SetScript("OnClick", function()
        U.Confirm(L.DELETE_TASK or "Delete this task?", L.YES or "Yes", L.NO or "No",
          function() NS.Tasks:RemoveByIndex(i); M:Refresh() end)
      end)

      idx = idx + 1
    end
  end

  -- Update minimap text
  if NS.EnhanceMinimapText then NS.EnhanceMinimapText() end
end
