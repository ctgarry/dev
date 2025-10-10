-- utils.lua
-- Shared utility helpers for WinterChecklist
-- Creates/extends NS.Util

local ADDON_NAME, NS = ...
NS = NS or _G[ADDON_NAME] or {}
_G[ADDON_NAME] = NS

NS.Util = NS.Util or {}
local U = NS.Util

-- ---------- Basic table helpers ----------
function U.shallow_copy(src)
  if type(src) ~= "table" then return src end
  local out = {}
  for k,v in pairs(src) do out[k] = v end
  return out
end

function U.deep_copy(src, seen)
  if type(src) ~= "table" then return src end
  if seen and seen[src] then return seen[src] end
  local s = seen or {}
  local out = {}
  s[src] = out
  for k,v in pairs(src) do
    out[U.deep_copy(k, s)] = U.deep_copy(v, s)
  end
  return out
end

-- Merge keys from 'defaults' into 'dst' if missing (non-recursive)
function U.copy_missing(dst, defaults)
  if type(dst) ~= "table" then dst = {} end
  if type(defaults) ~= "table" then return dst end
  for k,v in pairs(defaults) do
    if dst[k] == nil then dst[k] = v end
  end
  return dst
end

-- ---------- String helpers ----------
function U.trim(s)
  return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- split by whitespace by default; or pass a Lua pattern separator (e.g. ",")
function U.split(s, sep)
  sep = sep or "%s+"
  local out = {}
  s = tostring(s or "")
  for part in s:gmatch("([^"..sep.."]+)") do
    table.insert(out, part)
  end
  return out
end

-- safe tostring for fmt args
local function _s(v)
  local ok, str = pcall(function() return tostring(v) end)
  return ok and str or "<tostring-error>"
end

function U.safe_format(fmt, ...)
  local args = {...}
  for i=1,#args do args[i] = _s(args[i]) end
  local ok, msg = pcall(string.format, tostring(fmt or ""), table.unpack(args))
  return ok and msg or (tostring(fmt or "") .. " " .. table.concat(args, " "))
end

-- ---------- Math helpers ----------
function U.clamp(v, a, b) if v < a then return a elseif v > b then return b else return v end end

-- Convert a center point to an on-screen clamped point (math only; no anchoring)
function U.clamp_to_screen(cx, cy, w, h, screenW, screenH, pad)
  pad = pad or 8
  local halfW, halfH = (w or 0)/2, (h or 0)/2
  local minX, maxX = pad + halfW, (screenW - pad) - halfW
  local minY, maxY = pad + halfH, (screenH - pad) - halfH
  return U.clamp(cx, minX, maxX), U.clamp(cy, minY, maxY)
end

-- ---------- Logging ----------
-- Expect a SavedVariables table WinterChecklistDB with .debug boolean
function U.print(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99WinterChecklist|r " .. tostring(msg)) end

function U.debug(fmt, ...)
  if type(WinterChecklistDB)=="table" and WinterChecklistDB.debug then
    U.print("|cffaaaaaaDEBUG|r " .. U.safe_format(fmt, ...))
  end
end

return U
