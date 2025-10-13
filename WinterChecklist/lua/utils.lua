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
function U.ShowTextPopup(title, text, onAccept)
  if not StaticPopupDialogs then
    StaticPopupDialogs = {}
  end
  StaticPopupDialogs["WCL_TEXT_POPUP"] = {
    text = title or "WinterChecklist",
    button1 = (NS.L and NS.L.OK) or (OKAY or "OK"),
    button2 = (NS.L and NS.L.CANCEL) or (CANCEL or "Cancel"),
    hasEditBox = true,
    maxLetters = 0,
    OnShow = function(self)
      local eb = self.editBox
      eb:SetText(text or "")
      eb:SetFocus()
      eb:HighlightText()
    end,
    OnAccept = function(self)
      if onAccept then
        onAccept(self.editBox:GetText())
      end
    end,
    EditBoxOnEnterPressed = function(self)
      self:GetParent().button1:Click()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }
  StaticPopup_Show("WCL_TEXT_POPUP")
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

