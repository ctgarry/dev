
local ADDON_NAME = ...
local ADDON = _G[ADDON_NAME] or {}
_G[ADDON_NAME] = ADDON
ADDON.Minimap = ADDON.Minimap or {}
local M = ADDON.Minimap

local ICON_PATH = "Interface\\AddOns\\WinterChecklist\\media\\minimap.blp"

-- Tuned for CTG's Classic Era UI (80% scale, round minimap)
local RIM_ADJUST      = 25
local CENTER_OFFSET_X = 0
local CENTER_OFFSET_Y = 0

local RING_SIZE       = 54
local RING_OFFSET_X   = 10
local RING_OFFSET_Y   = -10

local ICON_SIZE       = 24
local ICON_OFFSET_X   = 0
local ICON_OFFSET_Y   = 0

local function GetRadius(btn)
    local w = Minimap:GetWidth()
    local h = Minimap:GetHeight()
    local base = (math.min(w, h) / 2)
    local halfBtn = (btn and btn:GetWidth() or 31) / 2
    return base - halfBtn + RIM_ADJUST
end

local function GetOrigin()
    local mx, my = Minimap:GetCenter()
    return mx + CENTER_OFFSET_X, my + CENTER_OFFSET_Y
end

local function SetPos(frame, angle)
    local r = GetRadius(frame)
    local rad = math.rad(angle or 225)
    local mx, my = GetOrigin()
    local x = math.cos(rad) * r
    local y = math.sin(rad) * r
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", mx + x, my + y)
end

local function UpdateTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("WinterChecklist", 1, 1, 1)
    GameTooltip:AddLine("Left-click: Show/Hide", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Right-click: Lock/Unlock", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Shift-Right: Hide Minimap Button", 0.8, 0.8, 0.8)
    local locked = _G.WinterChecklistDB and _G.WinterChecklistDB.locked
    GameTooltip:AddLine("Anchor: " .. ((locked and "|cffff5555Locked|r") or "|cff55ff55Unlocked|r"))
    GameTooltip:Show()
end

function M.Boot(DB)
    if M.button then
        if M.UpdateVisibility then M.UpdateVisibility(DB.minimap and DB.minimap.hide) end
        return
    end

    local b = CreateFrame("Button", "WC_MinimapButton", Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetClampedToScreen(true)

    local ring = b:CreateTexture(nil, "OVERLAY")
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    ring:SetSize(RING_SIZE, RING_SIZE)
    ring:SetPoint("CENTER", b, "CENTER", RING_OFFSET_X, RING_OFFSET_Y)

    local icon = b:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture(ICON_PATH)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("CENTER", b, "CENTER", ICON_OFFSET_X, ICON_OFFSET_Y)
    b.icon = icon

    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnEnter", UpdateTooltip)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    b:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if ADDON.UI and ADDON.UI.MainFrame and ADDON.UI.MainFrame.Toggle then
                ADDON.UI.MainFrame.Toggle()
            end
        elseif button == "RightButton" then
            if IsShiftKeyDown() then
                DB.minimap = DB.minimap or {}
                DB.minimap.hide = not DB.minimap.hide
                if ADDON.Minimap and ADDON.Minimap.UpdateVisibility then
                    ADDON.Minimap.UpdateVisibility(DB.minimap.hide)
                end
                if ADDON.Tag then ADDON.Tag("Minimap button " .. (DB.minimap.hide and "hidden" or "shown")) end
            else
                if ADDON.LockCmd then ADDON.LockCmd("toggle") end
            end
        end
    end)

    b:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function(self)
            local scale = Minimap:GetEffectiveScale()
            local cx, cy = GetCursorPosition()
            cx, cy = cx / scale, cy / scale
            local mx, my = GetOrigin()
            local angle = math.deg(math.atan2(cy - my, cx - mx)) % 360
            DB.minimap = DB.minimap or {}
            DB.minimap.angle = angle
            SetPos(self, angle)
        end)
    end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

    SetPos(b, DB.minimap and DB.minimap.angle or 225)

    M.button = b
    function M.UpdateVisibility(hidden)
        if hidden then b:Hide() else b:Show() end
    end
    M.UpdateVisibility(DB.minimap and DB.minimap.hide)
end
