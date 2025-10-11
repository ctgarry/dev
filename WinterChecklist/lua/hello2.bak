--[[--------------------------------------------------------------------
WinterChecklist – Scrollable Layout Prototype (single-file, no XML)
Purpose:
  - Upgrade of the basic prototype:
      • Resizable window with title + close button
      • Scrollable area showing ALL 9 rows (3 columns): [A..I] button, checkbox, label
      • Alternating row backgrounds for readability
      • Bottom action button
  - Classic-safe: uses UIPanelScrollFrameTemplate (available in Classic). No ScrollBox required.
  - Still inert: no persistence or gameplay logic.

Usage:
  - Add this Lua to your addon and reference it in your .toc.
  - In game: /wclhello2  → toggles the window
----------------------------------------------------------------------]]

local ADDON, NS = ...
NS = NS or {}

----------------------------------------------------------------------
-- THEME / TWEAKS
----------------------------------------------------------------------
local THEME = {
  titleText      = "WinterChecklist - Scrollable Prototype",
  width          = 520,
  height         = 380,
  minW = 380, minH = 280,
  maxW = 1000, maxH = 800,

  pad            = { l=12, t=36, r=12, b=46 },
  gridGapX       = 10,
  gridGapY       = 6,

  colWidths      = { 32, 26, 340 },
  rowHeight      = 26,

  fontObject     = GameFontHighlight,
  labelJustifyH  = "LEFT",

  backdrop = {
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left=8, right=8, top=8, bottom=8 }
  },

  titleColor     = { r=1, g=0.82, b=0 },
  labelColor     = { r=0.90, g=0.90, b=0.95 },
  buttonWidth    = 110,
  footerHeight   = 40,

  rowColorA      = { r=1, g=1, b=1, a=0.04 },
  rowColorB      = { r=1, g=1, b=1, a=0.10 },
}

----------------------------------------------------------------------
-- Pixel-safe helpers
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
-- Simple Grid Layouter for fixed-size cells
----------------------------------------------------------------------
local function GridLayout(parent, items, rows, cols, opts)
  opts = opts or {}
  local offX, offY = opts.offsetX or 0, opts.offsetY or 0
  local gapX, gapY = opts.gapX or 0, opts.gapY or 0
  local colW       = opts.colWidths or {}
  local rowH       = opts.rowHeight or 20

  for r = 1, rows do
    for c = 1, cols do
      local i = (r-1)*cols + c
      local f = items[i]
      if f then
        f:ClearAllPoints()
        local x = offX
        for k = 1, (c-1) do x = x + (colW[k] or 0) + gapX end
        local y = -(offY + (r-1) * (rowH + gapY))
        PSetPoint(f, "TOPLEFT", parent, "TOPLEFT", x, y)
        local w = colW[c]
        if w and w > 0 then PSetSize(f, w, rowH) else f:SetHeight(rowH) end
      end
    end
  end
end

