-- export.lua
-- Purpose: Export UI and Import/Export chooser for WinterChecklist.
-- Scope: Creates a single-instance export dialog and a popup chooser that defers to import/export.
-- Notes: Strict localization via T(key); no inline fallbacks. Avoid magic numbers with a constants table.

local ADDON, NS = ...

-- ===== Constants (avoid magic numbers) =====
local C = {
  WIDTH            = 400,
  HEIGHT           = 240,
  PAD              = 12,
  EDGE_SIZE        = 12,
  EDIT_HEIGHT      = 150,
  NOTE_OFFSET_Y    = -12,
  EDIT_OFFSET_Y    = -40,
  CLOSE_W          = 80,
  CLOSE_H          = 22,
  CLOSE_OFFSET_X   = -12,
  CLOSE_OFFSET_Y   = 12,
}

-- ===== Strict localization helper (no display fallbacks) =====
local L = NS.L or {}
local function T(key)  -- Asserts during dev if a key is missing
  assert(L[key], "Missing locale key: " .. tostring(key))
  return L[key]
end

-- -------------------------------------------------------------------
-- Local: build the export dialog (framed edit box with a note + close)
-- -------------------------------------------------------------------
local function showDialog(parent)
  local frame = CreateFrame("Frame", "WC_Export", parent or UIParent, "BackdropTemplate")
  frame:SetSize(C.WIDTH, C.HEIGHT)
  frame:SetPoint("CENTER")
  frame:SetBackdrop({
    bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = C.EDGE_SIZE,
  })
  frame:SetBackdropColor(0, 0, 0, 0.95)

  -- Note/instructions text
  local note = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  note:SetPoint("TOPLEFT", C.PAD, C.NOTE_OFFSET_Y)
  note:SetWidth(C.WIDTH - (2 * C.PAD))
  note:SetText(T("EXPORT_NOTE"))

  -- Multiline edit box for the export payload
  local eb = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  eb:SetMultiLine(true)
  eb:SetSize(C.WIDTH - (2 * C.PAD), C.EDIT_HEIGHT)
  eb:SetPoint("TOPLEFT", C.PAD, C.EDIT_OFFSET_Y)
  eb:SetAutoFocus(true)
  eb:SetScript("OnEscapePressed", function() frame:Hide() end)

  -- Close button
  local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  close:SetSize(C.CLOSE_W, C.CLOSE_H)
  close:SetPoint("BOTTOMRIGHT", C.CLOSE_OFFSET_X, C.CLOSE_OFFSET_Y)
  close:SetText(T("DLG_CLOSE"))
  close:SetScript("OnClick", function() frame:Hide() end)

  return frame, eb
end

-- -------------------------------------------------------------------
-- Public: show the export dialog and populate it with serialized tasks
-- -------------------------------------------------------------------
function NS.ShowExport(parent)
  -- Ensure single instance
  if not NS._exp then
    NS._exp, NS._expBox = showDialog(parent or UIParent)
  end

  -- If import is open, hide it for exclusivity
  if NS._imp and NS._imp:IsShown() then
    NS._imp:Hide()
  end

  -- Build export payload: one task per line with frequency prefix
  local lines = {}
  for _, t in ipairs(NS.GetTasks()) do
    local prefix = (t.frequency == "weekly") and "w: " or "d: "
    lines[#lines + 1] = prefix .. (t.text or "")
  end

  NS._expBox:SetText(table.concat(lines, "\n"))
  NS._exp:Show()
  NS._expBox:SetFocus()
  NS._expBox:HighlightText()
end

-- -------------------------------------------------------------------
-- Public: simple Import/Export chooser (pairs with NS.ShowImport/ShowExport)
-- -------------------------------------------------------------------
function NS.ShowImportExport(parent)
  StaticPopupDialogs["WC_IE"] = {
    text = T("IE_PROMPT"),
    button1 = T("DLG_IMPORT"),
    button2 = T("DLG_EXPORT"),
    OnAccept = function() NS.ShowImport(parent or UIParent) end,
    OnCancel = function() NS.ShowExport(parent or UIParent) end,
    timeout = 0, whileDead = true, hideOnEscape = true,
  }
  StaticPopup_Show("WC_IE")
end
