-- File: ui_core.lua
-- Purpose: Main addon UI (task list, filter, buttons, etc).
-- Scope: Core UI logic and layout; no popouts or extras here.
-- Dependencies: ui_extras.lua
-- Notes: Heavy use of WoW's XML templates for buttons, scrollframes, etc.
--        Minimap button and options panel are in separate files.
--        This file is large; see section headers to navigate.    

local ADDON, NS = ...

-- Namespace bootstrap (create once if needed) + fast local alias
NS = NS or {}
NS.C = NS.C or {}
local C = NS.C

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
C.HELP_W        = C.HELP_W        or 420
C.HELP_H        = C.HELP_H        or 320
C.HELP_OFFSET_X = C.HELP_OFFSET_X or 12
C.HELP_OFFSET_Y = C.HELP_OFFSET_Y or 0

function NS.ShowHelp(anchor)
  -- Close other popouts, but keep "help" open
  if NS.ClosePopouts then NS.ClosePopouts("help") end

  -- Build once
  NS.__help = NS.__help or CreateFrame("Frame", "WC_HelpPopup", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  local f = NS.__help
  if not f._built then
    f:SetSize(C.HELP_W or 420, C.HELP_H or 320)
    if f.SetBackdrop then
      f:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets   = { left=4, right=4, top=4, bottom=4 }
      })
      f:SetBackdropColor(0,0,0,0.85)
    end

    f:EnableMouse(true); f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -10)
    scroll:SetPoint("BOTTOMRIGHT", -28, 10)

    local body = CreateFrame("Frame", nil, scroll)
    scroll:SetScrollChild(body)
    body:SetSize((C.HELP_W or 420) - 38, (C.HELP_H or 320) - 28)

    local txt = body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    txt:SetPoint("TOPLEFT")
    txt:SetWidth((C.HELP_W or 420) - 38)
    txt:SetJustifyH("LEFT")
    f._text = txt

    table.insert(UISpecialFrames, "WC_HelpPopup") -- ESC closes
    f._built = true
  end

  -- Position beside main frame (or UIParent fallback)
  local parent = anchor or _G.WC_Main or UIParent
  f:ClearAllPoints()
  f:SetPoint(
    "TOPLEFT", parent, "TOPRIGHT",
    (C.POPOUT_OFFSET_X or C.HELP_OFFSET_X or 12),
    (C.POPOUT_OFFSET_Y or C.HELP_OFFSET_Y or 0)
  )

  -- Update body and show
  f._text:SetText((NS.L and NS.L.HELP_BODY) or "Help text not localized yet.")
  f:Show()
  if f.Raise then f:Raise() end
end

-- Popout anchoring defaults (don’t recreate NS.C; just read/assign fields)
local C = NS.C
C.POPOUT_OFFSET_X = C.POPOUT_OFFSET_X or 12
C.POPOUT_OFFSET_Y = C.POPOUT_OFFSET_Y or 0

