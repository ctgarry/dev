-- File: minimap.lua
-- Purpose: Minimap button and drag/angle math.
-- Scope: UI helper module; no globals.

local ADDON, NS = ...
NS.Minimap = NS.Minimap or {}
local M = NS.Minimap

-- Constants (avoid magic numbers)
NS = NS or {}
NS.C = NS.C or {}                      -- shared app-wide constants
local C = NS.C
C.PAD              = C.PAD or 12
C.TOP_BAR_H        = C.TOP_BAR_H or 48
C.POPOUT_OFFSET_X  = C.POPOUT_OFFSET_X or 12
C.POPOUT_OFFSET_Y  = C.POPOUT_OFFSET_Y or 0

-- Minimap-only constants live under C.MINIMAP
C.MINIMAP = C.MINIMAP or {}
local CM = C.MINIMAP

CM.ICON_PATH        = CM.ICON_PATH        or "Interface\\AddOns\\WinterChecklist\\img\\minimap.blp"

CM.RIM_ADJUST       = CM.RIM_ADJUST       or 25
CM.CENTER_OFFSET_X  = CM.CENTER_OFFSET_X  or 0
CM.CENTER_OFFSET_Y  = CM.CENTER_OFFSET_Y  or 0

CM.RING_SIZE        = CM.RING_SIZE        or 54
CM.RING_OFFSET_X    = CM.RING_OFFSET_X    or 10
CM.RING_OFFSET_Y    = CM.RING_OFFSET_Y    or -10

CM.ICON_SIZE        = CM.ICON_SIZE        or 24
CM.ICON_OFFSET_X    = CM.ICON_OFFSET_X    or 0
CM.ICON_OFFSET_Y    = CM.ICON_OFFSET_Y    or 0




-- Background disc behind the icon
CM.BACK_W        = CM.BACK_W        or 20
CM.BACK_H        = CM.BACK_H        or 20
CM.BACK_OFFSET_X = CM.BACK_OFFSET_X or 7
CM.BACK_OFFSET_Y = CM.BACK_OFFSET_Y or -5
local function GetRadius(btn)
    local w = Minimap:GetWidth()
    local h = Minimap:GetHeight()
    local base = (math.min(w, h) / 2)
    local halfBtn = (btn and btn:GetWidth() or 31) / 2
    return base - halfBtn + CM.RIM_ADJUST
end

local function GetOrigin()
    local mx, my = Minimap:GetCenter()
    return mx + CM.CENTER_OFFSET_X, my + CM.CENTER_OFFSET_Y
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

-- Ensure the minimap button shows/hides consistently
function M.UpdateVisibility(hiddenFlag)
  local btn = M.button
  if not btn then return end

  -- Prefer DB fields if present, otherwise use the argument
  local hidden = hiddenFlag
  local db = NS.EnsureDB and NS.EnsureDB() or nil
  if db then
    if db.showMinimap ~= nil then hidden = (db.showMinimap == false) end
    if db.minimap and db.minimap.hide ~= nil then hidden = db.minimap.hide end
  end

  if hidden then btn:Hide() else btn:Show() end
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

    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    local ring = b:CreateTexture(nil, "OVERLAY")
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    ring:SetSize(CM.RING_SIZE, CM.RING_SIZE)
    ring:SetPoint("CENTER", b, "CENTER", CM.RING_OFFSET_X, CM.RING_OFFSET_Y)

    
    -- Background disc (ported from ui_extras style)
    local back = b:CreateTexture(nil, "BACKGROUND")
    back:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    back:SetSize(CM.BACK_W, CM.BACK_H)
    back:SetPoint("CENTER", b, "CENTER", CM.BACK_OFFSET_X, CM.BACK_OFFSET_Y)

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(CM.ICON_PATH)
    icon:SetSize(CM.ICON_SIZE, CM.ICON_SIZE)
    icon:SetPoint("CENTER", b, "CENTER", CM.ICON_OFFSET_X, CM.ICON_OFFSET_Y)
    b.icon = icon

    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnEnter", UpdateTooltip)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    b:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if NS.UI and NS.UI.frame then
                NS.UI.frame:SetShown(not NS.UI.frame:IsShown())
                local d = NS.EnsureDB(); d.window = d.window or { w=460, h=500, x=0, y=0, shown=true }
                d.window.shown = NS.UI.frame:IsShown()
            end
        elseif button == "RightButton" then
            if IsShiftKeyDown() then
                DB.minimap = DB.minimap or {}
                DB.minimap.hide = not DB.minimap.hide
                if M.UpdateVisibility then M.UpdateVisibility(DB.minimap.hide) end
            else
                if NS.LockCmd then NS.LockCmd("toggle") end
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
    M.UpdateVisibility(DB.minimap and DB.minimap.hide)
end
