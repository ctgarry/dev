-- export.lua
local ADDON, NS = ...

local function showDialog(parent)
  local frame = CreateFrame("Frame", "WC_Export", parent, "BackdropTemplate")
  frame:SetSize(400, 240)
  frame:SetPoint("CENTER")
  frame:SetBackdrop({
    bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 12,
  })
  frame:SetBackdropColor(0,0,0,0.95)

  local note = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  note:SetPoint("TOPLEFT", 12, -12)
  note:SetWidth(376)
  note:SetText("Press Ctrl-A then Ctrl-C to copy. Paste anywhere to save.")

  local eb = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  eb:SetMultiLine(true)
  eb:SetSize(376, 150)
  eb:SetPoint("TOPLEFT", 12, -40)
  eb:SetAutoFocus(true)
  eb:SetScript("OnEscapePressed", function() frame:Hide() end)

  local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  close:SetSize(80,22)
  close:SetPoint("BOTTOMRIGHT", -12, 12)
  close:SetText("Close")
  close:SetScript("OnClick", function() frame:Hide() end)

  return frame, eb
end

function NS.ShowExport(parent)
  -- ensure single instance
  if not NS._exp then
    NS._exp, NS._expBox = showDialog(parent or UIParent)
  end

  -- if import is open, hide it for exclusivity
  if NS._imp and NS._imp:IsShown() then NS._imp:Hide() end

  local lines = {}
  for _, t in ipairs(NS.GetTasks()) do
    local prefix = (t.frequency == "weekly") and "w: " or "d: "
    lines[#lines+1] = prefix .. (t.text or "")
  end
  NS._expBox:SetText(table.concat(lines, "\n"))
  NS._exp:Show()
  NS._expBox:SetFocus()
  NS._expBox:HighlightText()
end

-- Simple chooser that pairs with import
function NS.ShowImportExport(parent)
  StaticPopupDialogs["WC_IE"] = {
    text = "Import or Export?",
    button1 = "Import",
    button2 = "Export",
    OnAccept = function() NS.ShowImport(parent or UIParent) end,
    OnCancel = function() NS.ShowExport(parent or UIParent) end,
    timeout = 0, whileDead = true, hideOnEscape = true,
  }
  StaticPopup_Show("WC_IE")
end
