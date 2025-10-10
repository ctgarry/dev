--[[
  @file    lua/tasks.lua
  @brief   Per-character tasks API + SavedVariables persistence + profile copy.
]]
local ADDON, NS = ...
local U = NS.Util
local L = NS.L

-- Internal: character key "Name-Realm"
local function keyForChar()
  local name, realm = UnitFullName and UnitFullName("player")
  name = name or (UnitName("player"))
  realm = realm or GetRealmName()
  return (name or "Unknown") .. "-" .. (realm or "Realm")
end

local function ensureTables()
  WinterChecklistDB.chars = WinterChecklistDB.chars or {}
  local k = keyForChar()
  WinterChecklistDB.chars[k] = WinterChecklistDB.chars[k] or { tasks = {} }
  return k, WinterChecklistDB.chars[k]
end

-- Public API ------------------------------------------------------------------
function NS.Tasks_Add(text)  -- backwards-safe alias if needed later
  return NS.Tasks:Add(text)
end

local T = {}
NS.Tasks = T

function T:Add(text)
  local k, c = ensureTables()
  text = U.trim(text)
  if text == "" then return false end
  table.insert(c.tasks, text)
  return true
end

function T:RemoveByIndex(idx)
  local _, c = ensureTables()
  if type(idx) == "number" and c.tasks[idx] then
    table.remove(c.tasks, idx); return true
  end
  return false
end

function T:List()
  local _, c = ensureTables()
  return c.tasks
end

function T:ListCharacters()
  ensureTables()
  local out = {}
  for key,_ in pairs(WinterChecklistDB.chars) do table.insert(out, key) end
  table.sort(out)
  return out
end

function T:CopyFromCharacter(fromKey)
  local me, mine = ensureTables()
  local from = WinterChecklistDB.chars[fromKey]
  if not from or not from.tasks then return false end
  mine.tasks = U.shallow_copy(from.tasks) or {}
  return true
end
