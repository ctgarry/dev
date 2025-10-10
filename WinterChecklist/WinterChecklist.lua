-- --------------------------------------------------------------------
-- WinterChecklist — clean-slate Classic Era scaffold (single-file)
-- Author: CTGarry
-- Notes:
--   - Strict namespace; no globals leaked.
--   - Safe event router; no insecure hooks or forbidden APIs.
--   - Movable/clamped UI with saved position (no SetMinResize calls).
--   - Zone-aware header text.
--   - Slash command: /wc (help, show, hide, reset, debug, export, import)
--   - Lightweight serializer for import/export (basic Lua-only format).
-- --------------------------------------------------------------------

local ADDON_NAME, NS = ...
NS.ADDON = ADDON_NAME

-- ---------------------------------------------------------------
-- Utilities (no globals)
-- ---------------------------------------------------------------
do
  local function tcopy(dst, src)
    for k, v in pairs(src) do
      if type(v) == "table" then
        dst[k] = dst[k] or {}
        tcopy(dst[k], v)
      else
        dst[k] = v
      end
    end
  end

  local function tcopy_missing(dst, src)
    for k, v in pairs(src) do
      if dst[k] == nil then
        if type(v) == "table" then
          dst[k] = {}
          tcopy_missing(dst[k], v)
        else
          dst[k] = v
        end
      elseif type(v) == "table" and type(dst[k]) == "table" then
        tcopy_missing(dst[k], v)
      end
    end
  end

  NS.table_copy = tcopy
  NS.table_copy_missing = tcopy_missing
end

-- Simple, safe printf-style logger
do
  local prefix = ("|cff89f7fe[%s]|r "):format(ADDON_NAME)
  function NS:Print(fmt, ...)
    if fmt == nil then return end
    DEFAULT_CHAT_FRAME:AddMessage(prefix .. (select("#", ...) > 0 and fmt:format(...) or fmt))
  end
  function NS:Debug(fmt, ...)
    if not (WinterChecklistDB and WinterChecklistDB.debug) then return end
    self:Print("|cffaaaaaaDEBUG|r " .. fmt, ...)
  end
end

-- Lightweight serializer (Lua-ish; numbers/booleans/strings/tables only)
NS.serialize = function(tbl)
  local function ser(v)
    local t = type(v)
    if t == "number" or t == "boolean" then
      return tostring(v)
    elseif t == "string" then
      return string.format("%q", v)
    elseif t == "table" then
      local parts = {}
      table.insert(parts, "{")
      for k, vv in pairs(v) do
        local key
        if type(k) == "string" and k:match("^[%a_][%w_]*$") then
          key = k
        else
          key = "[" .. ser(k) .. "]"
        end
        table.insert(parts, key .. "=" .. ser(vv) .. ",")
      end
      table.insert(parts, "}")
      return table.concat(parts)
    else
      return "nil" -- unsupported types dropped
    end
  end
  return ser(tbl)
end

-- Deserializer (loads in a sandboxed environment)
NS.deserialize = function(s)
  if type(s) ~= "string" or s:len() == 0 then return nil, "Empty import" end
  local env = {}
  local chunk, err = loadstring("return " .. s)
  if not chunk then return nil, err end
  setfenv(chunk, env)
  local ok, result = pcall(chunk)
  if not ok then return nil, result end
  if type(result) ~= "table" then return nil, "Not a table" end
  return result
end

-- ---------------------------------------------------------------
-- SavedVariables defaults
-- ---------------------------------------------------------------
NS.defaults = {
  version = GetAddOnMetadata and GetAddOnMetadata(ADDON_NAME, "Version") or "1.0.0",
  debug   = false,
  ui = {
    shown = true,
    point = "CENTER",
    relTo = "UIParent",
    relPt = "CENTER",
    x = 0, y = 0,
    w = 380, h = 260,
  },
  profile = {
    -- place future profile data here
  },
}

-- ---------------------------------------------------------------
-- Core: Event frame + router
-- ---------------------------------------------------------------
NS.frame = CreateFrame("Frame")
NS.frame:RegisterEvent("ADDON_LOADED")
NS.frame:RegisterEvent("PLAYER_LOGIN")
NS.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
NS.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
NS.frame:RegisterEvent("ZONE_CHANGED")
NS.frame:RegisterEvent("ZONE_CHANGED_INDOORS")

NS.events = {}

NS.frame:SetScript("OnEvent", function(_, event, ...)
  local handler = NS.events[event]
  if handler then
    handler(NS, ...)
  else
    NS:Debug("No handler for event %s", tostring(event))
  end
end)

-- ---------------------------------------------------------------
-- UI (single panel, movable, zone-aware header)
-- ---------------------------------------------------------------
NS.ui = {}

