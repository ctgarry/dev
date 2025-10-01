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
-- Reset completion flags by kind: "all" | "daily" | "weekly"
function NS.ResetTasks(kind)
  local db = (NS.EnsureDB and NS.EnsureDB()) or EnsureDB()
  local k = type(kind) == "string" and kind:lower() or "all"

  for _, t in ipairs(db.tasks or {}) do
    local f = (t.frequency or FREQ.DAILY):lower()
    if k == "all"
       or (k == "daily"  and f == FREQ.DAILY)
       or (k == "weekly" and f == FREQ.WEEKLY) then
      t.completed = false
    end
  end

  if NS.RefreshUI then NS.RefreshUI() end
  if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
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