----------------------------------------------------------------------
-- Frame factory
----------------------------------------------------------------------
local function CreateScrollablePrototype()
  if NS.ScrollProtoFrame then return NS.ScrollProtoFrame end

  local f = CreateFrame("Frame", "WCL_ScrollProtoFrame", UIParent, "BackdropTemplate")
  f:SetFrameStrata("HIGH")
  f:SetClampedToScreen(true)
  f:SetResizable(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetBackdrop(THEME.backdrop)
  f:SetBackdropColor(0,0,0,0.88)
  f:SetSize(THEME.width, THEME.height)
  f:SetPoint("CENTER")
  f:SetUserPlaced(true)

  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)

  -- Resize bounds
  local minW = THEME.minW or 360
  local minH = THEME.minH or 260
  local maxW = THEME.maxW
  local maxH = THEME.maxH
  if f.SetResizeBounds then
    if maxW and maxH then f:SetResizeBounds(minW, minH, maxW, maxH) else f:SetResizeBounds(minW, minH) end
  else
    if f.SetMinResize then f:SetMinResize(minW, minH) end
    if f.SetMaxResize and maxW and maxH then f:SetMaxResize(maxW, maxH) end
  end

  -- Title
  local title = f:CreateFontString(nil, "OVERLAY")
  title:SetFontObject(THEME.fontObject)
  title:SetText(THEME.titleText)
  title:SetJustifyH("CENTER")
  title:SetTextColor(THEME.titleColor.r, THEME.titleColor.g, THEME.titleColor.b)
  PSetPoint(title, "TOPLEFT",  f, "TOPLEFT",  THEME.pad.l, -8)
  PSetPoint(title, "TOPRIGHT", f, "TOPRIGHT", -THEME.pad.r, -8)

  -- Close
  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)

  -- Footer button
  local footer = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  footer:SetText("Do Nothing")
  footer:SetWidth(THEME.buttonWidth)
  footer:SetHeight(22)
  footer:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)

  -- Scrollable content area
  local container = CreateFrame("Frame", nil, f)
  PSetPoint(container, "TOPLEFT",     f, "TOPLEFT",     THEME.pad.l, -THEME.pad.t)
  PSetPoint(container, "BOTTOMRIGHT", f, "BOTTOMRIGHT", -THEME.pad.r, THEME.footerHeight)

  local scroll = CreateFrame("ScrollFrame", "WCL_ScrollProto_SF", container, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT")
  scroll:SetPoint("BOTTOMRIGHT")

  local scrollChild = CreateFrame("Frame", nil, scroll)
  scroll:SetScrollChild(scrollChild)
  scrollChild:SetPoint("TOPLEFT")
  scrollChild:SetPoint("TOPRIGHT")

  -- Row data (9 items)
  local rows = {
    { key="A", checked=false, label="Gather 10 Peacebloom"      },
    { key="B", checked=true,  label="Cook 5 Spice Bread"        },
    { key="C", checked=false, label="Visit the Flight Master"   },
    { key="D", checked=false, label="Buy vials in trade district"},
    { key="E", checked=true,  label="Smelt 20 Copper Bars"      },
    { key="F", checked=false, label="Train Journeyman Cooking"  },
    { key="G", checked=false, label="Set HS to Goldshire"       },
    { key="H", checked=false, label="Check mailbox for mats"    },
    { key="I", checked=false, label="Turn in starter quests"    },
  }

  -- Each row gets its own frame (for background striping), with 3 cells
  local rowFrames = {}
  local cellWidgets = {}

  for i = 1, #rows do
    local rf = CreateFrame("Frame", nil, scrollChild)
    rf:SetHeight(THEME.rowHeight)

    -- background stripe
    local bg = rf:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    local c = (i % 2 == 1) and THEME.rowColorA or THEME.rowColorB
    bg:SetColorTexture(c.r, c.g, c.b, c.a)
    rf.Bg = bg

    table.insert(rowFrames, rf)

    -- Column 1: single-char button
    local btn = CreateFrame("Button", nil, rf, "UIPanelButtonTemplate")
    btn:SetText(rows[i].key)
    btn:SetHeight(THEME.rowHeight)
    table.insert(cellWidgets, btn)

    -- Column 2: checkbox
    local cb = CreateFrame("CheckButton", nil, rf, "UICheckButtonTemplate")
    cb:SetChecked(rows[i].checked or false)
    cb:Disable()
    cb:SetAlpha(0.95)
    table.insert(cellWidgets, cb)

    -- Column 3: label
    local lbl = rf:CreateFontString(nil, "OVERLAY")
    lbl:SetFontObject(THEME.fontObject)
    lbl:SetTextColor(THEME.labelColor.r, THEME.labelColor.g, THEME.labelColor.b)
    lbl:SetJustifyH(THEME.labelJustifyH)
    lbl:SetWordWrap(false)
    lbl:SetText(rows[i].label or "")
    table.insert(cellWidgets, lbl)
  end

  -- Layout rows vertically inside scrollChild, and lay out 3 columns per row
  local totalHeight = 0
  for i, rf in ipairs(rowFrames) do
    rf:ClearAllPoints()
    if i == 1 then
      rf:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
      rf:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, 0)
    else
      rf:SetPoint("TOPLEFT", rowFrames[i-1], "BOTTOMLEFT", 0, -THEME.gridGapY)
      rf:SetPoint("TOPRIGHT", rowFrames[i-1], "BOTTOMRIGHT", 0, -THEME.gridGapY)
    end
    rf:SetHeight(THEME.rowHeight)
    totalHeight = totalHeight + THEME.rowHeight + (i==1 and 0 or THEME.gridGapY)

    -- Apply per-row 3-column layout
    local i0 = (i-1)*3
    GridLayout(rf, { cellWidgets[i0+1], cellWidgets[i0+2], cellWidgets[i0+3] }, 1, 3, {
      offsetX   = 0,
      offsetY   = 0,
      gapX      = THEME.gridGapX,
      gapY      = 0,
      colWidths = THEME.colWidths,
      rowHeight = THEME.rowHeight,
    })
  end

  -- Finalize scrollChild size so the scrollbar knows the content bounds
  scrollChild:SetHeight(totalHeight)
  scrollChild:SetWidth(container:GetWidth() - 20) -- leave room for scrollbar

  -- Update scrollChild width on container resize for proper wrapping
  container:SetScript("OnSizeChanged", function(_, w, h)
    scrollChild:SetWidth(math.max(1, w - 20))
  end)

  -- store refs
  f.Title   = title
  f.Footer  = footer
  f.Scroll  = scroll
  f.Rows    = rowFrames
  f.Cells   = cellWidgets

  NS.ScrollProtoFrame = f
  return f
end

----------------------------------------------------------------------
-- Slash: /wclhello2
----------------------------------------------------------------------
SLASH_WCLHELLO2_1 = "/wclhello2"
SlashCmdList.WCLHELLO2 = function()
  local f = CreateScrollablePrototype()
  if f:IsShown() then f:Hide() else f:Show() end
end
