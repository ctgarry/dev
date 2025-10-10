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
  eb:SetHeight(C.EDIT_HEIGHT or 260)
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

-- EXPORT ONLY: robust ShowExport for Classic (uses the same pattern as /wclx)

-- (Optional) small helper to build the export text using your addon,
-- falling back to SavedVariables if needed.
local function WCL_BuildExportText()
  if _G.WinterChecklist and type(_G.WinterChecklist.ExportString) == "function" then
    local ok, out = pcall(function() return _G.WinterChecklist:ExportString() end)
    if ok and type(out) == "string" and #out > 0 then
      return out
    end
  end
  -- Fallback: summarize SV
  local lines = {}
  lines[#lines+1] = "WinterChecklist — Export summary (fallback)"
  if type(_G.WinterChecklistDB) == "table" then
    local tasks = _G.WinterChecklistDB.tasks
    lines[#lines+1] = "SavedVariables: present"
    if type(tasks) == "table" then
      lines[#lines+1] = ("Tasks count: %d"):format(#tasks)
      for i, t in ipairs(tasks) do
        local title = (type(t)=="table" and t.title) or "(untitled)"
        lines[#lines+1] = (" - %d. %s"):format(i, tostring(title))
        if i >= 50 then
          lines[#lines+1] = " ... (truncated)"
          break
        end
      end
    else
      lines[#lines+1] = "No tasks array at WinterChecklistDB.tasks"
    end
  else
    lines[#lines+1] = "SavedVariables table WinterChecklistDB not found."
  end
  return table.concat(lines, "\n")
end

function WinterChecklist:ShowExport()
  -- 1) Ensure the named frame is a real Frame (not a table/function from earlier code)
  if _G.WC_ExportPopup and (type(_G.WC_ExportPopup) ~= "table") and _G.WC_ExportPopup.GetObjectType then
    -- it's a Region; keep it
  else
    _G.WC_ExportPopup = nil
  end

  local frame = _G.WC_ExportPopup
  if not frame then
    frame = CreateFrame("Frame", "WC_ExportPopup", UIParent, "BackdropTemplate")
    frame:SetSize(640, 480)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 12, insets = { left=3, right=3, top=3, bottom=3 },
    })
    frame:SetBackdropColor(0,0,0,0.9)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
    frame:Hide()
    _G.WC_ExportPopup = frame

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -10)
    title:SetText("WinterChecklist — Export")

    -- Close
    local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -10)
    close:SetSize(80, 22)
    close:SetText("Close")
    close:SetScript("OnClick", function() frame:Hide() end)

    -- 2) ScrollFrame + sized scroll child (Classic requirement)
    local pad = 12
    local scroll = CreateFrame("ScrollFrame", "WCL_ExportScroll", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", pad, -40)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -pad, pad)

    local innerW = 640 - (pad * 2) - 24
    local innerH = 480 - 40 - pad - 24
    local content = CreateFrame("Frame", "WCL_ExportContent", scroll)
    content:SetSize(innerW, innerH)
    scroll:SetScrollChild(content)

    -- 3) EditBox anchored to the content; explicit height so it renders
    local eb = CreateFrame("EditBox", "WCL_ExportEditBox", content)
    eb:SetAllPoints(content)
    eb:SetMultiLine(true)
    eb:SetAutoFocus(true)
    eb:SetFontObject(ChatFontNormal)
    eb:EnableMouse(true)
    eb:SetTextColor(1,1,1,1)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    -- Smart-ish height without GetStringHeight (not available on EditBox in Classic)
    eb.ResizeToText = function(self)
      self:ClearFocus()
      self:SetWidth(innerW)
      -- simple line count * line height
      local text = self:GetText() or ""
      local lines = 1
      for _ in text:gmatch("\n") do lines = lines + 1 end
      local fobj = self:GetFontObject()
      local _, fontSize = fobj and fobj:GetFont()
      fontSize = fontSize or 14
      local perLine = fontSize + 4
      local h = (lines * perLine) + 20
      self:SetHeight(math.max(260, h))
    end
  end

  -- 4) Populate and show
  local text = WCL_BuildExportText()
  WCL_ExportEditBox:SetText(text)
  WCL_ExportEditBox:ResizeToText()

  frame:Show()
  WCL_ExportEditBox:SetFocus()
  WCL_ExportEditBox:HighlightText()
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

