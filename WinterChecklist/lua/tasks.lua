--[[
  @file    lua/tasks.lua
  @brief   Per-character tasks API + SavedVariables persistence + profile copy.
]]
local ADDON, NS = ...
local U = NS.Util
local L = NS.L
local T = NS.Tasks

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


-- Milestone A: extended task API ----------------------------------------------
local function activeKey()
  local account = WinterChecklistDB and WinterChecklistDB.accountWide
  if account then return "Account-Wide" end
  local name, realm = UnitFullName and UnitFullName("player")
  name = name or UnitName("player") or "Unknown"
  realm = realm or GetRealmName() or "Realm"
  return name.."-"..realm
end

local function ensureTables()
  WinterChecklistDB = WinterChecklistDB or {}
  WinterChecklistDB.chars = WinterChecklistDB.chars or {}
  WinterChecklistDB.accountWide = WinterChecklistDB.accountWide or false
  local key = activeKey()
  local rec = WinterChecklistDB.chars[key] or {}
  WinterChecklistDB.chars[key] = rec
  rec.tasks = rec.tasks or {}
  return key, rec
end

local function normalizeFreq(freq)
  freq = tostring(freq or "all"):lower()
  if freq ~= "daily" and freq ~= "weekly" then return "all" end
  return freq
end

function T:Add(text, freq)
  local _, me = ensureTables()
  local s = U and U.trim and U.trim(text) or text
  if not s or s == "" then return false end
  table.insert(me.tasks, { text=s, done=false, freq=normalizeFreq(freq) })
  if NS.NotifyTasksChanged then NS.NotifyTasksChanged("ADD") end
  return true
end

function T:Edit(index, newText, newFreq)
  local _, me = ensureTables()
  local row = me.tasks[index]
  if not row then return false end
  if newText and newText ~= "" then row.text = newText end
  if newFreq then row.freq = normalizeFreq(newFreq) end
  if NS.NotifyTasksChanged then NS.NotifyTasksChanged("EDIT") end
  return true
end

function T:ToggleDone(index, val)
  local _, me = ensureTables()
  local row = me.tasks[index]
  if not row then return false end
  row.done = (val == nil) and (not row.done) or not not val
  if NS.NotifyTasksChanged then NS.NotifyTasksChanged("TOGGLE") end
  return true
end

function T:RemoveByIndex(index)
  local _, me = ensureTables()
  if not me.tasks[index] then return false end
  table.remove(me.tasks, index)
  if NS.NotifyTasksChanged then NS.NotifyTasksChanged("REMOVE") end
  return true
end

function T:MoveUp(index)
  local _, me = ensureTables()
  if index <= 1 or index > #me.tasks then return false end
  me.tasks[index-1], me.tasks[index] = me.tasks[index], me.tasks[index-1]
  if NS.NotifyTasksChanged then NS.NotifyTasksChanged("MOVE") end
  return true
end

function T:MoveDown(index)
  local _, me = ensureTables()
  if index < 1 or index >= #me.tasks then return false end
  me.tasks[index+1], me.tasks[index] = me.tasks[index], me.tasks[index+1]
  if NS.NotifyTasksChanged then NS.NotifyTasksChanged("MOVE") end
  return true
end

function T:GetAll()
  local _, me = ensureTables()
  return me.tasks
end

-- Import behavior: ask merge vs replace via popup
function T:ImportWithPrompt(data)
  local function doReplace()
    local ok, n = T:Import(data, true)
    if ok and NS.Print then NS:Print((NS.L.IMPORT_OK_FMT or "Imported %d tasks."):format(n or 0)) end
  end
  local function doMerge()
    local ok, n = T:Import(data, false)
    if ok and NS.Print then NS:Print((NS.L.IMPORT_OK_FMT or "Imported %d tasks."):format(n or 0)) end
  end
  if U and U.Confirm then
    U.Confirm(NS.L.IMPORT_MERGE_OR_REPLACE or "Import: merge with existing tasks, or replace them?",
              NS.L.IMPORT_REPLACE or "Replace", NS.L.IMPORT_MERGE or "Merge", doReplace, doMerge)
  else
    doMerge()
  end
end
