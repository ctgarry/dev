--[[
  @file    lua/tasks.lua
  @brief   Per-character tasks API + SavedVariables persistence + profile copy.
]]
local _, NS = ...
local U = NS.Util or {}
local L = NS.L or {}

local Tasks = NS.Tasks or {}
NS.Tasks = Tasks

local function charKey()
  local name, realm = UnitFullName and UnitFullName("player")
  name = name or UnitName("player") or "Unknown"
  realm = realm or GetRealmName() or "Realm"
  return name .. "-" .. realm
end

local function ensureDB()
  WinterChecklistDB = WinterChecklistDB or {}
  WinterChecklistDB.chars = WinterChecklistDB.chars or {}
  if WinterChecklistDB.accountWide == nil then
    WinterChecklistDB.accountWide = false
  end
end

local function activeKey()
  ensureDB()
  if WinterChecklistDB.accountWide then
    return "Account-Wide"
  end
  return charKey()
end

local function normalizeFreq(freq)
  freq = tostring(freq or "all"):lower()
  if freq ~= "daily" and freq ~= "weekly" then
    return "all"
  end
  return freq
end

local function normalizeTask(row)
  if type(row) == "string" then
    local trimmed = (U.trim and U.trim(row)) or row
    if type(trimmed) ~= "string" or trimmed == "" then
      return nil
    end
    return { text = trimmed, done = false, freq = "all" }
  elseif type(row) == "table" then
    local text = row.text or row[1]
    if type(text) ~= "string" or text == "" then
      return nil
    end
    return { text = text, done = not not row.done, freq = normalizeFreq(row.freq) }
  end
  return nil
end

local function sanitizeTasks(tasks)
  if type(tasks) ~= "table" then
    return {}
  end
  for i = #tasks, 1, -1 do
    local normalized = normalizeTask(tasks[i])
    if normalized then
      tasks[i] = normalized
    else
      table.remove(tasks, i)
    end
  end
  return tasks
end

local function ensureRecord(key)
  ensureDB()
  key = key or activeKey()
  local rec = WinterChecklistDB.chars[key]
  if not rec then
    rec = {}
    WinterChecklistDB.chars[key] = rec
  end
  rec.tasks = sanitizeTasks(rec.tasks or {})
  return key, rec
end

local function getRecordFor(key)
  ensureDB()
  local rec = WinterChecklistDB.chars[key]
  if not rec then
    return key, nil
  end
  rec.tasks = sanitizeTasks(rec.tasks or {})
  return key, rec
end

local function notify(reason)
  if NS.NotifyTasksChanged then
    NS.NotifyTasksChanged(reason)
  end
end

