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
local T = {}
NS.Tasks = T

function T:Add(text)
  local k, c = ensureTables()
  text = U.trim(text)
  if text == "" then return false end
  table.insert(c.tasks, text)
  -- Feedback (sound) via LSM or SOUNDKIT
  if NS.Media and NS.Media.PlayTaskAdded then NS.Media:PlayTaskAdded() end
  -- Chat feedback (localized)
  if NS.Print and L.TASKS_ADDED then NS:Print(L.TASKS_ADDED:format(text)) end
  return true
end

function T:RemoveByIndex(idx)
  local _, c = ensureTables()
  if type(idx) == "number" and c.tasks[idx] then
    local removed = table.remove(c.tasks, idx)
    if removed and NS.Print and L.TASKS_REMOVED then NS:Print(L.TASKS_REMOVED:format(removed)) end
    return true
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

-- Export / Import --------------------------------------------------------------
local T = NS.Tasks or {}
NS.Tasks = T

-- shallow schema: tasks are stored under WinterChecklistDB.chars[me].tasks = { {text=..., done=false}, ... }
local function ensureTables()
  WinterChecklistDB = WinterChecklistDB or {}
  WinterChecklistDB.chars = WinterChecklistDB.chars or {}
  local me = (UnitName("player") or "Unknown").."-"..(GetRealmName() or "Realm")
  local mine = WinterChecklistDB.chars[me] or {}
  WinterChecklistDB.chars[me] = mine
  mine.tasks = mine.tasks or {}
  return me, mine
end

-- serialize to a compact Lua string (safe to paste)
local function serialize(tbl)
  local function esc(s) return (s or ""):gsub('\\', '\\\\'):gsub('"', '\\"') end
  local out = { "return { tasks={" }
  for _,t in ipairs(tbl or {}) do
    table.insert(out, ('{text="%s",done=%s},'):format(esc(t.text), tostring(not not t.done)))
  end
  table.insert(out, "} }")
  return table.concat(out, "")
end

function T:Export()
  local _, mine = ensureTables()
  local payload = serialize(mine.tasks)
  return payload
end

local function deserialize(chunk)
  if type(chunk) ~= "string" or chunk == "" then return nil end
  local ok, res = pcall(loadstring(chunk))
  if not ok or type(res) ~= "function" then return nil end
  local ok2, tbl = pcall(res)
  if not ok2 or type(tbl) ~= "table" then return nil end
  return tbl
end

function T:Import(data)
  local tbl = deserialize(data)
  if not tbl or type(tbl.tasks) ~= "table" then return false end
  local _, mine = ensureTables()
  mine.tasks = {}
  local count = 0
  for _,t in ipairs(tbl.tasks) do
    if type(t) == "table" and type(t.text) == "string" then
      table.insert(mine.tasks, { text=t.text, done=not not t.done })
      count = count + 1
    end
  end
  if NS.NotifyTasksChanged then NS.NotifyTasksChanged("IMPORT") end
  return true, count
end

-- Ergonomics: Remove(text) and Clear()
function T:Remove(text)
  local _, mine = ensureTables()
  if not text or text == "" then return 0 end
  local removed = 0
  for i=#mine.tasks,1,-1 do
    if mine.tasks[i].text == text then
      table.remove(mine.tasks, i)
      removed = removed + 1
    end
  end
  if removed > 0 and NS.NotifyTasksChanged then NS.NotifyTasksChanged("REMOVE") end
  return removed
end

function T:Clear()
  local _, mine = ensureTables()
  local n = #mine.tasks
  wipe(mine.tasks)
  if NS.NotifyTasksChanged then NS.NotifyTasksChanged("CLEAR") end
  return n
end
