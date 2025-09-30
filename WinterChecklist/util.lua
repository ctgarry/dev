-- util.lua
local ADDON, NS = ...

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
do
  local PREFIX = "|cff33ff99WinterChecklist|r: "
  function NS.Print(msg)
    local text = (msg == nil) and "" or tostring(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
      DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. text)
    end
  end
end

----------------------------------------------------------------------
-- Timing helper
----------------------------------------------------------------------

-- Call a function at most once every `sec` seconds (for OnUpdate throttling)
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
----------------------------------------------------------------------

local IS_RETAIL = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

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
function NS.IconText(key, opts)
  opts = opts or {}
  local info = NS.ICON_REG[key]
  if not info then return "" end

  -- Prefer Unicode on Retail unless forced to texture
  if IS_RETAIL and info.unicode and not opts.forceTexture then
    return info.unicode
  end

  local tex = info.texture
  local size = opts.size or info.size or 14
  local tc = info.texCoords
  if tc then
    -- format: |Tpath:width:height:...:ULx:ULy:LRx:LRy|t  using a 64x64 atlas
    return ("|T%s:%d:%d:0:0:64:64:%d:%d:%d:%d|t")
      :format(tex, size, size, tc[1]*64, tc[2]*64, tc[3]*64, tc[4]*64)
  else
    return ("|T%s:%d:%d|t"):format(tex, size, size)
  end
end

-- Apply an icon to a UIPanelButton (and pad width a bit)
function NS.ApplyIcon(btn, key, opts)
  if not btn then return end
  btn:SetText(NS.IconText(key, opts))
  local reg = NS.ICON_REG[key]
  if btn.SetWidth and reg and reg.padW then
    local w = (btn:GetText() and (btn:GetText():len() * 8) or 16) + reg.padW
    btn:SetWidth(w)
  end
end

-- Create a small icon button with optional tooltip
function NS.SmallIconBtn(parent, key, tooltip, opts)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(28, 22)
  NS.ApplyIcon(b, key, opts)
  if tooltip then
    b:SetMotionScriptsWhileDisabled(true)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(tooltip)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  end
  return b
end
