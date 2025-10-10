-- tasks.lua
-- Purpose: Task-list operations (selection, edit, delete, reset/completion helpers).
-- Scope: Pure logic; no UI/compat and no user-facing strings here.
-- Notes: Frequencies are stored on tasks as lowercase ("daily"/"weekly").

local ADDON, NS = ...

-- ===== Constants (avoid magic strings) =====
local FREQ = {
  DAILY  = "daily",
  WEEKLY = "weekly",
}

-- Selection state (module-local)
local selIndex = nil

----------------------------------------------------------------------
-- Selection helpers
----------------------------------------------------------------------
function NS.SelectTask(i)
  -- accepts nil to clear selection
  if i == nil then selIndex = nil; return end
  if type(i) == "number" and i >= 1 then
    selIndex = i
  end
end

function NS.GetSelection()
  return selIndex
end

----------------------------------------------------------------------
-- Edit / Delete
----------------------------------------------------------------------
function NS.EditSelected(newText)
  if not selIndex then return end
  local tasks = NS.GetTasks()
  local t = tasks and tasks[selIndex]
  if t then
    -- Prevent duplicates within same frequency on edit
    local freq = (t.frequency or FREQ.DAILY)
    for idx, other in ipairs(tasks) do
      if idx ~= selIndex and (other.frequency or FREQ.DAILY) == freq and (other.text or "") == (newText or "") then
        if NS.Print then NS.Print("Duplicate task exists in "..freq..": "..(newText or "")) end
        return
      end
    end
    -- Do not trim or enforce non-empty here; UI should validate and localize messages.
    t.text = newText
    NS.SaveTasks(tasks)
    if NS.RefreshUI then NS.RefreshUI() end
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
  end
end

function NS.DeleteSelected()
  if not selIndex then return end
  local tasks = NS.GetTasks()
  if tasks and tasks[selIndex] then
    table.remove(tasks, selIndex)
    selIndex = nil
    NS.SaveTasks(tasks)
    if NS.RefreshUI then NS.RefreshUI() end
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
  end
end

----------------------------------------------------------------------
-- Completion & resets
----------------------------------------------------------------------

-- Frequency constants (lowercase strings)
NS.FREQ = NS.FREQ or { all = "all", daily = "daily", weekly = "weekly" }
local FREQ = NS.FREQ

-- Uncheck tasks by kind ("all" | "daily" | "weekly")
function NS.ResetTasks(kind)
  local db = NS.EnsureDB and NS.EnsureDB()
  if not db or not db.tasks then return end

  local k = (type(kind) == "string" and kind:lower()) or "all"

  for _, t in ipairs(db.tasks) do
    local f = type(t.frequency) == "string" and t.frequency:lower() or "all"
    if (k == "all")
       or (k == "daily"  and f == "daily")
       or (k == "weekly" and f == "weekly") then
      t.completed = false
    end
  end

  if NS.RefreshUI then
    NS.RefreshUI()
  elseif NS.FilterAndRebuildList and _G.WC_Main then
    NS.FilterAndRebuildList(_G.WC_Main)
  end

  if NS.SyncProfileSnapshot then
    NS.SyncProfileSnapshot()
  end
end

-- Optional helpers (non-breaking; may be used by UI)
function NS.ToggleCompleted(i)
  local tasks = NS.GetTasks()
  local t = (tasks and type(i) == "number") and tasks[i]
  if not t then return end
  t.completed = not not (not t.completed)
  NS.SaveTasks(tasks)
  if NS.RefreshUI then NS.RefreshUI() end
  if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
end

function NS.SetCompleted(i, value)
  local tasks = NS.GetTasks()
  local t = (tasks and type(i) == "number") and tasks[i]
  if not t then return end
  t.completed = value and true or false
  NS.SaveTasks(tasks)
  if NS.RefreshUI then NS.RefreshUI() end
  if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
end


-- WC_SANITIZE_AND_PEEK

function NS.SanitizeText(s)
  if type(s) ~= "string" then return s end
  s = s:gsub("[\226\128\152\226\128\153\239\191\189\194\146]", "'")
  s = s:gsub("[\226\128\156\226\128\157]", '"')
  s = s:gsub("\226\128\147", "-"):gsub("\226\128\148", "-")
  s = s:gsub("\226\128\166", "...")
  s = s:gsub("\226\128\139", ""):gsub("\194\160", " ")
  return s
end


local function _WC_PeekFirst(tasks)
  if type(tasks) ~= "table" then return "[empty]" end

  -- Try array first, fall back to first pair
  local t = tasks[1]
  if t == nil then
    for _, v in pairs(tasks) do t = v; break end
  end
  if t == nil then return "[empty]" end

  -- Sanitize text for format/newlines and cap length
  local txt = tostring(t.text or "?")
  txt = txt:gsub("%%", "%%%%"):gsub("%s+", " ")
  if #txt > 80 then txt = txt:sub(1,77) .. "..." end

  local freq = tostring((type(t.frequency) == "string" and t.frequency or "?"))
  local done = tostring(t.completed)

  -- Count items (fallback if #tasks == 0 for non-array table)
  local n = #tasks
  if n == 0 then
    n = 0
    for _ in pairs(tasks) do n = n + 1 end
  end

  return string.format("[%d items] first='%s' (%s, completed=%s)", n, txt, freq, done)
end

