-- tasks.lua
local ADDON, NS = ...

local selIndex = nil

function NS.SelectTask(i) selIndex = i end
function NS.GetSelection() return selIndex end

function NS.EditSelected(newText)
  if not selIndex then return end
  local tasks = NS.GetTasks()
  if tasks[selIndex] then
    tasks[selIndex].text = newText
    NS.SaveTasks(tasks)
    if NS.RefreshUI then NS.RefreshUI() end
    if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
  end
end

function NS.DeleteSelected()
  if not selIndex then return end
  local tasks = NS.GetTasks()
  table.remove(tasks, selIndex)
  selIndex = nil
  NS.SaveTasks(tasks)
  if NS.RefreshUI then NS.RefreshUI() end
  if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
end

function NS.ResetTasks(kind)
  local db = NS.EnsureDB and NS.EnsureDB() or EnsureDB()
  for _, t in ipairs(db.tasks) do
    if kind == "all"
       or (kind == "daily"  and (t.frequency or "daily") == "daily")
       or (kind == "weekly" and (t.frequency or "daily") == "weekly") then
      t.completed = false
    end
  end
  if NS.RefreshUI then NS.RefreshUI() end
  if NS.SyncProfileSnapshot then NS.SyncProfileSnapshot() end
end
