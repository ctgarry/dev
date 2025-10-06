-- File: ui_extras.lua
-- Purpose: Shared popups and small helpers (no minimap or options UI here).
-- Scope: Independent helpers used by options/minor flows.

local ADDON, NS = ...

-- Strict localization
local function T(key)
  local L = NS.L or {}
  return (L and L[key]) or key
end

-- Close any auxiliary popouts so only one is visible at a time.
function NS.ClosePopouts(except)
  -- export dialog
  if except ~= "export" and NS._exp and NS._exp:IsShown() then NS._exp:Hide() end
  -- import dialog
  if except ~= "import" and NS._imp and NS._imp:IsShown() then NS._imp:Hide() end
  -- help popup
  if except ~= "help" and NS.__help and NS.__help:IsShown() then NS.__help:Hide() end
  -- any StaticPopup (Add/edit prompt)
  if except ~= "prompt" and StaticPopup_Hide then
    for i = 1, 4 do
      local f = _G["StaticPopup"..i]
      if f and f:IsShown() then f:Hide() end
    end
  end
end

-- ===== Copy-to-clipboard Popup for links =====
StaticPopupDialogs = StaticPopupDialogs or {}

StaticPopupDialogs["WCL_COPY_LINK"] = {
    text = T("COPY_LINK_TEXT") or "Copy the link below:",
    button1 = OKAY,
    hasEditBox = true,
    whileDead = true,
    preferredIndex = 3,
    OnShow = function(self, data)
        local eb = self.editBox
        eb:SetText(data and data.url or "")
        eb:SetFocus()
        eb:HighlightText()
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    timeout = 0,
    hideOnEscape = true,
}

function NS.ShowCopyLinkPopup(url)
    if not StaticPopup_Show then return end
    StaticPopup_Show("WCL_COPY_LINK", nil, nil, { url = url or "" })
end

-- ===== Confirm Copy Profile Tasks =====
StaticPopupDialogs["WCL_COPY_CONFIRM"] = {
    text = T("COPY_CONFIRM_TITLE") or "Copy profile tasks?",
    button1 = YES,
    button2 = NO,
    whileDead = true,
    preferredIndex = 3,
    OnShow = function(self, data)
        self.text:SetText((data and data.msg) or T("COPY_CONFIRM_TITLE") or "Copy profile tasks?")
    end,
    OnAccept = function(self, data)
        local srcTasks = data and data.srcTasks
        if not srcTasks or #srcTasks == 0 then return end
        local db = NS.EnsureDB and NS.EnsureDB() or nil
        if not db then return end
        -- Shallow copy to avoid sharing tables; deep copy if available
        if NS.DeepCopy then
            db.tasks = NS.DeepCopy(srcTasks)
        else
            db.tasks = {}
            for i, t in ipairs(srcTasks) do
                local nt = {}
                for k,v in pairs(t) do nt[k] = v end
                table.insert(db.tasks, nt)
            end
        end
        if NS.RefreshUI then NS.RefreshUI() end
        if NS.Print then NS.Print(T("MSG_PROFILE_COPIED") or "Copied tasks from selected profile.") end
    end,
    timeout = 0,
    hideOnEscape = true,
}
-- ===== Help popout (anchored beside main, ESC to close) =====
NS.C = NS.C or {}; local C = NS.C
C.HELP_W        = C.HELP_W        or 420
C.HELP_H        = C.HELP_H        or 320
C.HELP_OFFSET_X = C.HELP_OFFSET_X or 12
C.HELP_OFFSET_Y = C.HELP_OFFSET_Y or 0

function NS.ToggleHelp(anchor)
  NS.__help = NS.__help or CreateFrame("Frame", "WC_HelpPopup", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  local f = NS.__help
  if not f._built then
    f:SetSize(C.HELP_W, C.HELP_H)
    if f.SetBackdrop then
      f:SetBackdrop({ bgFile="Interface/Tooltips/UI-Tooltip-Background",
                      edgeFile="Interface/Tooltips/UI-Tooltip-Border", edgeSize=12,
                      insets={left=4,right=4,top=4,bottom=4}})
      f:SetBackdropColor(0,0,0,0.85)
    end
    f:EnableMouse(true); f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -10)
    scroll:SetPoint("BOTTOMRIGHT", -28, 10)
    local body = CreateFrame("Frame", nil, scroll); scroll:SetScrollChild(body)
    body:SetSize(C.HELP_W-38, C.HELP_H-28)

    local txt = body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    txt:SetPoint("TOPLEFT"); txt:SetWidth(C.HELP_W-38); txt:SetJustifyH("LEFT")
    f._text = txt

    table.insert(UISpecialFrames, "WC_HelpPopup") -- ESC to close
    f._built = true
  end

  local content = (NS.L and NS.L.HELP_BODY) or "Help text not localized yet."
  f._text:SetText(content)

  local parent = anchor or _G.WC_MainFrame or UIParent
  f:ClearAllPoints()
  f:SetPoint("TOPLEFT", parent, "TOPRIGHT", C.POPOUT_OFFSET_X or C.HELP_OFFSET_X, C.POPOUT_OFFSET_Y or C.HELP_OFFSET_Y)
  f:SetShown(not f:IsShown())
end