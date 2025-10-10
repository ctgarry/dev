--[[
  @file    lua/utils.lua
  @brief   Small, dependency-free helpers used across modules.
]]
local ADDON, NS = ...
NS.Util = NS.Util or {}
local U = NS.Util

-- String helpers --------------------------------------------------------------
function U.trim(s)
  if type(s) ~= "string" then return "" end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Table helpers ---------------------------------------------------------------
function U.shallow_copy(t)
  if type(t) ~= "table" then return t end
  local out = {}
  for k,v in pairs(t) do out[k] = v end
  return out
end

function U.deepcopy(t, seen)
  if type(t) ~= "table" then return t end
  if seen and seen[t] then return seen[t] end
  local s = seen or {}
  local res = {}
  s[t] = res
  for k,v in pairs(t) do res[U.deepcopy(k, s)] = U.deepcopy(v, s) end
  return res
end

-- Math helpers ----------------------------------------------------------------
function U.clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end
