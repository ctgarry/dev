--[[
  @file    lua/profiles.lua
  @brief   Shared list opt-in handling, seeding flow, and SavedVariables helpers.
]]
local ADDON, NS = ...
local U = NS.Util or {}
local L = NS.L or {}

NS.Profiles = NS.Profiles or {}
local M = NS.Profiles

local ACCOUNT_KEY = "Account-Wide"
local SEED_DIALOG = "WCL_SHARED_SEED_PROMPT"

local function currentCharKey()
  local name, realm = UnitFullName and UnitFullName("player")
  name = name or UnitName("player") or "Unknown"
  realm = realm or GetRealmName() or "Realm"
  if realm == "" then
    return name
  end
  return string.format("%s-%s", name, realm)
end

local function prettyCharName()
  local name, realm = UnitFullName and UnitFullName("player")
  if name and realm and realm ~= "" then
    return string.format("%s-%s", name, realm)
  end
  return currentCharKey()
end

local function ensureShared()
  WinterChecklistDB = WinterChecklistDB or {}
  WinterChecklistDB.sharedList = WinterChecklistDB.sharedList or {}
  local shared = WinterChecklistDB.sharedList
  shared.optIn = shared.optIn or {}
  shared.seeded = shared.seeded or {}
  shared.tasks = shared.tasks or {}
  return shared
end

local function normalizeFreq(freq)
  local f = tostring(freq or "all"):lower()
  if f == "daily" or f == "weekly" then
    return f
  end
  return "all"
end

local function normalizeTask(row)
  if type(row) == "string" then
    local txt = U.trim and U.trim(row) or row
    if type(txt) == "string" and txt ~= "" then
      return { text = txt, done = false, freq = "all" }
    end
    return nil
  end
  if type(row) ~= "table" then
    return nil
  end
  local text = row.text or row[1]
  if type(text) ~= "string" or text == "" then
    return nil
  end
  return { text = text, done = not not row.done, freq = normalizeFreq(row.freq) }
end

