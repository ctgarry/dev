-- WinterChecklist 1.5 (Classic Era) — ui_core.lua
local ADDON_NAME = ...
local ADDON = _G[ADDON_NAME] or {}
_G[ADDON_NAME] = ADDON
ADDON.UI = ADDON.UI or {}
local UI = ADDON.UI

-- Classic-safe resize helper
local function SetResizeBoundsSafe(frame, minW, minH, maxW, maxH)
    if not frame then return end
    if frame.SetResizeBounds then
        frame:SetResizeBounds(minW or 200, minH or 120, maxW or 1200, maxH or 900)
    else
        if frame.SetMinResize then pcall(frame.SetMinResize, frame, minW or 200, minH or 120) end
        if frame.SetMaxResize then pcall(frame.SetMaxResize, frame, maxW or 1200, maxH or 900) end
    end
end

function UI.CreateMainFrame(DB)
    if UI.MainFrame and UI.MainFrame.frame then return end

    local f = CreateFrame("Frame", "WC_MainFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    f:SetSize(260, 180)
    f:SetPoint(DB.pos.point or "CENTER", _G[DB.pos.rel or "UIParent"] or UIParent, DB.pos.relPoint or "CENTER", DB.pos.x or 0, DB.pos.y or 0)

    if f.SetBackdrop then
        f:SetBackdrop({ bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
                        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize=16, insets={left=4,right=4,top=4,bottom=4} })
    end

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("WinterChecklist")

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not DB.locked then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, rel, rp, x, y = self:GetPoint(1)
        DB.pos.point, DB.pos.rel, DB.pos.relPoint, DB.pos.x, DB.pos.y = p, rel and rel:GetName() or "UIParent", rp, x, y
    end)

    SetResizeBoundsSafe(f, 200, 120, 800, 600)

    UI.MainFrame = UI.MainFrame or {}
    UI.MainFrame.frame = f
    function UI.MainFrame.ApplyLock(locked)
        f:SetMovable(not locked)
        if f.SetAlpha then f:SetAlpha(locked and 0.95 or 1.0) end
    end
    function UI.MainFrame.Toggle()
        if f:IsShown() then f:Hide() else f:Show() end
    end
end
