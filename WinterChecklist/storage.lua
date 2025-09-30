-- storage.lua
local ADDON, NS = ...

-- Prefer namespaced helpers
local IsEmpty = NS.IsEmpty

-- Account-wide DB (snapshots, etc.)
function EnsureAccountDB()
  _G.WinterChecklistAccountDB = _G.WinterChecklistAccountDB or { profiles = {} }
  return _G.WinterChecklistAccountDB
end
NS.EnsureAccountDB = EnsureAccountDB

-- Per-character DB (main addon state)
function EnsureDB()
  _G.WinterChecklistDB = _G.WinterChecklistDB or {}
  local db = _G.WinterChecklistDB

  -- defaults
  db.tasks  = db.tasks  or {
    { text = "Sample daily: Turn in daily quest", frequency = "daily",  completed = false },
    { text = "Sample weekly: Kill world boss",    frequency = "weekly", completed = false },
  }
  db.window = db.window or { w = 460, h = 500, x = 0, y = 0, shown = true }
  if db.showMinimap == nil then db.showMinimap = true end
  db.opts   = db.opts   or {}

  --------------------------------------------------------------------
  -- Legacy migration (old db.filter.{search,mode} -> new fields)
  --------------------------------------------------------------------
  -- search: only adopt legacy value if current search is empty
  if db.filter and db.filter.search then
    local empty = (IsEmpty and IsEmpty(db.search)) or (db.search == nil) or (db.search == "")
    if empty then
      db.search = db.filter.search
    end
  end
  db.search = db.search or ""

  -- filterMode: DAILY / WEEKLY / ALL
  if not db.filterMode then
    if db.filter and db.filter.mode then
      local m = db.filter.mode
      if m == "daily"      then db.filterMode = "DAILY"
      elseif m == "weekly" then db.filterMode = "WEEKLY"
      else                      db.filterMode = "ALL"
      end
    else
      db.filterMode = "ALL"
    end
  end

  -- drop legacy container
  db.filter = nil

  return db
end
NS.EnsureDB = EnsureDB

-- Small accessors used by other modules
function NS.GetTasks()      return EnsureDB().tasks end
function NS.SaveTasks(list) EnsureDB().tasks = list end

function NS.GetOpt(k, default)
  local v = EnsureDB().opts[k]
  if v == nil then return default end
  return v
end

function NS.SetOpt(k, v)
  local db = EnsureDB()
  db.opts[k] = v
end

----------------------------------------------------------------------
-- Snapshotting helpers
----------------------------------------------------------------------

local function CurrentCharKey()
  local name  = UnitName("player") or "Unknown"
  local realm = (GetRealmName and GetRealmName() or ""):gsub("%s+", "")
  return ("%s-%s"):format(name, realm)
end

local function DeepCopyTasks(list)
  local out = {}
  for _, t in ipairs(list or {}) do
    out[#out+1] = {
      text       = t.text,
      frequency  = t.frequency,
      completed  = t.completed and true or false,
    }
  end
  return out
end

function NS.SyncProfileSnapshot()
  local adb = EnsureAccountDB()
  local db  = EnsureDB()
  local key = CurrentCharKey()
  adb.profiles[key] = adb.profiles[key] or {}
  adb.profiles[key].tasks   = DeepCopyTasks(db.tasks)
  adb.profiles[key].updated = (time and time()) or 0
end