function NS.ShowImport(anchor)
  NS.ClosePopouts("import")
  local parent  = anchor or _G.WC_Main or UIParent
  local f = _G.WC_ImportPopup
  if not f then
    f = CreateFrame("Frame", "WC_ImportPopup", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    f:SetFrameStrata("DIALOG")
    f:SetSize(380, 300)
    if f.SetBackdrop then
      f:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets   = { left=4,right=4,top=4,bottom=4 }
      })
      f:SetBackdropColor(0,0,0,0.9)
    end

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText((NS.L and NS.L.DLG_IMPORT) or "Import")

    -- Multiline edit box in a UIPanelScrollFrameTemplate (no ghosting/char counter)
    local sf  = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 16, -40)
    sf:SetPoint("BOTTOMRIGHT", -16, 50)

    local edit = CreateFrame("EditBox", nil, sf)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(GameFontHighlightSmall)
    edit:SetTextColor(1,1,1,1)
    edit:SetWidth(sf:GetWidth())         -- initial width; keep in sync below
    edit:SetText("")                     -- start empty
    sf:SetScrollChild(edit)
    f._edit = edit

    -- Keep edit width synced to the scrollframe’s visible width
    sf:HookScript("OnSizeChanged", function(self, w) edit:SetWidth(w or 330) end)

    -- Buttons
    local ok = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    ok:SetSize(80, 22)
    ok:SetPoint("BOTTOMRIGHT", -12, 12)
    ok:SetText(OKAY)
    ok:SetScript("OnClick", function()
      local txt = (f._edit and f._edit:GetText()) or ""
      local tasks, err = NS.ParseImport and NS.ParseImport(txt)
      if not tasks then
        if NS.Print then
          NS.Print(((NS.L and NS.L.IMPORT_ABORT_BADLINE) and NS.L.IMPORT_ABORT_BADLINE:format(err or "bad line"))
                    or ("Import aborted: "..tostring(err)))
        end
        return
      end
      local d = (NS.EnsureDB and NS.EnsureDB()) or WinterChecklistDB
      d.tasks = d.tasks or {}
      for _, t in ipairs(tasks) do table.insert(d.tasks, t) end
      if NS.FilterAndRebuildList and _G.WC_Main then NS.FilterAndRebuildList(_G.WC_Main) end
      f:Hide()
    end)

    local cancel = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancel:SetSize(80, 22)
    cancel:SetPoint("RIGHT", ok, "LEFT", -8, 0)
    cancel:SetText(CANCEL)
    cancel:SetScript("OnClick", function() f:Hide() end)

    table.insert(UISpecialFrames, "WC_ImportPopup") -- ESC closes
  end

  f:ClearAllPoints()
  f:SetPoint("TOPLEFT", parent, "TOPRIGHT", C.POPOUT_OFFSET_X or 12, C.POPOUT_OFFSET_Y or 0)
  f:Show()
  if f._edit then f._edit:SetFocus() end
end

function NS.ShowExport(anchor)
  NS.ClosePopouts("export")
  local parent = anchor or _G.WC_Main or UIParent
  local f = _G.WC_ExportPopup
  if not f then
    f = CreateFrame("Frame", "WC_ExportPopup", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    f:SetFrameStrata("DIALOG")
    f:SetSize(380, 300)
    if f.SetBackdrop then
      f:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets   = { left=4,right=4,top=4,bottom=4 }
      })
      f:SetBackdropColor(0,0,0,0.9)
    end

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText((NS.L and NS.L.DLG_EXPORT) or "Export")

    -- Multiline edit box in a UIPanelScrollFrameTemplate (same pattern as Import)
    local sf  = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 16, -40)
    sf:SetPoint("BOTTOMRIGHT", -16, 50)

    local edit = CreateFrame("EditBox", nil, sf)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(GameFontHighlightSmall)
    edit:SetTextColor(1,1,1,1)
    edit:SetWidth(sf:GetWidth())
    edit:SetText(NS.BuildExport and NS.BuildExport() or "")
    sf:SetScrollChild(edit)
    f._edit = edit

    sf:HookScript("OnSizeChanged", function(self, w) edit:SetWidth(w or 330) end)

    local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    close:SetSize(80,22)
    close:SetPoint("BOTTOMRIGHT", -12, 12)
    close:SetText(CLOSE)
    close:SetScript("OnClick", function() f:Hide() end)

    table.insert(UISpecialFrames, "WC_ExportPopup")
  else
    -- refresh content on reopen
    if f._edit and NS.BuildExport then f._edit:SetText(NS.BuildExport()) end
  end

  f:ClearAllPoints()
  f:SetPoint("TOPLEFT", parent, "TOPRIGHT", C.POPOUT_OFFSET_X or 12, C.POPOUT_OFFSET_Y or 0)
  f:Show()
  if f._edit then f._edit:HighlightText() end
end
