-- filters.lua
-- Purpose: Pure filtering utilities for WinterChecklist.
-- Scope: Filter by frequency mode (ALL/DAILY/WEEKLY) and by free-text query.
-- Notes: No user-facing strings here. No globals. Keep dependency-light.

local ADDON, NS = ...

-- ===== Constants (avoid magic strings) =====
local MODE = {
  ALL    = "ALL",
  DAILY  = "DAILY",
  WEEKLY = "WEEKLY",
}

-- ===== Local helpers (kept local to avoid globals) =====

-- Normalize mode: accepts nil/"ALL"/"DAILY"/"WEEKLY" in any case.
-- Unknown values are treated as "ALL" (permissive).
local function NormalizeMode(mode)
  local m = (type(mode) == "string") and mode:upper() or nil
  if m == MODE.DAILY or m == MODE.WEEKLY or m == MODE.ALL then return m end
  return MODE.ALL
end

-- Returns true if a task should be included given the normalized mode.
local function TaskPassesMode(task, normMode)
  if normMode == MODE.ALL then return true end
  -- Default frequency is "daily" if absent
  local f = (task.frequency or "daily"):lower()
  if normMode == MODE.DAILY  then return f == "daily"  end
  if normMode == MODE.WEEKLY then return f == "weekly" end
  return true
end

-- Returns true if the task's text contains the (lowercased) query.
-- Query is pre-trimmed and lowercased by the public API below.
local function MatchesQuery(task, lowerQuery)
  if lowerQuery == "" then return true end
  local text = (task.text or ""):lower()
  return text:find(lowerQuery, 1, true) ~= nil
end

-- =====================================================================
-- Public API
-- =====================================================================

-- Small testable helpers (useful for unit-style checks in other files)
function NS.PassesMode(task, mode)        return TaskPassesMode(task, NormalizeMode(mode)) end
function NS.MatchesSearch(task, query)
  local q = query or ""
  if NS and NS.STrim then q = NS.STrim(q) else q = q:match("^%s*(.-)%s*$") or q end
  return MatchesQuery(task, q:lower())
end

-- Filters the given task array using a free-text query and a frequency mode.
-- - tasks: table of task objects { text, frequency, completed }
-- - query: string (trimmed/lowercased; empty query matches all)
-- - mode : "ALL" | "DAILY" | "WEEKLY" (case-insensitive; unknown → "ALL")
function NS.FilterTasks(tasks, query, mode)
  local out, i = {}, 1
  local normMode = NormalizeMode(mode)

  -- Prefer NS.STrim if available; fall back to manual trim to avoid hard dependency
  local q = query or ""
  if NS and NS.STrim then
    q = NS.STrim(q)
  else
    q = q:match("^%s*(.-)%s*$") or q
  end
  local lowerQuery = q:lower()

  for _, t in ipairs(tasks or {}) do
    if TaskPassesMode(t, normMode) and MatchesQuery(t, lowerQuery) then
      out[i] = t
      i = i + 1
    end
  end
  return out
end
