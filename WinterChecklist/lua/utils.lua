--[[
  @file    lua/utils.lua
  @brief   Small, dependency-free helpers used across modules.
]]
local _, NS = ...
NS.Util = NS.Util or {}
local U = NS.Util

-- String helpers --------------------------------------------------------------
function U.trim(s)
  if type(s) ~= "string" then
    return ""
  end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Table helpers ---------------------------------------------------------------
function U.shallow_copy(t)
  if type(t) ~= "table" then
    return t
  end
  local out = {}
  for k, v in pairs(t) do
    out[k] = v
  end
  return out
end

function U.deepcopy(t, seen)
  if type(t) ~= "table" then
    return t
  end
  if seen and seen[t] then
    return seen[t]
  end
  local s = seen or {}
  local res = {}
  s[t] = res
  for k, v in pairs(t) do
    res[U.deepcopy(k, s)] = U.deepcopy(v, s)
  end
  return res
end

-- Math helpers ----------------------------------------------------------------
function U.clamp(v, lo, hi)
  if v < lo then
    return lo
  end
  if v > hi then
    return hi
  end
  return v
end

-- UI helpers ------------------------------------------------------------------
function U.ShowTextPopup(title, text, onAccept, opts)
  if not StaticPopupDialogs then
    StaticPopupDialogs = {}
  end
  opts = opts or {}
  local key = opts.key or "WCL_TEXT_POPUP"
  local multiline = opts.multiline ~= false
  local width = opts.width or (multiline and 420 or 260)
  local height = opts.height or (multiline and 140 or 32)
  local commitOnEnter = opts.commitOnEnter
  if commitOnEnter == nil then
    commitOnEnter = not multiline
  end
  local prompt = opts.prompt or title or "WinterChecklist"
  StaticPopupDialogs[key] = {
    text = prompt,
    button1 = opts.button1 or (NS.L and NS.L.OK) or (OKAY or "OK"),
    button2 = opts.button2 or (NS.L and NS.L.CANCEL) or (CANCEL or "Cancel"),
    hasEditBox = true,
    maxLetters = 0,
    OnShow = function(self)
      local eb = self.editBox
      if not eb then
        return
      end
      eb:SetMultiLine(multiline)
      eb:SetWidth(width)
      eb:SetHeight(height)
      eb:SetAutoFocus(true)
      eb:SetMaxLetters(0)
      eb:SetCountInvisibleLetters(false)
      eb:SetAltArrowKeyMode(false)
      eb:SetText(text or "")
      eb:HighlightText()
      eb:SetCursorPosition(0)
      eb:SetFocus()
      eb:ClearAllPoints()
      if multiline then
        eb:SetPoint("TOPLEFT", self, "TOPLEFT", 18, -52)
        eb:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -34, 62)
        eb:SetHeight(height)
        self:SetWidth(math.max(self:GetWidth(), width + 60))
        self:SetHeight(math.max(self:GetHeight(), height + 128))
      else
        eb:SetPoint("TOP", self, "TOP", 0, -52)
        eb:SetPoint("LEFT", self, "LEFT", 18, 0)
        eb:SetPoint("RIGHT", self, "RIGHT", -17, 0)
      end
      if opts.onShow then
        opts.onShow(self, eb)
      end
    end,
    OnAccept = function(self)
      if onAccept then
        onAccept(self.editBox:GetText())
      end
    end,
    EditBoxOnEnterPressed = function(self)
      if commitOnEnter then
        self:GetParent().button1:Click()
      end
    end,
    EditBoxOnEscapePressed = function(self)
      self:GetParent().button2:Click()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }
  StaticPopup_Show(key)
end

-- Simple yes/no confirm dialog ------------------------------------------------
function U.Confirm(text, yesLabel, noLabel, onAccept, onCancel)
  if not StaticPopupDialogs then
    StaticPopupDialogs = {}
  end
  StaticPopupDialogs["WCL_CONFIRM_POPUP"] = {
    text = text or "Confirm?",
    button1 = yesLabel or (NS.L and NS.L.YES) or "Yes",
    button2 = noLabel or (NS.L and NS.L.NO) or "No",
    OnAccept = function()
      if onAccept then
        onAccept()
      end
    end,
    OnCancel = function()
      if onCancel then
        onCancel()
      end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }
  StaticPopup_Show("WCL_CONFIRM_POPUP")
end

function U.ClampToScreen(frame)
  if not frame then
    return
  end
  local uiW, uiH = UIParent:GetRight(), UIParent:GetTop()
  local left, bottom = frame:GetLeft() or 0, frame:GetBottom() or 0
  local right, top = frame:GetRight() or 0, frame:GetTop() or 0
  local offX = 0
  local offY = 0
  if left < 0 then
    offX = -left
  end
  if right > uiW then
    offX = uiW - right
  end
  if bottom < 0 then
    offY = -bottom
  end
  if top > uiH then
    offY = uiH - top
  end
  if offX ~= 0 or offY ~= 0 then
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (frame:GetLeft() or 0) + offX, (frame:GetTop() or 0) + offY)
  end
end
