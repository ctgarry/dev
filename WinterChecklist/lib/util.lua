-- util.lua
-- Purpose: Cross-file utility helpers (string ops, printing, throttling, icons, small icon buttons).
-- Scope: Pure utilities; no compatibility or options/minimap shims here (those live in compat.lua).
-- Notes: No user-facing strings are defined here (brand prefix is a constant label, not localized).
--        Retail-vs-Classic detection is consulted via NS.IsRetail() (defined in compat.lua).

local ADDON, NS = ...

-- Localize hot globals for perf
local CreateFrame       = CreateFrame
local GameTooltip       = GameTooltip
local DEFAULT_CHAT_FRAME= DEFAULT_CHAT_FRAME
local s_format          = string.format

-- ===== Constants (avoid magic numbers) =====
local C = {
  SMALL_BTN_W       = 28,
  SMALL_BTN_H       = 22,
  ATLAS_SIZE        = 64,   -- texture atlas size used in texture tags
  DEFAULT_ICON_SIZE = 14,   -- fallback icon size
  DEFAULT_STR_W     = 16,   -- minimal measured width for icon text
  BRAND_PREFIX      = "|cff33ff99WinterChecklist|r: ", -- not localized by design
}

----------------------------------------------------------------------
-- String & print helpers (cross-file)
----------------------------------------------------------------------

-- Trim both ends (safe for nils)
function NS.STrim(s)
  if s == nil then return "" end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Empty check (after trim)
function NS.IsEmpty(s)
  return NS.STrim(s) == ""
end

-- Chat-frame print with addon prefix
function NS.Print(msg)
  local text = (msg == nil) and "" or tostring(msg)
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(C.BRAND_PREFIX .. text)
  end
end

----------------------------------------------------------------------
-- Timing helper
----------------------------------------------------------------------

-- Call a function at most once every `sec` seconds (for OnUpdate throttling)
-- Usage: local tick = NS.Throttle(0.2); frame:SetScript("OnUpdate", function(_, e) tick(e, function() ... end) end)
function NS.Throttle(sec)
  local acc, last = 0, 0
  return function(elapsed, f)
    acc = acc + (elapsed or 0)
    if (acc - last) >= (sec or 0) then
      last = acc
      f()
    end
  end
end

----------------------------------------------------------------------
-- Icon helpers (Retail Unicode vs Classic textures), cross-file
-- Note: Retail-vs-Classic detection is delegated to compat.lua via NS.IsRetail().
----------------------------------------------------------------------

-- Central icon registry so all files render the same symbols
NS.ICON_REG = NS.ICON_REG or {
  gear = {
    unicode   = "⚙",
    texture   = "Interface\\Buttons\\UI-OptionsButton",
    size      = 16,
    texCoords = { 5/64, 59/64, 5/64, 59/64 },
    padW      = 8,
  },
  link = {
    unicode   = "🔗",
    texture   = "Interface\\BUTTONS\\UI-SocialFrame-ChatIcon",
    size      = 14,
    texCoords = nil,
    padW      = 6,
  },
  refresh = {
    unicode   = "⟳",
    texture   = "Interface\\Buttons\\UI-RefreshButton",
    size      = 14,
    texCoords = nil,
    padW      = 8,
  },
  arrow = {
    unicode   = "→",
    texture   = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up",
    size      = 12,
    texCoords = nil,
    padW      = 6,
  },
}

-- Returns a texture tag or unicode symbol for a registry key
-- opts: { size=number, forceTexture=true|false, forceUnicode=true|false }
function NS.IconText(key, opts)
  opts = opts or {}
  local info = NS.ICON_REG[key]
  assert(info ~= nil, "Unknown icon key: " .. tostring(key))

  -- Prefer Unicode on Retail unless explicitly forced to texture
  local wantUnicode = (opts.forceUnicode == true)
    or (opts.forceTexture ~= true and NS.IsRetail and NS.IsRetail() and info.unicode ~= nil)

  if wantUnicode and info.unicode then
    return info.unicode
  end

  local tex = info.texture
  local size = opts.size or info.size or C.DEFAULT_ICON_SIZE
  local tc = info.texCoords
  if tc then
    -- format: |Tpath:width:height:...:ULx:ULy:LRx:LRy|t using the atlas size from C.ATLAS_SIZE
    local A = C.ATLAS_SIZE
    return s_format("|T%s:%d:%d:0:0:%d:%d:%d:%d:%d:%d|t",
      tex, size, size, A, A, tc[1]*A, tc[2]*A, tc[3]*A, tc[4]*A)
  else
    return s_format("|T%s:%d:%d|t", tex, size, size)
  end
end

-- Apply an icon to a UIPanelButton (and pad width a bit)
function NS.ApplyIcon(btn, key, opts)
  assert(btn ~= nil, "ApplyIcon: button is nil")
  local reg = NS.ICON_REG[key]
  assert(reg ~= nil, "ApplyIcon: unknown icon key: " .. tostring(key))

  btn:SetText(NS.IconText(key, opts))
  if btn.SetWidth and reg.padW then
    -- Measure actual string width for reliable sizing across fonts/scales
    local fs = btn.GetFontString and btn:GetFontString() or nil
    local w  = (fs and fs:GetStringWidth() or C.DEFAULT_STR_W) + reg.padW
    btn:SetWidth(w)
  end
end

-- Create a small icon button with optional tooltip (tooltip text should be localized by caller)
function NS.SmallIconBtn(parent, key, tooltip, opts)
  assert(parent ~= nil, "SmallIconBtn: parent is nil")
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(C.SMALL_BTN_W, C.SMALL_BTN_H)
  NS.ApplyIcon(b, key, opts)
  if tooltip then
    b:SetMotionScriptsWhileDisabled(true)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(tooltip) -- caller-provided, already localized
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  end
  return b
end