local function cloneTasks(src)
  local copy = {}
  if type(src) ~= "table" then
    return copy
  end
  for _, row in ipairs(src) do
    local normalized = normalizeTask(row)
    if normalized then
      copy[#copy + 1] = normalized
    end
  end
  return copy
end

local function escape(str)
  return (str or ""):gsub("\\", "\\\\"):gsub('"', '\\"')
end

local function serialize(tasks)
  local out = { "return { tasks={" }
  for _, row in ipairs(tasks) do
    out[#out + 1] = ('{text="%s",done=%s},'):format(escape(row.text), tostring(not not row.done))
  end
  out[#out + 1] = "} }"
  return table.concat(out, "")
end

local function deserialize(chunk)
  if type(chunk) ~= "string" or chunk == "" then
    return nil
  end
  local ok, res = pcall(loadstring, chunk)
  if not ok or type(res) ~= "function" then
    return nil
  end
  local ok2, tbl = pcall(res)
  if not ok2 or type(tbl) ~= "table" then
    return nil
  end
  return tbl
end

function Tasks.GetAll(_)
  local _, rec = ensureRecord()
  return rec.tasks
end

function Tasks.List(self)
  return Tasks.GetAll(self)
end

function Tasks.ListCharacters(_)
  ensureRecord() -- ensure active record exists
  local out = {}
  for key in pairs(WinterChecklistDB.chars) do
    out[#out + 1] = key
  end
  table.sort(out)
  return out
end

function Tasks.CopyFromCharacter(_, fromKey)
  if not fromKey or fromKey == "" then
    return false
  end
  local _, mine = ensureRecord()
  local _, from = getRecordFor(fromKey)
  if not from or not from.tasks then
    return false
  end
  mine.tasks = cloneTasks(from.tasks)
  notify("COPY")
  return true
end

function Tasks.Add(_, text, freq)
  local _, rec = ensureRecord()
  local trimmed = (U.trim and U.trim(text)) or text
  if type(trimmed) ~= "string" then
    return false
  end
  if trimmed == "" then
    return false
  end
  local task = { text = trimmed, done = false, freq = normalizeFreq(freq) }
  table.insert(rec.tasks, task)
  if NS.Media and NS.Media.PlayTaskAdded then
    NS.Media:PlayTaskAdded()
  end
  if NS.Print and L.TASKS_ADDED then
    NS:Print(L.TASKS_ADDED:format(trimmed))
  end
  notify("ADD")
  return true
end

function Tasks.RemoveByIndex(_, index)
  local _, rec = ensureRecord()
  if type(index) ~= "number" then
    return false
  end
  local removed = table.remove(rec.tasks, index)
  if not removed then
    return false
  end
  local removedText = type(removed) == "table" and removed.text or removed
  if removedText and NS.Print and L.TASKS_REMOVED then
    NS:Print(L.TASKS_REMOVED:format(removedText))
  end
  notify("REMOVE")
  return true
end

function Tasks.Remove(_, text)
  local _, rec = ensureRecord()
  local target = (U.trim and U.trim(text)) or text
  if type(target) ~= "string" or target == "" then
    return 0
  end
  local removed = 0
  for i = #rec.tasks, 1, -1 do
    local row = rec.tasks[i]
    local rowText = type(row) == "table" and row.text or row
    if rowText == target then
      table.remove(rec.tasks, i)
      removed = removed + 1
    end
  end
  if removed > 0 then
    notify("REMOVE")
  end
  return removed
end

function Tasks.Clear(_)
  local _, rec = ensureRecord()
  local count = #rec.tasks
  if count > 0 then
    if wipe then
      wipe(rec.tasks)
    else
      for i = #rec.tasks, 1, -1 do
        rec.tasks[i] = nil
      end
    end
    notify("CLEAR")
  end
  return count
end

function Tasks.Edit(_, index, newText, newFreq)
  local _, rec = ensureRecord()
  local row = rec.tasks[index]
  if not row then
    return false
  end
  if type(newText) == "string" then
    local trimmed = (U.trim and U.trim(newText)) or newText
    if trimmed ~= "" then
      row.text = trimmed
    end
  end
  if newFreq then
    row.freq = normalizeFreq(newFreq)
  end
  notify("EDIT")
  return true
end

function Tasks.ToggleDone(_, index, val)
  local _, rec = ensureRecord()
  local row = rec.tasks[index]
  if not row then
    return false
  end
  if val == nil then
    row.done = not row.done
  else
    row.done = not not val
  end
  notify("TOGGLE")
  return true
end

function Tasks.MoveUp(_, index)
  local _, rec = ensureRecord()
  if type(index) ~= "number" or index <= 1 or index > #rec.tasks then
    return false
  end
  rec.tasks[index - 1], rec.tasks[index] = rec.tasks[index], rec.tasks[index - 1]
  notify("MOVE")
  return true
end

function Tasks.MoveDown(_, index)
  local _, rec = ensureRecord()
  if type(index) ~= "number" or index < 1 or index >= #rec.tasks then
    return false
  end
  rec.tasks[index + 1], rec.tasks[index] = rec.tasks[index], rec.tasks[index + 1]
  notify("MOVE")
  return true
end

function Tasks.Export(_)
  local _, rec = ensureRecord()
  return serialize(rec.tasks)
end

function Tasks.Import(_, data, replace)
  local tbl = deserialize(data)
  if not tbl or type(tbl.tasks) ~= "table" then
    return false
  end
  local _, rec = ensureRecord()
  if replace ~= false then
    if wipe then
      wipe(rec.tasks)
    else
      for i = #rec.tasks, 1, -1 do
        rec.tasks[i] = nil
      end
    end
  end
  local count = 0
  for _, row in ipairs(tbl.tasks) do
    local normalized = normalizeTask(row)
    if normalized then
      rec.tasks[#rec.tasks + 1] = normalized
      count = count + 1
    end
  end
  notify("IMPORT")
  return true, count
end

function Tasks.ImportWithPrompt(self, data)
  local function doReplace()
    local ok, n = self:Import(data, true)
    if ok and NS.Print then
      NS:Print((L.IMPORT_OK_FMT or "Imported %d tasks."):format(n or 0))
    end
  end

  local function doMerge()
    local ok, n = self:Import(data, false)
    if ok and NS.Print then
      NS:Print((L.IMPORT_OK_FMT or "Imported %d tasks."):format(n or 0))
    end
  end

  if U and U.Confirm then
    U.Confirm(
      L.IMPORT_MERGE_OR_REPLACE or "Import: merge with existing tasks, or replace them?",
      L.IMPORT_REPLACE or "Replace",
      L.IMPORT_MERGE or "Merge",
      doReplace,
      doMerge
    )
  else
    doMerge()
  end
end

