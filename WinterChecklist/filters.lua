-- filters.lua
local ADDON, NS = ...

local function TaskPassesMode(task, mode)
  if not mode or mode == "ALL" then return true end
  local f = (task.frequency or "daily"):lower()
  if mode == "DAILY"  then return f == "daily"  end
  if mode == "WEEKLY" then return f == "weekly" end
  return true
end

local function MatchesQuery(task, query)
  if not query or query == "" then return true end
  query = query:lower()
  local text = (task.text or ""):lower()
  return text:find(query, 1, true) ~= nil
end

function NS.FilterTasks(tasks, query, mode)
  local out, i = {}, 1
  for _, t in ipairs(tasks or {}) do
    if TaskPassesMode(t, mode) and MatchesQuery(t, query) then
      out[i] = t
      i = i + 1
    end
  end
  return out
end