local function sanitizeTasks(tasks)
  if type(tasks) ~= "table" then
    return {}
  end
  local sanitized = {}
  for _, row in ipairs(tasks) do
    local normalized = normalizeTask(row)
    if normalized then
      sanitized[#sanitized + 1] = normalized
    end
  end
  return sanitized
end

local function ensureRecord(key)
  WinterChecklistDB = WinterChecklistDB or {}
  WinterChecklistDB.chars = WinterChecklistDB.chars or {}
  local rec = WinterChecklistDB.chars[key]
  if not rec then
    rec = {}
    WinterChecklistDB.chars[key] = rec
  end
  rec.tasks = sanitizeTasks(rec.tasks or {})
  return rec
end

local function cloneTasks(tasks)
  local out = {}
  for _, row in ipairs(tasks or {}) do
    out[#out + 1] = { text = row.text, done = not not row.done, freq = normalizeFreq(row.freq) }
  end
  return out
end

local function mergeTasks(existing, incoming)
  local merged = cloneTasks(existing)
  local seen = {}
  for _, row in ipairs(merged) do
    if row.text then
      seen[row.text] = true
    end
  end
  for _, row in ipairs(incoming or {}) do
    if row.text and row.text ~= "" and not seen[row.text] then
      seen[row.text] = true
      merged[#merged + 1] = { text = row.text, done = not not row.done, freq = normalizeFreq(row.freq) }
    end
  end
  return merged
end

local function fireTaskChanged(reason)
  if NS.NotifyTasksChanged then
    NS.NotifyTasksChanged(reason)
  elseif NS.UIList and NS.UIList.Refresh then
    NS.UIList:Refresh()
  end
end

local function refreshWidgets()
  if NS.UIList and NS.UIList.UpdateSharedToggle then
    NS.UIList:UpdateSharedToggle()
  end
  if NS.Options and NS.Options.RefreshSharedCheckbox then
    NS.Options:RefreshSharedCheckbox()
  end
  if NS.RefreshModeBadge then
    NS.RefreshModeBadge()
  end
end

local function showSeedPrompt(text, onChoice)
  if not StaticPopupDialogs then
    StaticPopupDialogs = {}
  end
  StaticPopupDialogs[SEED_DIALOG] = {
    text = text,
    button1 = L.SHARED_SEED_COPY,
    button2 = L.SHARED_SEED_SKIP,
    button3 = L.SHARED_SEED_MERGE,
    OnAccept = function()
      if onChoice then
        onChoice("COPY")
      end
    end,
    OnAltAccept = function()
      if onChoice then
        onChoice("MERGE")
      end
    end,
    OnCancel = function(_, reason)
      if reason == "clicked" then
        if onChoice then
          onChoice("SKIP")
        end
        return
      end
      if onChoice then
        onChoice("ABORT")
      end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }
  StaticPopup_Show(SEED_DIALOG)
end

function M:ApplyActive()
  ensureShared()
  WinterChecklistDB.accountWide = self:IsOptedIn()
end

function M:IsOptedIn(charKey)
  local shared = ensureShared()
  local key = charKey or currentCharKey()
  return not not shared.optIn[key]
end

function M:SetOptIn(enabled)
  local shared = ensureShared()
  local key = currentCharKey()
  if enabled then
    if shared.optIn[key] then
      self:ApplyActive()
      refreshWidgets()
      return
    end
    self:_handleEnable(key)
  else
    if not shared.optIn[key] then
      self:ApplyActive()
      refreshWidgets()
      return
    end
    shared.optIn[key] = nil
    self:_handleDisable(key)
  end
end

function M:_applySeedOutcome(charKey, charTasks, accountTasks, choice)
  local shared = ensureShared()
  local decision = choice or "SKIP"
  local accountRec = ensureRecord(ACCOUNT_KEY)
  if decision == "COPY" then
    accountRec.tasks = cloneTasks(charTasks)
    if (NS.Print or print) and L.SHARED_SEED_COPY_DONE then
      (NS.Print or print)(L.SHARED_SEED_COPY_DONE:format(prettyCharName()))
    end
    fireTaskChanged("SHARED_COPY")
  elseif decision == "MERGE" then
    accountRec.tasks = mergeTasks(accountTasks, charTasks)
    if (NS.Print or print) and L.SHARED_SEED_MERGE_DONE then
      (NS.Print or print)(L.SHARED_SEED_MERGE_DONE:format(prettyCharName()))
    end
    fireTaskChanged("SHARED_MERGE")
  else
    fireTaskChanged("SHARED_SKIP")
  end
  shared.tasks = accountRec.tasks
  shared.seeded[charKey] = true
  self:ApplyActive()
  refreshWidgets()
end

function M:_handleEnable(charKey)
  local shared = ensureShared()
  local charRec = ensureRecord(charKey)
  local accountRec = ensureRecord(ACCOUNT_KEY)
  local charTasks = cloneTasks(charRec.tasks)
  local accountTasks = cloneTasks(accountRec.tasks)

  local function abortEnable()
    shared.optIn[charKey] = nil
    self:ApplyActive()
    refreshWidgets()
    fireTaskChanged("SHARED_ABORT")
  end

  if shared.seeded[charKey] or #charTasks == 0 then
    shared.optIn[charKey] = true
    if not shared.seeded[charKey] and #charTasks == 0 then
      shared.seeded[charKey] = true
    end
    shared.tasks = accountRec.tasks
    self:ApplyActive()
    refreshWidgets()
    fireTaskChanged("SHARED_ENABLE")
    return
  end

  local baseText = (#accountTasks > 0 and L.SHARED_SEED_PROMPT_EXISTING) or L.SHARED_SEED_PROMPT
  local text = baseText:format(prettyCharName())
  showSeedPrompt(text, function(choice)
    if choice == "ABORT" then
      abortEnable()
      return
    end
    if not shared.optIn[charKey] then
      shared.optIn[charKey] = true
    end
    self:_applySeedOutcome(charKey, charTasks, accountTasks, choice)
  end)
end

function M:_handleDisable(charKey)
  -- Do not copy shared into personal; just switch back to the character's own list.
  self:ApplyActive()
  refreshWidgets()
  fireTaskChanged("SHARED_DISABLE")
end

function M:GetAccountKey()
  return ACCOUNT_KEY
end

function M:GetCharacterKey()
  return currentCharKey()
end

function M:Init()
  local shared = ensureShared()
  local legacy = WinterChecklistDB.accountWide
  if not shared._migrated then
    if type(legacy) == "boolean" and legacy then
      for key in pairs(WinterChecklistDB.chars or {}) do
        if key ~= ACCOUNT_KEY then
          shared.optIn[key] = true
          shared.seeded[key] = true
        end
      end
    end
    shared._migrated = true
  end

  local key = currentCharKey()
  if shared.optIn[key] == nil and type(legacy) == "boolean" then
    if legacy then
      shared.optIn[key] = true
      shared.seeded[key] = true
    end
  end

  self:ApplyActive()
  refreshWidgets()
end
