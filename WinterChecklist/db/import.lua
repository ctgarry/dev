-- import.lua
-- Purpose: Import UI for WinterChecklist — lets the user paste lines like "d: Task" or "w: Task".
-- Scope: Single-instance dialog; validates format, builds task table, saves, and refreshes UI.
-- Notes: Strict localization via T(key); no inline fallbacks. Avoid magic numbers with a constants table.

local ADDON, NS = ...

-- ===== Constants (avoid magic numbers) =====
local C = {
  WIDTH          = 400,
  HEIGHT         = 260,
  PAD            = 12,
  EDGE_SIZE      = 12,
  NOTE_WIDTH     = 376,   -- WIDTH - 2*PAD
  NOTE_OFFSET_Y  = -12,
  EDIT_W         = 376,   -- WIDTH - 2*PAD
  EDIT_H         = 150,
  EDIT_OFFSET_Y  = -56,
  BTN_W          = 80,
  BTN_H          = 22,
  BTN_GAP        = -8,
  BTN_OFFSET_X   = -12,
  BTN_OFFSET_Y   =  12,
}

-- ===== Strict localization helper (no display fallbacks) =====
local L = NS.L or {}
local function T(key)  -- Asserts during dev if a key is missing
  assert(L[key], "Missing locale key: " .. tostring(key))
  return L[key]
end

-- -------------------------------------------------------------------
-- Local: build the import dialog (instructions + multiline edit + buttons)
-- -------------------------------------------------------------------
local function showDialog(parent)
  local frame = CreateFrame("Frame", "WC_Import", parent or UIParent, "BackdropTemplate")
  frame:SetSize(C.WIDTH, C.HEIGHT)
  frame:SetPoint("CENTER")
  frame:SetBackdrop({
    bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = C.EDGE_SIZE,
  })
  frame:SetBackdropColor(0, 0, 0, 0.95)

  -- Instructions
  local note = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  note:SetPoint("TOPLEFT", C.PAD, C.NOTE_OFFSET_Y)
  note:SetWidth(C.NOTE_WIDTH)
  note:SetJustifyH("LEFT")
  note:SetText(T("IMPORT_INSTRUCTIONS"))

  -- Multiline edit box for pasted payload
  local eb = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  eb:SetMultiLine(true)
  eb:SetSize(C.EDIT_W, C.EDIT_H)
  eb:SetPoint("TOPLEFT", C.PAD, C.EDIT_OFFSET_Y)
  eb:SetAutoFocus(false)
  eb:SetScript("OnEscapePressed", function() frame:Hide() end)

  -- Import (OK) button
  local ok = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  ok:SetSize(C.BTN_W, C.BTN_H)
  ok:SetPoint("BOTTOMRIGHT", C.BTN_OFFSET_X, C.BTN_OFFSET_Y)
  ok:SetText(T("DLG_IMPORT"))
  ok:SetScript("OnClick", function()
    local text = eb:GetText() or ""

    -- Validate all lines first: must start with d: or w: (allow whitespace, case-insensitive)
    for line in text:gmatch("[^\r\n]+") do
      if not line:find("^%s*[dDwW]:%s") then
        NS.Print((T("IMPORT_ABORT_BADLINE")):format(line))
        frame:Hide()
        return
      end
    end

    -- Build tasks if valid
    local tasks = {}
    for line in text:gmatch("[^\r\n]+") do
      local prefix, rest = line:match("^%s*([dDwW]):%s*(.*)")
      if prefix and rest then
        local freq = (prefix == "w" or prefix == "W") and "weekly" or "daily"
        tasks[#tasks+1] = { text = rest, frequency = freq, completed = false }
      end
    end

    -- Save & refresh
    NS.SaveTasks(tasks)
    if NS.RefreshUI           then NS.RefreshUI()           end
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
    frame:Hide()
  end)

  -- Cancel button
  local cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  cancel:SetSize(C.BTN_W, C.BTN_H)
  cancel:SetPoint("RIGHT", ok, "LEFT", C.BTN_GAP, 0)
  cancel:SetText(T("DLG_CANCEL"))
  cancel:SetScript("OnClick", function() frame:Hide() end)

  -- Store edit box so caller can focus/select later if needed
  frame.editBox = eb

  return frame
end

-- -------------------------------------------------------------------
-- Public: show the import dialog (single-instance)
-- -------------------------------------------------------------------
function NS.ShowImport(parent)
  NS._imp = NS._imp or showDialog(parent)
  NS._imp:Show()
  if NS._imp.editBox then
    NS._imp.editBox:SetFocus()
    NS._imp.editBox:HighlightText()
  end
end
