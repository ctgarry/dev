--[[--------------------------------------------------------------------
WinterChecklist – Barebones Layout Prototype (single-file, no XML)
Purpose:
  - Show a resizable window with:
      • Title at top
      • A 3×3 "task-ish" grid in the middle:
          Col 1: one-character buttons
          Col 2: interactive checkboxes (no handlers)
          Col 3: fixed-width text labels (~25 chars each)
      • A bottom button ("Do Nothing")
  - Zero persistence / business logic. Purely for layout + styling play.
  - Retail + Classic safe (no Settings API). Minimal helpers included.

Usage:
  - Add this Lua to your addon and reference it in your .toc.
  - In game: /wclhello  → toggles the window
----------------------------------------------------------------------]]

local ADDON, NS = ...
NS = NS or {}

----------------------------------------------------------------------
-- THEME / TWEAKS (edit here to play with look & feel)
----------------------------------------------------------------------
local THEME = {
  titleText = "WinterChecklist - Layout Prototype",
  width = 480,
  height = 360,
  minW = 360,
  minH = 260,
  maxW = 900,
  maxH = 700,

  pad = { l = 12, t = 36, r = 12, b = 46 }, -- inner content padding (title+footer reserve)
  gridGapX = 10,
  gridGapY = 8,

  colWidths = { 28, 26, 280 }, -- button, checkbox, text col
  rowHeight = 24,

  fontObject = GameFontHighlight, -- apply via SetFontObject
  labelJustifyH = "LEFT",

  backdrop = { -- simple backdrop (works Retail/Classic)
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
  },

  titleColor = { r = 1, g = 0.82, b = 0 },
  labelColor = { r = 0.90, g = 0.90, b = 0.95 },
  buttonWidth = 90,
  footerHeight = 36,
}

----------------------------------------------------------------------
-- Pixel-safe helpers (use PixelUtil if available; otherwise raw SetPoint/Size)
----------------------------------------------------------------------
local PixelUtilSafe = _G.PixelUtil
local function PSetPoint(region, point, rel, relPoint, x, y)
  if PixelUtilSafe and PixelUtilSafe.SetPoint then
    PixelUtilSafe.SetPoint(region, point, rel, relPoint, x, y)
  else
    region:SetPoint(point, rel, relPoint, x, y)
  end
end
local function PSetSize(region, w, h)
  if PixelUtilSafe and PixelUtilSafe.SetSize then
    PixelUtilSafe.SetSize(region, w, h)
  else
    region:SetSize(w, h)
  end
end

----------------------------------------------------------------------
-- Simple Grid Layouter (Classic-safe; uses manual anchors)
-- Places children in rows x cols with fixed column widths & row heights.
----------------------------------------------------------------------
local function GridLayout(parent, items, rows, cols, opts)
  opts = opts or {}
  local offX, offY = opts.offsetX or 0, opts.offsetY or 0
  local gapX, gapY = opts.gapX or 0, opts.gapY or 0
  local colW = opts.colWidths or {}
  local rowH = opts.rowHeight or 20

  for r = 1, rows do
    for c = 1, cols do
      local i = (r - 1) * cols + c
      local f = items[i]
      if f then
        f:ClearAllPoints()
        local x = offX
        for k = 1, (c - 1) do
          x = x + (colW[k] or 0) + gapX
        end
        local y = -(offY + (r - 1) * (rowH + gapY))
        PSetPoint(f, "TOPLEFT", parent, "TOPLEFT", x, y)
        -- If this element should have a "suggested size", apply it:
        local w = colW[c]
        if w and w > 0 then
          PSetSize(f, w, rowH)
        else
          f:SetHeight(rowH)
        end
      end
    end
  end
end