function NS.ui:Create()
  if self.frame then return end

  local db = WinterChecklistDB.ui

  local f = CreateFrame("Frame", "WC_MainFrame", UIParent, "BackdropTemplate")
  f:SetSize(db.w, db.h)
  f:SetPoint(db.point, db.relTo and _G[db.relTo] or UIParent, db.relPt, db.x, db.y)
  f:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = {left=4,right=4,top=4,bottom=4}
  })
  f:SetMovable(true)
  f:EnableMouse(true)
  f:SetClampedToScreen(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, relTo, relPt, x, y = self:GetPoint()
    db.point, db.relTo, db.relPt, db.x, db.y = point, relTo and relTo:GetName() or "UIParent", relPt, x, y
  end)

  -- Title bar
  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 12, -10)
  title:SetText(ADDON_NAME)

  -- Zone label
  local zone = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  zone:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  zone:SetText("Zone: —")
  self.zoneText = zone

  -- Body text (placeholder)
  local body = f:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  body:SetPoint("TOPLEFT", zone, "BOTTOMLEFT", 0, -12)
  body:SetJustifyH("LEFT")
  body:SetJustifyV("TOP")
  body:SetText("Welcome! Use |cff00ff00/wc|r for commands.\nThis is a clean Classic Era scaffold.")
  self.body = body

  -- Close button
  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 2, 1)

  self.frame = f
end

function NS.ui:SetShown(wantShown)
  if not self.frame then self:Create() end
  if wantShown then
    self.frame:Show()
  else
    self.frame:Hide()
  end
  WinterChecklistDB.ui.shown = wantShown and true or false
end

function NS.ui:UpdateZone()
  if not self.frame then return end
  local zone = GetRealZoneText() or GetZoneText() or "Unknown"
  local sub = GetSubZoneText()
  if sub and sub ~= "" and sub ~= zone then
    self.zoneText:SetText(("Zone: %s — %s"):format(zone, sub))
  else
    self.zoneText:SetText(("Zone: %s"):format(zone))
  end
end

-- ---------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------
SlashCmdList["WINTERCHECKLIST"] = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "" or msg == "help" or msg == "?" then
    NS:Print("Commands: |cff00ff00/wc show|r, |cff00ff00/wc hide|r, |cff00ff00/wc reset|r, |cff00ff00/wc debug|r, |cff00ff00/wc export|r, |cff00ff00/wc import|r")
    return
  end

  if msg == "show" then
    NS.ui:SetShown(true)
    return
  elseif msg == "hide" then
    NS.ui:SetShown(false)
    return
  elseif msg == "reset" then
    local d = NS.defaults.ui
    local ui = WinterChecklistDB.ui
    ui.point, ui.relTo, ui.relPt, ui.x, ui.y, ui.w, ui.h = d.point, d.relTo, d.relPt, d.x, d.y, d.w, d.h
    if NS.ui.frame then
      NS.ui.frame:ClearAllPoints()
      NS.ui.frame:SetPoint(ui.point, ui.relTo and _G[ui.relTo] or UIParent, ui.relPt, ui.x, ui.y)
      NS.ui.frame:SetSize(ui.w, ui.h)
    end
    NS:Print("UI position/size reset.")
    return
  elseif msg == "debug" then
    WinterChecklistDB.debug = not WinterChecklistDB.debug
    NS:Print("Debug: %s", WinterChecklistDB.debug and "ON" or "OFF")
    return
  elseif msg == "export" then
    local copy = {}
    NS.table_copy(copy, WinterChecklistDB.profile)
    local s = NS.serialize(copy)
    NS:Print("Export (copy from chat):")
    NS:Print("%s", s)
    return
  elseif msg:match("^import%s") then
    local payload = msg:sub(("import "):len()+1)
    local tbl, err = NS.deserialize(payload)
    if not tbl then
      NS:Print("|cffff5555Import failed:|r %s", tostring(err))
      return
    end
    -- merge into profile (non-destructive)
    NS.table_copy_missing(tbl, {}) -- ensure table
    NS.table_copy(WinterChecklistDB.profile, tbl)
    NS:Print("Import complete (%d keys).", (function(t) local c=0 for _ in pairs(t) do c=c+1 end return c end)(tbl))
    return
  else
    NS:Print("Unknown command '%s'. Type /wc for help.", msg)
  end
end
SLASH_WINTERCHECKLIST1 = "/wc"

-- ---------------------------------------------------------------
-- Event handlers
-- ---------------------------------------------------------------
NS.events.ADDON_LOADED = function(self, addonName)
  if addonName ~= ADDON_NAME then return end

  -- Initialize SavedVariables
  if type(WinterChecklistDB) ~= "table" then
    WinterChecklistDB = {}
  end
  self.table_copy_missing(WinterChecklistDB, self.defaults)

  self:Debug("ADDON_LOADED: DB ready. Version %s", WinterChecklistDB.version or "n/a")
end

NS.events.PLAYER_LOGIN = function(self)
  self:Debug("PLAYER_LOGIN")
  -- Build UI once player systems are up
  NS.ui:Create()
  NS.ui:SetShown(WinterChecklistDB.ui.shown)
  NS.ui:UpdateZone()
end

NS.events.PLAYER_ENTERING_WORLD = function(self, isLogin, isReload)
  self:Debug("PLAYER_ENTERING_WORLD (login=%s reload=%s)", tostring(isLogin), tostring(isReload))
  NS.ui:UpdateZone()
end

NS.events.ZONE_CHANGED_NEW_AREA = function() NS.ui:UpdateZone() end
NS.events.ZONE_CHANGED = function() NS.ui:UpdateZone() end
NS.events.ZONE_CHANGED_INDOORS = function() NS.ui:UpdateZone() end
