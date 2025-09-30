-- import.lua
local ADDON, NS = ...

local function showDialog(parent)
  local frame = CreateFrame("Frame", "WC_Import", parent, "BackdropTemplate")
  frame:SetSize(400, 260)
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
  note:SetJustifyH("LEFT")
  note:SetText("Import format:\n- Lines starting with 'd: ' = daily task\n- Lines starting with 'w: ' = weekly task\n- Any other line is INVALID and will abort the import.")

  local eb = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  eb:SetMultiLine(true)
  eb:SetSize(376, 150)
  eb:SetPoint("TOPLEFT", 12, -56)
  eb:SetAutoFocus(false)

  local ok = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  ok:SetSize(80,22)
  ok:SetPoint("BOTTOMRIGHT", -12, 12)
  ok:SetText("Import")
  ok:SetScript("OnClick", function()
    local text = eb:GetText() or ""

    -- Validate all lines first
    for line in text:gmatch("[^\r\n]+") do
      if not line:find("^%s*[dDwW]:%s") then
        NS.Print("Import aborted: bad line: " .. line)
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

    NS.SaveTasks(tasks)
    if NS.RefreshUI then NS.RefreshUI() end
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
    frame:Hide()
  end)

  local cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  cancel:SetSize(80,22)
  cancel:SetPoint("RIGHT", ok, "LEFT", -8, 0)
  cancel:SetText("Cancel")
  cancel:SetScript("OnClick", function() frame:Hide() end)

  return frame
end

function NS.ShowImport(parent)
  NS._imp = NS._imp or showDialog(parent)
  NS._imp:Show()
end