----------------------------------------------------------------------
-- Frame factory
----------------------------------------------------------------------
local function CreatePrototypeWindow()
  if NS.ProtoFrame then
    return NS.ProtoFrame
  end

  local f = CreateFrame("Frame", "WCL_ProtoFrame", UIParent, "BackdropTemplate")
  f:SetFrameStrata("HIGH")
  f:SetClampedToScreen(true)
  f:SetResizable(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetBackdrop(THEME.backdrop)
  f:SetBackdropColor(0, 0, 0, 0.85)
  f:SetSize(THEME.width, THEME.height)
  f:SetPoint("CENTER")
  f:SetUserPlaced(true)

  -- Dragging
  f:SetScript("OnDragStart", function(self)
    self:StartMoving()
  end)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
  end)

  -- Resize bounds (robust across Retail/Classic)
  local minW = THEME.minW or 360
  local minH = THEME.minH or 260
  local maxW = THEME.maxW
  local maxH = THEME.maxH

  if f.SetResizeBounds then
    if maxW and maxH then
      f:SetResizeBounds(minW, minH, maxW, maxH)
    else
      f:SetResizeBounds(minW, minH)
    end
  else
    if f.SetMinResize then
      f:SetMinResize(minW, minH)
    end
    if f.SetMaxResize and maxW and maxH then
      f:SetMaxResize(maxW, maxH)
    end
  end

  -- Title (use CreateFontString with layer only; set font via SetFontObject)
  local title = f:CreateFontString(nil, "OVERLAY")
  title:SetFontObject(THEME.fontObject)
  title:SetText(THEME.titleText)
  title:SetJustifyH("CENTER")
  title:SetTextColor(THEME.titleColor.r, THEME.titleColor.g, THEME.titleColor.b)
  PSetPoint(title, "TOPLEFT", f, "TOPLEFT", THEME.pad.l, -8)
  PSetPoint(title, "TOPRIGHT", f, "TOPRIGHT", -THEME.pad.r, -8)

  -- Close
  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)

  -- Content container (pads inside frame; reserve footer space)
  local content = CreateFrame("Frame", nil, f)
  PSetPoint(content, "TOPLEFT", f, "TOPLEFT", THEME.pad.l, -THEME.pad.t)
  PSetPoint(content, "BOTTOMRIGHT", f, "BOTTOMRIGHT", -THEME.pad.r, THEME.footerHeight)

  -- Footer button
  local footer = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  footer:SetText("Do Nothing")
  footer:SetWidth(THEME.buttonWidth)
  footer:SetHeight(22)
  footer:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)

  --------------------------------------------------------------------
  -- Build the 3×3 "task list" grid
  --------------------------------------------------------------------
  local rows = {
    { key = "A", checked = false, label = "Gather 10 Peacebloom" },
    { key = "B", checked = true, label = "Cook 5 Spice Bread" },
    { key = "C", checked = false, label = "Visit the Flight Master" },
    { key = "D", checked = false, label = "Buy vials in trade district" },
    { key = "E", checked = true, label = "Smelt 20 Copper Bars" },
    { key = "F", checked = false, label = "Train Journeyman Cooking" },
    { key = "G", checked = false, label = "Set HS to Goldshire" },
    { key = "H", checked = false, label = "Check mailbox for mats" },
    { key = "I", checked = false, label = "Turn in starter quests" },
  }

  local created = {}
  local total = 3 * 3

  for i = 1, total do
    local r = rows[i]
    -- Col 1: one-character button
    local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    btn:SetText(r and (r.key or "?") or "?")
    btn:SetHeight(THEME.rowHeight)
    table.insert(created, btn)

    -- Col 2: checkbox
    local cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    cb:SetChecked(r and r.checked or false)
    cb:Disable() -- inert; comment to interact
    cb:SetAlpha(0.95)
    table.insert(created, cb)

    -- Col 3: fixed-width label
    local lbl = content:CreateFontString(nil, "OVERLAY")
    lbl:SetFontObject(THEME.fontObject)
    lbl:SetTextColor(THEME.labelColor.r, THEME.labelColor.g, THEME.labelColor.b)
    lbl:SetJustifyH(THEME.labelJustifyH)
    lbl:SetText(r and r.label or "")
    lbl:SetWordWrap(false)
    table.insert(created, lbl)
  end

  -- Apply grid layout
  GridLayout(content, created, 3, 3, {
    offsetX = 0,
    offsetY = 0,
    gapX = THEME.gridGapX,
    gapY = THEME.gridGapY,
    colWidths = THEME.colWidths,
    rowHeight = THEME.rowHeight,
  })

  -- Store refs
  f.Title = title
  f.Content = content
  f.Footer = footer
  f.Cells = created

  f:Hide() -- start hidden so the first /wclhello toggles it visible
  NS.ProtoFrame = f
  return f
end

----------------------------------------------------------------------
-- Slash command: /wclhello
----------------------------------------------------------------------
SLASH_WCLHELLO1 = "/wclhello"
SlashCmdList.WCLHELLO = function(msg)
  -- Build (or fetch) your prototype frame using the actual constructor in this file
  local f = CreatePrototypeWindow()
  if not f then
    print("|cffff7f00WinterChecklist:|r UI not ready (no frame).")
    return
  end

  -- If user typed "toggle" (or nothing), do a smart toggle; otherwise force show
  local cmd = (msg or ""):lower():match("^%s*(%S*)")
  if cmd == "hide" then
    f:Hide()
  elseif cmd == "show" then
    f:Show()
    if f.Raise then
      f:Raise()
    end
  else
    if f:IsShown() then
      f:Hide()
    else
      f:Show()
      if f.Raise then
        f:Raise()
      end
    end
  end
end
