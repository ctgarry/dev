-- export.lua
-- Purpose: Export UI and Import/Export chooser for WinterChecklist.
-- Scope: Creates a single-instance export dialog and a popup chooser that defers to import/export.
-- Notes: Strict localization via T(key); no inline fallbacks. Avoid magic numbers with a constants table.

local ADDON, NS = ...

-- ===== Constants (avoid magic numbers) =====
local C = {
  WIDTH            = 480,
  HEIGHT           = 360,
  PAD              = 12,
  EDGE_SIZE        = 12,
  EDIT_HEIGHT      = 260, -- unused with scrollframe, but keep as fallback
  NOTE_OFFSET_Y    = -12,
  EDIT_OFFSET_Y    = -36,
  CLOSE_W          = 80,
  CLOSE_H          = 22,
  CLOSE_OFFSET_Y   = 10,
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
  frame:SetFrameStrata("DIALOG")
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

  -- Scrollable edit area for the export payload
  local pad = C and C.PAD or 12
  local innerW = (C and C.WIDTH or 500) - (pad * 2) - 24
  local innerH = (C and C.HEIGHT or 400) - (pad * 2) - 24

  local scroll = CreateFrame("ScrollFrame", "WCL_ExportScroll", frame, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", pad, -pad)
  scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -pad, pad)

  -- REQUIRED: a sized scroll child
  local content = CreateFrame("Frame", "WCL_ExportContent", scroll)
  content:SetSize(innerW, innerH)
  scroll:SetScrollChild(content)

  local eb = CreateFrame("EditBox", "WCL_ExportEditBox", content)
  eb:SetMultiLine(true)
  eb:SetAutoFocus(true)
  eb:SetFontObject(ChatFontNormal)
  eb:SetAllPoints(content)
  eb:EnableMouse(true)
  eb:SetTextColor(1,1,1,1)
  eb:HighlightText(0,0)

  eb:SetWidth(C.WIDTH - (2 * C.PAD) - 24)
  eb:SetScript("OnEscapePressed", function() frame:Hide() end)
  eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

  if eb.SetBackdrop then
    eb:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 8, insets = {left=3,right=3,top=3,bottom=3},
    })
    eb:SetBackdropColor(0.1, 0.1, 0.1, 0.85)
  end

  -- populate text (safe if function missing)
  local text = WinterChecklist and WinterChecklist.ExportString and WinterChecklist:ExportString() or ""
  eb:SetText(text)

  scroll:SetScrollChild(eb)
  NS._expBox = eb
  NS._exp = frame
  if frame.GetName then table.insert(UISpecialFrames, frame:GetName()) end

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
