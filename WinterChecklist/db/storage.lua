-- storage.lua
-- Purpose: SavedVariables access, defaults, migrations, accessors, and profile snapshotting.
-- Scope: Account-wide (snapshots) and per-character DB. No compat shims or UI here.
-- Notes: All user-facing sample text is localized. No inline fallbacks. Cross-file API lives on NS.*.

local ADDON, NS = ...

-- Localize globals for perf/safety
local UnitName     = UnitName
local GetRealmName = GetRealmName
local time         = time
local type, tostring, assert = type, tostring, assert

-- ===== Constants (avoid magic numbers & string literals) =====
local DEFAULT_WIDTH   = 460
local DEFAULT_HEIGHT  = 500
local DEFAULT_X       = 0
local DEFAULT_Y       = 0
local DB_VERSION      = 1

local FILTER = {
  DAILY  = "DAILY",
  WEEKLY = "WEEKLY",
  ALL    = "ALL",
}

-- ===== Strict localization helper (prefer NS.T, assert on missing) =====
local T = NS.T or (function(key)
  local L = NS.L or {}
  assert(L[key], "Missing locale key: " .. tostring(key))
  return L[key]
end)

-- Prefer namespaced helpers (from util.lua)
local IsEmpty = NS.IsEmpty

-- =====================================================================
-- Account-wide DB (snapshots, etc.)
-- =====================================================================
local function EnsureAccountDB()
  local adb = _G.WinterChecklistAccountDB
  if type(adb) ~= "table" then
    adb = { profiles = {}, _v = DB_VERSION }
    _G.WinterChecklistAccountDB = adb
  else
    adb.profiles = adb.profiles or {}
    adb._v = adb._v or DB_VERSION
  end
  return adb
end
NS.EnsureAccountDB = EnsureAccountDB

-- =====================================================================
-- Per-character DB (main addon state)
-- =====================================================================
local function applyDefaults(db)
  -- Tasks (user-visible sample text is localized)
  if type(db.tasks) ~= "table" then
    db.tasks = {
      { text = T("SAMPLE_DAILY_TASK"),  frequency = "daily",  completed = false },
      { text = T("SAMPLE_WEEKLY_TASK"), frequency = "weekly", completed = false },
    }
  end

  -- Window defaults
  local w = db.window
  if type(w) ~= "table" then
    w = {}
    db.window = w
  end
  w.w     = tonumber(w.w) or DEFAULT_WIDTH
  w.h     = tonumber(w.h) or DEFAULT_HEIGHT
  w.x     = tonumber(w.x) or DEFAULT_X
  w.y     = tonumber(w.y) or DEFAULT_Y
  w.shown = (w.shown ~= false) -- default true

  -- Options
  if type(db.opts) ~= "table" then db.opts = {} end
  if db.showMinimap == nil then db.showMinimap = true end

  -- Search/filter
  if type(db.search) ~= "string" then db.search = "" end
  if db.filterMode ~= FILTER.DAILY and db.filterMode ~= FILTER.WEEKLY and db.filterMode ~= FILTER.ALL then
    db.filterMode = FILTER.ALL
  end

  -- Version stamp
  db._v = db._v or DB_VERSION
end

local function runMigrations(db)
  -- v0 -> v1: migrate legacy db.filter.{search,mode} if present
  if db._v == nil then
    if type(db.filter) == "table" then
      -- search: only adopt if current search is empty
      if type(db.filter.search) == "string" then
        local empty = (IsEmpty and IsEmpty(db.search)) or (db.search == nil) or (db.search == "")
        if empty then db.search = db.filter.search end
      end
      -- filterMode: DAILY / WEEKLY / ALL
      if db.filter.mode == "daily" then
        db.filterMode = FILTER.DAILY
      elseif db.filter.mode == "weekly" then
        db.filterMode = FILTER.WEEKLY
      end
    end
    db.filter = nil
    db._v = 1
  end
end

local function EnsureDB()
  local db = _G.WinterChecklistDB
  if type(db) ~= "table" then
    db = {}
    _G.WinterChecklistDB = db
  end

  runMigrations(db)
  applyDefaults(db)
  return db
end
NS.EnsureDB = EnsureDB

-- =====================================================================
-- Small accessors used by other modules
-- =====================================================================
function NS.GetTasks()                 return EnsureDB().tasks end
function NS.SaveTasks(list)            EnsureDB().tasks = list end

function NS.GetOpt(k, default)
  local v = EnsureDB().opts[k]
  if v == nil then return default end
  return v
end

function NS.SetOpt(k, v)
  EnsureDB().opts[k] = v
end

-- --- Window placement -------------------------------------------------
function NS.GetWindow()
  local w = EnsureDB().window
  return w.w, w.h, w.x, w.y, w.shown
end

function NS.SetWindow(wd, ht, x, y, shown)
  local w = EnsureDB().window
  if wd then w.w = tonumber(wd) or w.w end
  if ht then w.h = tonumber(ht) or w.h end
  if x  then w.x = tonumber(x)  or w.x end
  if y  then w.y = tonumber(y)  or w.y end
  if shown ~= nil then w.shown = shown and true or false end
end

-- --- Search/filter ----------------------------------------------------
function NS.GetSearch()                return EnsureDB().search end
function NS.SetSearch(s)               EnsureDB().search = type(s) == "string" and s or "" end

function NS.GetFilterMode()            return EnsureDB().filterMode end
function NS.SetFilterMode(mode)
  if mode == FILTER.DAILY or mode == FILTER.WEEKLY or mode == FILTER.ALL then
    EnsureDB().filterMode = mode
  end
end

-- --- Minimap toggle ---------------------------------------------------
function NS.GetShowMinimap()           return EnsureDB().showMinimap end
function NS.SetShowMinimap(b)          EnsureDB().showMinimap = (b and true or false) end

-- --- Hard reset (keeps account snapshots) -----------------------------
function NS.ResetDefaults()
  _G.WinterChecklistDB = {}
  return EnsureDB()
end

-- =====================================================================
-- Snapshotting helpers
-- =====================================================================
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

function NS.GetProfileSnapshot(charKey)
  local adb = EnsureAccountDB()
  return (adb.profiles or {})[charKey or CurrentCharKey()]
end
