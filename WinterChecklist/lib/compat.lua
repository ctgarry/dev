-- File: lib/compat.lua
-- Purpose: Retail/Classic shims only (no UI, no minimap, no options).
-- Scope: Tiny helpers that behave the same on Retail and Classic. Safe to require anywhere.

local ADDON, NS = ...

-- ===== Project detection (keep it simple) =====
NS.IsRetail  = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
NS.IsClassic = not NS.IsRetail

-- ===== Safe wrappers =====

-- Resize bounds wrapper (Classic lacks SetResizeBounds)
function NS.SetResizeBounds(frame, minW, minH, maxW, maxH)
  if not frame then return end
  if frame.SetResizeBounds then
    frame:SetResizeBounds(minW, minH, maxW, maxH)
  else
    if frame.SetMinResize then pcall(frame.SetMinResize, frame, minW or 1, minH or 1) end
    if frame.SetMaxResize then pcall(frame.SetMaxResize, frame, maxW or 10000, maxH or 10000) end
  end
end

-- Show/Hide without errors if frame is nil
function NS.SafeSetShown(frame, shown)
  if frame and frame.IsShown then
    if shown then frame:Show() else frame:Hide() end
  end
end

-- Event helper: register multiple events safely
function NS.SafeRegisterEvents(frame, events)
  if not frame or not frame.RegisterEvent or type(events) ~= "table" then return end
  for _, ev in ipairs(events) do pcall(frame.RegisterEvent, frame, ev) end
end

-- Defer helper: run func on next tick if timers exist
function NS.After(delay, func)
  if type(func) ~= "function" then return end
  if C_Timer and C_Timer.After then
    C_Timer.After(delay or 0, func)
  else
    func()
  end
end

-- String localizer passthrough (asserts in main code if key is missing)
function NS.T(key)
  local L = NS.L or {}
  return L[key] or key
end
