-- WinterChecklist.lua
-- Lightweight checklist addon for Retail & Classic Era.
-- SavedVariablesPerCharacter: WinterChecklistDB
-- For profile management, add to your .toc:
-- ## SavedVariables: WinterChecklistAccountDB

local ADDON, NS = ...

----------------------------------------------------------------------
-- Constants & small utils
----------------------------------------------------------------------
local PAD = 10
local BOTTOM_BAR_H = 48 -- space for radios + zone + refresh
local function STrim(s) if not s then return "" end return (s:gsub("^%s+",""):gsub("%s+$","")) end
local function IsEmpty(s) return STrim(s) == "" end
local function Print(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Checklist|r: "..(msg or "")) end

local function SafeSetResizeBounds(frame, minW, minH, maxW, maxH)
  if frame.SetResizeBounds then frame:SetResizeBounds(minW, minH, maxW, maxH)
  elseif frame.SetMinResize then frame:SetMinResize(minW, minH) end
end

-- ------------------------------------------------------------
-- Cross-version Icon Helpers (Retail unicode / Classic texture)
-- ------------------------------------------------------------
local IS_RETAIL = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

NS.ICON_REG = NS.ICON_REG or {
  gear = {
    unicode   = "⚙",                                -- U+2699 (Retail fonts usually have it)
    texture   = "Interface\\Buttons\\UI-OptionsButton",
    size      = 16,
    texCoords = {5/64, 59/64, 5/64, 59/64},         -- crop border
    padW      = 10,
  },
  link = {
    unicode   = "🔗",                                -- Retail: U+1F517
    texture   = "Interface\\ICONS\\INV_Misc_Map_01", -- Classic-safe generic link/map icon
    size      = 16,
    padW      = 10,
  },
  refresh = {
    unicode   = "⟳",                                 -- Retail: U+27F3
    texture   = "Interface\\Buttons\\UI-RefreshButton", -- Falls back to texture on Classic
    size      = 16,
    padW      = 10,
  },
  arrow = {
    unicode   = "→",                                      -- U+2192 (Retail fonts usually have it)
    texture   = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up", -- Classic-safe right arrow
    size      = 12,
    padW      = 4,
    texCoords = {8/64, 56/64, 8/64, 56/64},               -- crop border so it looks clean
  },
    -- Add more icons later as needed
}

-- Return a text token for SetText(): Retail -> unicode, Classic -> |T...|t
function NS.IconText(key, opts)
  opts = opts or {}
  local ic = NS.ICON_REG[key]; if not ic then return "" end
  if IS_RETAIL and ic.unicode and not opts.forceTexture then
    return ic.unicode
  end
  local size = opts.size or ic.size or 16
  local l, r, t, b = 0, 1, 0, 1
  if ic.texCoords then l, r, t, b = unpack(ic.texCoords) end
  return ("|T%s:%d:%d:0:0:64:64:%d:%d:%d:%d|t"):
    format(ic.texture, size, size, l*64, r*64, t*64, b*64)
end

-- Apply icon (and optional label) to a button with :SetText
-- opts: size, textAfter, textBefore, forceTexture, padW
function NS.ApplyIcon(btn, key, opts)
  opts = opts or {}
  local ic = NS.ICON_REG[key]; if not ic then return end
  local padW = (opts.padW ~= nil and opts.padW) or ic.padW or 8
  local icon = NS.IconText(key, opts)
  local txt = (opts.textBefore or "") .. icon .. (opts.textAfter or "")
  if btn.SetText then btn:SetText(txt) end
  if (opts.textAfter or opts.textBefore) and btn.GetTextWidth then
    btn:SetWidth(math.max(btn:GetTextWidth() + 16, (opts.size or ic.size or 16) + padW + 12))
  else
    btn:SetWidth((opts.size or ic.size or 16) + padW + 4)
  end
end

-- Convenience creator for small icon buttons
function NS.SmallIconBtn(parent, key, tooltip, opts)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetHeight(26)
  NS.ApplyIcon(b, key, opts)
  if tooltip then
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(tooltip, 1,1,1,1,true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  end
  return b
end

local function ToggleWorldMapGeneric()
  if ToggleWorldMap then ToggleWorldMap(); return end
  if WorldMapFrame then
    if WorldMapFrame:IsShown() then
      if HideUIPanel then HideUIPanel(WorldMapFrame) else WorldMapFrame:Hide() end
    else
      if ShowUIPanel then ShowUIPanel(WorldMapFrame) else WorldMapFrame:Show() end
    end
  end
end

----------------------------------------------------------------------
-- Copy-to-clipboard popup (Blizzard StaticPopup)
----------------------------------------------------------------------
StaticPopupDialogs["WINTERCHECKLIST_COPY_LINK"] = {
  text = "Ctrl+A, Ctrl+C to Copy to your Clipboard.",
  button1 = OKAY,
  hasEditBox = true,
  showAlert = true,            -- yellow '!' icon like the reference screenshot
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  enterClicksFirstButton = true,
  preferredIndex = 3,          -- avoid taint with other dialogs

  OnShow = function(self, data)
    local eb = self.editBox
    eb:SetText(type(data) == "string" and data or "")
    eb:HighlightText()
    eb:SetFocus()
  end,

  EditBoxOnEscapePressed = function(self)
    self:GetParent():Hide()
  end,
}

StaticPopupDialogs["WCL_COPY_CONFIRM"] = {
  text = "", -- set at runtime
  button1 = YES,
  button2 = NO,
  OnShow = function(self, data)
    self.text:SetText(data and data.msg or "")
  end,
  OnAccept = function(self, data)
    if not data or not data.srcTasks then return end
    local db2 = EnsureDB()
    db2.tasks = DeepCopyTasks(data.srcTasks)
    UI.RefreshTaskList()
    SyncProfileSnapshot()
  end,
  timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

local function ShowCopyLinkPopup(url)
  StaticPopup_Show("WINTERCHECKLIST_COPY_LINK", nil, nil, url)
end

----------------------------------------------------------------------
-- Saved variables (per-char + account for profiles)
----------------------------------------------------------------------
local function EnsureAccountDB()
  _G.WinterChecklistAccountDB = _G.WinterChecklistAccountDB or { profiles = {} }
  return _G.WinterChecklistAccountDB
end

local function EnsureDB()
  _G.WinterChecklistDB = _G.WinterChecklistDB or {}
  local db = _G.WinterChecklistDB

  db.tasks = db.tasks or {
    { text = "Sample daily: Turn in daily quest", frequency = "daily", completed = false },
    { text = "Sample weekly: Kill world boss",    frequency = "weekly", completed = false },
  }
  db.window = db.window or { w = 460, h = 500, x = 0, y = 0, shown = true }
  if db.showMinimap == nil then db.showMinimap = true end

  -- migrate legacy
  if db.filter and db.filter.search and IsEmpty(db.search) then db.search = db.filter.search end
  db.search = db.search or ""
  if not db.filterMode then
    if db.filter and db.filter.mode then
      local m = db.filter.mode
      if m == "daily" then db.filterMode = "DAILY"
      elseif m == "weekly" then db.filterMode = "WEEKLY"
      else db.filterMode = "ALL" end
    else db.filterMode = "ALL" end
  end
  db.filter = nil -- remove legacy

  return db
end

local function CurrentCharKey()
  local name = UnitName("player") or "Unknown"
  local realm = GetRealmName and GetRealmName() or ""
  realm = realm:gsub("%s+", "")
  return ("%s-%s"):format(name, realm)
end

local function DeepCopyTasks(list)
  local out = {}
  for _,t in ipairs(list or {}) do
    table.insert(out, { text = t.text, frequency = t.frequency, completed = t.completed and true or false })
  end
  return out
end

local function SyncProfileSnapshot()
  local adb = EnsureAccountDB()
  local db = EnsureDB()
  local key = CurrentCharKey()
  adb.profiles[key] = adb.profiles[key] or {}
  adb.profiles[key].tasks = DeepCopyTasks(db.tasks)
  adb.profiles[key].updated = time and time() or 0
end

----------------------------------------------------------------------
-- Filtering
----------------------------------------------------------------------
local function TaskPassesFilter(task, mode)
  if mode == "DAILY"  then return task.frequency == "daily"  end
  if mode == "WEEKLY" then return task.frequency == "weekly" end
  return true
end

----------------------------------------------------------------------
-- UI state
----------------------------------------------------------------------
local UI = {
  frame = nil,
  listParent = nil,
  rows = {},
  filtered = {},
  lastClickedIndex = nil,
  help = nil,
  gear = nil,
  popImport = nil,
  popExport = nil,
  context = nil,
  radios = nil,
  controls = {},
  options = {
    panel = nil,
  },
}

local function HideAllPopups()
  if UI.help then UI.help:Hide() end
  if UI.gear then UI.gear:Hide() end
  if UI.popImport then UI.popImport:Hide() end
  if UI.popExport then UI.popExport:Hide() end
  if UI.context then UI.context:Hide() end
end

local function MakeOpaqueBackground(frame)
  local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
  bg:SetAllPoints(true)
  bg:SetColorTexture(0, 0, 0, 1)
  return bg
end

local function ResetTasks(kind)
  local db = EnsureDB()
  for _, t in ipairs(db.tasks) do
    if kind == "all"
       or (kind == "daily"  and t.frequency == "daily")
       or (kind == "weekly" and t.frequency == "weekly") then
      t.completed = false
    end
  end
  UI.RefreshTaskList(); SyncProfileSnapshot()
end

----------------------------------------------------------------------
-- Small popups (Prompt / Import / Export / Confirm)
----------------------------------------------------------------------
local function SimplePrompt(parent, title, initialText, onOK)
  HideAllPopups()
  local p = CreateFrame("Frame", nil, parent, "BasicFrameTemplateWithInset")
  p:SetSize(360, 140)
  p:SetPoint("CENTER", parent, "CENTER", 0, 30)
  p:EnableMouse(true)
  p:SetMovable(true)
  p:RegisterForDrag("LeftButton")
  p:SetScript("OnDragStart", p.StartMoving)
  p:SetScript("OnDragStop", p.StopMovingOrSizing)
  if p.TitleText then p.TitleText:SetText(title) end
  MakeOpaqueBackground(p)

  local eb = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
  eb:SetAutoFocus(true)
  eb:SetSize(320, 24)
  eb:SetPoint("TOP", p, "TOP", 0, -40)
  eb:SetText(initialText or "")
  eb:HighlightText()

  local ok = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  ok:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -10, 8)
  ok:SetSize(90, 22) ok:SetText("OK")
  local cancel = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  cancel:SetPoint("RIGHT", ok, "LEFT", -8, 0)
  cancel:SetSize(90, 22) cancel:SetText("Cancel")

  ok:SetScript("OnClick", function()
    local t = STrim(eb:GetText() or "")
    if IsEmpty(t) then Print("Please enter text."); return end
    onOK(t); p:Hide(); p:SetParent(nil)
  end)
  cancel:SetScript("OnClick", function() p:Hide() end)
  eb:SetScript("OnEnterPressed", ok:GetScript("OnClick"))
  eb:SetScript("OnEscapePressed", cancel:GetScript("OnClick"))
  p:EnableKeyboard(true)
  p:SetScript("OnKeyDown", function(self, key) if key == "ESCAPE" then cancel:Click() end end)
end

local function BuildHelpBodyText()
  local arrow = NS.IconText("arrow", { size = 12 })  -- Retail: "→", Classic: texture
  return table.concat({
    "|cffffff00Quick UI how-to|r",
    "• Use the search box to filter tasks.",
    "• Radio buttons at the bottom filter: All / Daily / Weekly.",
    "• + to add, E to edit selected, - to delete.",
    "• Right-click a row for actions.",
    "• Click a task's checkbox to mark complete/incomplete.",
    "• Drag the window by its title; drag the bottom-right corner to resize.",
    ("• Zone button %s opens the world map."):format(arrow),
    "• Minimap button toggles this window (can be hidden in AddOns options).",
    "",
    "|cffffff00Commands|r",
    ("/wcl %s toggle the window"):format(arrow),
    ("/wcl add <text> %s add a daily task"):format(arrow),
    ("/wcl addw <text> %s add a weekly task"):format(arrow),
    ("/wcl minimap %s toggle the minimap button"):format(arrow),
    ("/wcl reset %s reset all tasks to incomplete"):format(arrow),
    ("/wcl reset daily %s reset only daily tasks."):format(arrow),
    ("/wcl reset weekly %s reset only weekly tasks."):format(arrow),
    ("/wcl help %s show this help"):format(arrow),
    "",
    "|cffffd200Developer Notes|r",
    "Quick reset: |cffffff78/wcl fixframe|r resets size & position. Or hard reset with:",
    "|cffaaaaaa/run if WinterChecklistDB then WinterChecklistDB.window=nil end ReloadUI()|r",
  }, "\n")
end

local function ToggleHelp(parent)
  if UI.help and UI.help:IsShown() then UI.help:Hide(); return end
  HideAllPopups()

  local f = parent
  local closeBtn = _G[(f:GetName() or "") .. "CloseButton"]

  local h = CreateFrame("Frame", nil, parent, "BasicFrameTemplateWithInset")
  h:SetSize(380, 420)
  h:SetClampedToScreen(true)

  if closeBtn then
    -- Position so the HELP CONTENT's TOPLEFT is ~8px right, 6px down of the addon's X.
    h:ClearAllPoints()
    h:SetPoint("TOPLEFT", closeBtn, "BOTTOMRIGHT", 0, 22)
  else
    -- Fallback: open to the right of the addon
    h:ClearAllPoints()
    h:SetPoint("TOPLEFT", parent, "TOPRIGHT", 8, -30)
  end

  if h.TitleText then h.TitleText:SetText("Checklist — Help") end
  MakeOpaqueBackground(h)

  local sf = CreateFrame("ScrollFrame", nil, h, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", h, "TOPLEFT", 8, -28)
  sf:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", -28, 40)
  local body = CreateFrame("Frame", nil, sf); sf:SetScrollChild(body)
  body:SetSize(320, 1000)

  local text = body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  text:SetPoint("TOPLEFT"); text:SetWidth(320); text:SetJustifyH("LEFT")
  text:SetText(BuildHelpBodyText())

  local close = CreateFrame("Button", nil, h, "UIPanelButtonTemplate")
  close:SetPoint("BOTTOMLEFT", h, "BOTTOMLEFT", 8, 10)
  close:SetSize(90, 22); close:SetText("Close")
  close:SetScript("OnClick", function() h:Hide() end)

  h:EnableKeyboard(true)
  h:SetScript("OnKeyDown", function(self, key) if key == "ESCAPE" then self:Hide() end end)

  UI.help = h
  h:Show()
end

-- Import / Export helpers
local function SerializeTasks(db)
  local out = {}
  for _,t in ipairs(db.tasks) do
    local prefix = (t.frequency == "weekly") and "w: " or "d: "
    table.insert(out, prefix .. (t.text or ""))
  end
  return table.concat(out, "\n")
end

local function ParseTasks(s)
  local list = {}
  for line in (s.."\n"):gmatch("([^\n]*)\n") do
    local L = STrim(line)
    if not IsEmpty(L) then
      local freq, txt = "daily", L
      local tag, rest = L:match("^([dDwW])%s*:%s*(.*)$")
      if tag and rest then freq = (tag == "w" or tag == "W") and "weekly" or "daily"; txt = rest end
      table.insert(list, { text = txt, frequency = freq, completed = false })
    end
  end
  return list
end

local function ShowExport(parent)
  HideAllPopups()
  local db = EnsureDB()
  local w = math.max(340, math.min(parent:GetWidth() - 40, 560))

  local f = CreateFrame("Frame", nil, parent, "BasicFrameTemplateWithInset")
  f:SetSize(w, 260)
  f:SetPoint("CENTER", parent, "CENTER")
  if f.TitleText then f.TitleText:SetText("Export Tasks — Copy") end
  MakeOpaqueBackground(f)

  local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -28)
  sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 36)

  local eb = CreateFrame("EditBox", nil, sf)
  eb:SetMultiLine(true); eb:SetFontObject(ChatFontNormal)
  eb:SetWidth(w - 40)
  eb:SetText(SerializeTasks(db))
  sf:SetScrollChild(eb)
  eb:HighlightText(); eb:SetFocus()

  local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  close:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 8)
  close:SetSize(90, 22); close:SetText("Close")
  close:SetScript("OnClick", function() f:Hide() end)

  f:EnableKeyboard(true)
  f:SetScript("OnKeyDown", function(self, key) if key == "ESCAPE" then self:Hide() end end)

  UI.popExport = f
  f:Show()
end

-- Import confirmation (NO reassignment of StaticPopupDialogs)
StaticPopupDialogs["WCL_IMPORT_CONFIRM"] = {
  text = "Import will delete all the current tasks and replace them with the imported list. Are you sure?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function(self, data)
    if not data or not data.list then return end
    local db = EnsureDB()
    db.tasks = data.list
    UI.RefreshTaskList()
    SyncProfileSnapshot()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

local function ShowImport(parent)
  HideAllPopups()
  local w = math.max(340, math.min(parent:GetWidth() - 40, 560))

  local f = CreateFrame("Frame", nil, parent, "BasicFrameTemplateWithInset")
  f:SetSize(w, 300)
  f:SetPoint("CENTER", parent, "CENTER")
  if f.TitleText then f.TitleText:SetText("Import Tasks — One per line (prefix with d: or w:)") end
  MakeOpaqueBackground(f)

  local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -28)
  sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 36)

  local eb = CreateFrame("EditBox", nil, sf)
  eb:SetMultiLine(true); eb:SetFontObject(ChatFontNormal)
  eb:SetWidth(w - 40)
  eb:SetText("d: Do a daily\nw: Do a weekly")
  sf:SetScrollChild(eb)
  eb:HighlightText(); eb:SetFocus()

  local ok = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  ok:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 8)
  ok:SetSize(100, 22); ok:SetText("Import")
  local cancel = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  cancel:SetPoint("RIGHT", ok, "LEFT", -8, 0)
  cancel:SetSize(90, 22); cancel:SetText("Cancel")

  ok:SetScript("OnClick", function()
    local list = ParseTasks(eb:GetText() or "")
    if #list == 0 then Print("Nothing to import."); return end
    StaticPopup_Hide("WCL_IMPORT_CONFIRM")
    StaticPopup_Show("WCL_IMPORT_CONFIRM", nil, nil, { list = list })
  end)
  cancel:SetScript("OnClick", function() f:Hide() end)

  f:EnableKeyboard(true)
  f:SetScript("OnKeyDown", function(self, key) if key == "ESCAPE" then self:Hide() end end)

  UI.popImport = f
  f:Show()
end

----------------------------------------------------------------------
-- Right-click mini menu (row)
----------------------------------------------------------------------
local function HideContext() if UI.context then UI.context:Hide() end end
local function ShowContextForRow(parent, row, task)
  HideAllPopups()
  local f = CreateFrame("Frame", nil, parent, "BasicFrameTemplateWithInset")
  f:SetSize(160, 110)
  f:SetPoint("BOTTOMLEFT", row, "TOPLEFT", 0, 6)
  MakeOpaqueBackground(f)

  local function addBtn(label, yOff, onClick)
    local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    b:SetSize(140, 22)
    b:SetPoint("TOPLEFT", f, "TOPLEFT", 10, yOff)
    b:SetText(label)
    b:SetScript("OnClick", function() onClick(); f:Hide() end)
    return b
  end

  addBtn("Make Daily",  -12, function() task.frequency = "daily"; UI.RefreshTaskList(); SyncProfileSnapshot() end)
  addBtn("Make Weekly", -36, function() task.frequency = "weekly"; UI.RefreshTaskList(); SyncProfileSnapshot() end)
  addBtn("Delete",      -60, function()
    local db = EnsureDB()
    for i,t in ipairs(db.tasks) do if t == task then table.remove(db.tasks, i); break end end
    UI.lastClickedIndex = nil
    UI.RefreshTaskList()
    SyncProfileSnapshot()
  end)

  UI.context = f
  f:Show()
end

----------------------------------------------------------------------
-- Gear menu (Import/Export/Reset)
----------------------------------------------------------------------
local function ToggleGear(parent)
  if UI.gear and UI.gear:IsShown() then UI.gear:Hide(); return end
  HideAllPopups()

  local f = parent
  local closeBtn = _G[(f:GetName() or "") .. "CloseButton"]

  local g = CreateFrame("Frame", nil, parent, "BasicFrameTemplateWithInset")
  g:SetSize(180, 140)
  if closeBtn then
    g:SetPoint("TOPLEFT", closeBtn, "BOTTOMRIGHT", 8, -6)
  else
    g:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 8, 0)
  end
  if g.TitleText then g.TitleText:SetText("Checklist — Tools") end
  MakeOpaqueBackground(g)

  local bImp = CreateFrame("Button", nil, g, "UIPanelButtonTemplate")
  bImp:SetSize(140, 22); bImp:SetPoint("TOPLEFT", g, "TOPLEFT", 20, -36); bImp:SetText("Import")
  bImp:SetScript("OnClick", function() g:Hide(); ShowImport(parent) end)

  local bExp = CreateFrame("Button", nil, g, "UIPanelButtonTemplate")
  bExp:SetSize(140, 22); bExp:SetPoint("TOPLEFT", bImp, "BOTTOMLEFT", 0, -6); bExp:SetText("Export")
  bExp:SetScript("OnClick", function() g:Hide(); ShowExport(parent) end)

  local bRD = CreateFrame("Button", nil, g, "UIPanelButtonTemplate")
  bRD:SetSize(140, 22); bRD:SetPoint("TOPLEFT", bExp, "BOTTOMLEFT", 0, -6); bRD:SetText("Reset Daily")
  bRD:SetScript("OnClick", function()
    ResetTasks("daily")
    g:Hide()
  end)

  local bRW = CreateFrame("Button", nil, g, "UIPanelButtonTemplate")
  bRW:SetSize(140, 22); bRW:SetPoint("TOPLEFT", bRD, "BOTTOMLEFT", 0, -6); bRW:SetText("Reset Weekly")
  bRW:SetScript("OnClick", function()
    ResetTasks("weekly")
    g:Hide()
  end)

  UI.gear = g
  g:Show()
end

----------------------------------------------------------------------
-- Main frame + layout
----------------------------------------------------------------------
local function UpdateTitleCount(db)
  if not UI.frame or not UI.frame.TitleText then return end
  local vis, done = 0, 0
  for _,t in ipairs(UI.filtered or {}) do vis = vis + 1; if t.completed then done = done + 1 end end
  UI.frame.TitleText:SetText(("Checklist (%d/%d)"):format(done, vis))
end

local function CreateResizeGrip(frame, db)
  local grip = CreateFrame("Button", nil, frame)
  grip:SetPoint("BOTTOMRIGHT", -3, 3)
  grip:SetSize(16, 16)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  frame:SetResizable(true)
  grip:SetScript("OnMouseDown", function(self) self:GetParent():StartSizing("BOTTOMRIGHT") end)
  grip:SetScript("OnMouseUp", function(self)
    local p = self:GetParent(); p:StopMovingOrSizing()
    local d = EnsureDB()
    d.window = d.window or { w = 460, h = 500, x = 0, y = 0, shown = UI.frame and UI.frame:IsShown() or true }
    d.window.w, d.window.h = p:GetSize()
  end)
end

local function CreateMainFrame(db)
  if UI.frame then return end

  local f = CreateFrame("Frame", "WinterChecklistFrame", UIParent, "BasicFrameTemplateWithInset")
  f:SetClampedToScreen(true)
  SafeSetResizeBounds(f, 360, 320, 1100, 1000)
  f:SetPoint("CENTER", UIParent, "CENTER", db.window.x or 0, db.window.y or 0)
  f:SetSize(db.window.w or 460, db.window.h or 500)
  f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local px, py = UIParent:GetCenter()
    local x,  y  = self:GetCenter()
    local d = EnsureDB()
    d.window = d.window or { w = 460, h = 500, x = 0, y = 0, shown = UI.frame and UI.frame:IsShown() or true }
    d.window.x, d.window.y = x - px, y - py
  end)
  f:SetScript("OnSizeChanged", function(self, w, h)
    local d = EnsureDB()
    d.window = d.window or { w = 460, h = 500, x = 0, y = 0, shown = UI.frame and UI.frame:IsShown() or true }
    d.window.w, d.window.h = w, h
  end)
  if f.TitleText then f.TitleText:SetText("Checklist") end
  CreateResizeGrip(f, db)

  UI.frame = f

  -- Top controls
  local top = CreateFrame("Frame", nil, f)
  top:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -30)
  top:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -30)
  top:SetHeight(48)

  -- Search
  local search = CreateFrame("EditBox", nil, top, "InputBoxTemplate")
  search:SetAutoFocus(false); search:SetHeight(24); search:SetText(db.search or "")
  UI.controls.search = search

  -- Buttons: Add, Edit, Delete, Gear, Help
  local function MakeBtn(label, w)
    local b = CreateFrame("Button", nil, top, "UIPanelButtonTemplate")
    b:SetSize(w or 28, 22)
    b:SetText(label)
    return b
  end

  local bAdd  = MakeBtn("+")
  local bEdit = MakeBtn("E")
  local bDel  = MakeBtn("-")
  local bGear = NS.SmallIconBtn(top, "gear", "Tools / Import/Export") -- icon-only (keep)
  local bHelp = MakeBtn("?")

  -- layout: right-align buttons, search fills remaining
  local function RelayoutTop()
    local w = top:GetWidth()
    local pad = 6
    local buttons = { bHelp, bGear, bDel, bEdit, bAdd } -- laid out right->left
    local total = 0
    for _,b in ipairs(buttons) do total = total + b:GetWidth() end
    total = total + pad * (#buttons - 1)

    for _,b in ipairs(buttons) do b:ClearAllPoints() end
    search:ClearAllPoints()

    if w >= total + 160 then
      -- one line
      local x = w
      for i, b in ipairs(buttons) do
        x = x - b:GetWidth()
        b:SetPoint("TOPLEFT", top, "TOPLEFT", x, 0)
        x = x - pad
      end
      search:SetPoint("LEFT", top, "LEFT", 0, 0)
      search:SetPoint("RIGHT", buttons[#buttons], "LEFT", -pad, 0)
      search:SetHeight(22)
    else
      -- two lines: search on top (full width), buttons below left-to-right
      search:SetPoint("TOPLEFT", top, "TOPLEFT", 0, 0)
      search:SetPoint("TOPRIGHT", top, "TOPRIGHT", 0, 0)
      search:SetHeight(22)
      local x = 0
      for _, b in ipairs({ bAdd, bEdit, bDel, bGear, bHelp }) do
        b:SetPoint("TOPLEFT", top, "TOPLEFT", x, -28)
        x = x + b:GetWidth() + pad
      end
    end
  end
  top:SetScript("OnSizeChanged", RelayoutTop); C_Timer.After(0, RelayoutTop)

  search:SetScript("OnTextChanged", function(self)
    db.search = self:GetText() or ""
    UI.RefreshTaskList()
  end)

  -- Add/Edit/Delete with guard
  bAdd:SetScript("OnClick", function()
    local defaultFreq = (db.filterMode == "WEEKLY") and "weekly" or ((db.filterMode == "DAILY") and "daily" or "daily")
    SimplePrompt(f, "Add Task", "", function(text)
      table.insert(db.tasks, { text = text, frequency = defaultFreq, completed = false })
      UI.RefreshTaskList(); SyncProfileSnapshot()
    end)
  end)

  bEdit:SetScript("OnClick", function()
    local idx = UI.lastClickedIndex
    if not idx or not UI.filtered or not UI.filtered[idx] then Print("Click a task first, then press E to edit."); return end
    local task = UI.filtered[idx]
    SimplePrompt(f, "Edit Task", task.text or "", function(text)
      task.text = text
      UI.RefreshTaskList(); SyncProfileSnapshot()
    end)
  end)

  bDel:SetScript("OnClick", function()
    local idx = UI.lastClickedIndex
    if not idx or not UI.filtered or not UI.filtered[idx] then Print("Click a task first, then press - to delete."); return end
    local toDelete = UI.filtered[idx]
    for i,t in ipairs(db.tasks) do if t == toDelete then table.remove(db.tasks, i); break end end
    UI.lastClickedIndex = nil
    UI.RefreshTaskList(); SyncProfileSnapshot()
  end)

  bHelp:SetScript("OnClick", function() ToggleHelp(f) end)
  bGear:SetScript("OnClick", function() ToggleGear(f) end)

  -- List area
  local listBG = CreateFrame("Frame", nil, f, "InsetFrameTemplate3")
  listBG:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -82)
  listBG:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, BOTTOM_BAR_H)

  local scroll = CreateFrame("ScrollFrame", nil, listBG, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", listBG, "TOPLEFT", 4, -4)
  scroll:SetPoint("BOTTOMRIGHT", listBG, "BOTTOMRIGHT", -28, 4)
  local scrollChild = CreateFrame("Frame", nil, scroll)
  scroll:SetScrollChild(scrollChild)
  scrollChild:SetSize(1, 1)
  UI.listParent = scrollChild

  -- Bottom bar
  local bottom = CreateFrame("Frame", nil, f)
  bottom:SetPoint("LEFT", f, "LEFT", PAD, 0)
  bottom:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
  bottom:SetPoint("BOTTOM", f, "BOTTOM", 0, PAD/2)
  bottom:SetHeight(BOTTOM_BAR_H - PAD/2)

  -- Radios
  local radios = CreateFrame("Frame", nil, bottom)
  radios:SetSize(260, 22)
  radios:SetPoint("BOTTOMLEFT", bottom, "BOTTOMLEFT", 0, 22)

  local function makeRadio(parent, label, x, mode)
    local r = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
    r:SetPoint("LEFT", parent, "LEFT", x, 0)
    local lab = r.Text or r.text or _G[(r:GetName() or "") .. "Text"]
    if not lab then lab = r:CreateFontString(nil, "ARTWORK", "GameFontHighlight"); lab:SetPoint("LEFT", r, "RIGHT", 2, 0) end
    lab:SetText(label); r._labelFS = lab
    r:SetScript("OnClick", function()
      if not r:GetChecked() then r:SetChecked(true) end
      for _, other in ipairs(parent._all or {}) do if other ~= r then other:SetChecked(false) end end
      db.filterMode = mode; UI.RefreshTaskList()
    end)
    r.mode = mode
    return r
  end

  radios._all = {}
  radios.all    = makeRadio(radios, "All",    0,   "ALL")
  radios.daily  = makeRadio(radios, "Daily",  70,  "DAILY")
  radios.weekly = makeRadio(radios, "Weekly", 150, "WEEKLY")
  table.insert(radios._all, radios.all); table.insert(radios._all, radios.daily); table.insert(radios._all, radios.weekly)
  UI.radios = radios

  -- Zone button
  local zoneBtn = CreateFrame("Button", nil, bottom, "UIPanelButtonTemplate")
  zoneBtn:SetPoint("BOTTOMLEFT", bottom, "BOTTOMLEFT", 0, 0)
  zoneBtn:SetSize(180, 22)
  zoneBtn:SetText("Zone: —")
  zoneBtn:SetScript("OnClick", ToggleWorldMapGeneric)
  UI.controls.zoneBtn = zoneBtn

  -- Refresh button (right)
  local refreshBtn = CreateFrame("Button", nil, bottom, "UIPanelButtonTemplate")
  refreshBtn:SetPoint("BOTTOMRIGHT", bottom, "BOTTOMRIGHT", 0, 0)
  refreshBtn:SetSize(110, 22)
  NS.ApplyIcon(refreshBtn, "refresh", { textAfter = " Refresh" })
  refreshBtn:SetScript("OnClick", function() UI.RefreshTaskList() end)
  UI.controls.refresh = refreshBtn

  -- Initialize radios
  radios.all:SetChecked(db.filterMode == "ALL")
  radios.daily:SetChecked(db.filterMode == "DAILY")
  radios.weekly:SetChecked(db.filterMode == "WEEKLY")
end

----------------------------------------------------------------------
-- Rendering (rows, highlight, context)
----------------------------------------------------------------------
local function ApplyFilters(db)
  local q = db.search and db.search:lower() or nil
  local out = {}
  for _, t in ipairs(db.tasks) do
    local okMode = TaskPassesFilter(t, db.filterMode)
    local okSearch = (not q) or (t.text and t.text:lower():find(q, 1, true))
    if okMode and okSearch then table.insert(out, t) end
  end
  return out
end

local function SetRowSelected(i, selected)
  local row = UI.rows[i]; if not row then return end
  row.selBG:SetShown(selected)
  row.text:SetTextColor(selected and 1 or 0.9, selected and 0.95 or 0.9, selected and 0.6 or 0.9, 1)
end

function UI.RefreshTaskList()
  local db = EnsureDB()
  if not UI.listParent then return end

  HideContext()

  UI.filtered = ApplyFilters(db)

  for i = 1, #UI.filtered do
    if not UI.rows[i] then
      local row = CreateFrame("Frame", nil, UI.listParent)
      row:SetSize(UI.listParent:GetWidth() - 10, 22)

      local bg = row:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints(); bg:SetColorTexture(0.25, 0.25, 0.1, 0.35); bg:Hide()
      row.selBG = bg

      row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
      row.check:SetPoint("LEFT", 0, 0); row.check:SetScale(0.9); row.check:SetHitRectInsets(0, -10, 0, 0)

      row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      row.text:SetPoint("LEFT", row.check, "RIGHT", 6, 0)
      row.text:SetJustifyH("LEFT"); row.text:SetWordWrap(false); row.text:SetText("")

      if i == 1 then row:SetPoint("TOPLEFT", UI.listParent, "TOPLEFT", 6, -6)
      else row:SetPoint("TOPLEFT", UI.rows[i-1], "BOTTOMLEFT", 0, -6) end

      row:EnableMouse(true)
      row:SetScript("OnMouseDown", function(self, btn)
        for j = 1, #UI.rows do SetRowSelected(j, false) end
        for j, r in ipairs(UI.rows) do if r == self then UI.lastClickedIndex = j; SetRowSelected(j, true); break end end
        if btn == "RightButton" then
          local idx = UI.lastClickedIndex
          if idx and UI.filtered[idx] then ShowContextForRow(UI.frame, self, UI.filtered[idx]) end
        end
      end)

      UI.rows[i] = row
    end
  end

  for i, task in ipairs(UI.filtered) do
    local row = UI.rows[i]
    row.taskRef = task
    row.text:SetText(task.text or "")
    row.check:SetScript("OnClick", nil)
    row.check:SetChecked(task.completed and true or false)
    row.check:SetScript("OnClick", function(self)
      task.completed = not not self:GetChecked()
      UI.RefreshTaskList(); SyncProfileSnapshot()
    end)
    row:Show()
  end

  for i = #UI.filtered + 1, #UI.rows do UI.rows[i]:Hide() end
  if UI.lastClickedIndex and UI.lastClickedIndex > #UI.filtered then UI.lastClickedIndex = nil end
  for j = 1, #UI.rows do SetRowSelected(j, UI.lastClickedIndex == j) end

  local totalH = 0; for _ = 1, #UI.filtered do totalH = totalH + 28 end
  UI.listParent:SetHeight(math.max(1, totalH + 8))

  UpdateTitleCount(db)

  local zone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or ""
  if IsEmpty(zone) then zone = "—" end
  if UI.controls.zoneBtn then UI.controls.zoneBtn:SetText(("Zone: %s"):format(zone)) end

  if UI.radios then
    UI.radios.all:SetChecked(db.filterMode == "ALL")
    UI.radios.daily:SetChecked(db.filterMode == "DAILY")
    UI.radios.weekly:SetChecked(db.filterMode == "WEEKLY")
  end
end

----------------------------------------------------------------------
-- Minimap button
----------------------------------------------------------------------
local function UpdateMinimapVisibility(db) if UI.minimap then UI.minimap:SetShown(db.showMinimap ~= false) end end

local function CreateMinimapButton(db)
  if UI.minimap or not Minimap then return end
  local btn = CreateFrame("Button", "WinterChecklist_MinimapButton", Minimap)
  btn:SetSize(30, 30); btn:SetFrameStrata("LOW"); btn:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 4, -4)

  local icon = btn:CreateTexture(nil, "ARTWORK"); icon:SetAllPoints()
  icon:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
  local bg = btn:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(1,1,1,1)
  local mask = btn:CreateMaskTexture(nil, "OVERLAY"); mask:SetAllPoints()
  mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
  bg:AddMaskTexture(mask); icon:AddMaskTexture(mask)
  local border = btn:CreateTexture(nil, "OVERLAY"); border:SetAllPoints(); border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

  btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  btn:SetScript("OnClick", function()
    local d = EnsureDB()
    if UI.frame:IsShown() then UI.frame:Hide() else UI.frame:Show() end
    d.window = d.window or { w = 460, h = 500, x = 0, y = 0, shown = true }
    d.window.shown = UI.frame:IsShown()
  end)
  btn:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT"); GameTooltip:SetText("Checklist",1,1,1); GameTooltip:AddLine("Left-click to toggle window.", .8,.8,.8); GameTooltip:Show() end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
  UI.minimap = btn
  UpdateMinimapVisibility(db)
end

----------------------------------------------------------------------
-- Options Panel (help + profiles + extras)
----------------------------------------------------------------------
local function CreateOptionsPanel(db)
  local panel = CreateFrame("Frame"); panel.name = "Checklist"

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16); title:SetText("Checklist")

  -- Help text (scroll)
  local helpScroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
  helpScroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -48)
  helpScroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -36, 180)
  local body = CreateFrame("Frame", nil, helpScroll); helpScroll:SetScrollChild(body)
  body:SetSize(600, 1000)
  local helpText = body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  helpText:SetPoint("TOPLEFT"); helpText:SetWidth(560); helpText:SetJustifyH("LEFT")
  helpText:SetText(BuildHelpBodyText())

  -- Bottom area container (everything below the help scroll lives here)
  local bottomArea = CreateFrame("Frame", nil, panel)
  bottomArea:SetPoint("TOPLEFT", helpScroll, "BOTTOMLEFT", 0, -12)
  bottomArea:SetPoint("TOPRIGHT", helpScroll, "BOTTOMRIGHT", 0, -12)
  bottomArea:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 16)
  bottomArea:SetPoint("BOTTOMLEFT",  panel, "BOTTOMLEFT",  16, 16)

  -- Row 1: Minimap checkbox + Open button
  local cb = CreateFrame("CheckButton", nil, bottomArea, "InterfaceOptionsCheckButtonTemplate")
  cb:SetPoint("TOPLEFT", bottomArea, "TOPLEFT", 0, 0)
  cb.Text:SetText("Show minimap button")
  cb:SetChecked(db.showMinimap ~= false)
  cb:SetScript("OnClick", function(self)
    db.showMinimap = self:GetChecked()
    UpdateMinimapVisibility(db)
  end)

  local open = CreateFrame("Button", nil, bottomArea, "UIPanelButtonTemplate")
  open:SetSize(160, 22)
  open:ClearAllPoints()
  open:SetPoint("TOPRIGHT", bottomArea, "TOPRIGHT", 0, 0)
  open:SetPoint("TOP", cb, "TOP", 0, 0)

  -- Make the checkbox label stop before the button
  cb.Text:ClearAllPoints()
  cb.Text:SetPoint("LEFT",  cb,      "RIGHT", 4, 0)
  cb.Text:SetPoint("RIGHT", open,    "LEFT", -12, 0)
  cb.Text:SetWordWrap(false)  -- prevent wrapping into the button

  open:SetText("Toggle Checklist")
  open:SetScript("OnClick", function()
    local d = EnsureDB()
    if UI.frame:IsShown() then UI.frame:Hide() else UI.frame:Show() end
    d.window = d.window or { w = 460, h = 500, x = 0, y = 0, shown = true }
    d.window.shown = UI.frame:IsShown()
  end)

  -- Row 2: Profile management
  local profTitle = bottomArea:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  profTitle:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 0, -12)
  profTitle:SetText("Profile Management (per character):")

  local dropdown = CreateFrame("Frame", "WinterChecklistProfileDropdown", bottomArea, "UIDropDownMenuTemplate")
  UIDropDownMenu_SetWidth(dropdown, 220)   -- make the dropdown a predictable width
  dropdown:ClearAllPoints()
  dropdown:SetPoint("TOPLEFT", profTitle, "BOTTOMLEFT", -16, -6)

  local selectedKey = nil

  local function RefreshDropdown()
    local adb = EnsureAccountDB()
    local items, selfKey = {}, CurrentCharKey()
    for key, val in pairs(adb.profiles or {}) do
      if key ~= selfKey and val.tasks and #val.tasks > 0 then table.insert(items, key) end
    end
    table.sort(items)
    UIDropDownMenu_SetText(dropdown, selectedKey or "Select a character profile")
    UIDropDownMenu_Initialize(dropdown, function(self, level)
      for _, key in ipairs(items) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = key
        info.func = function() selectedKey = key; UIDropDownMenu_SetText(dropdown, key) end
        UIDropDownMenu_AddButton(info, level)
      end
    end)
  end

  local copyBtn = CreateFrame("Button", nil, bottomArea, "UIPanelButtonTemplate")
  copyBtn:SetSize(160, 22)
  copyBtn:ClearAllPoints()
  copyBtn:SetPoint("TOP",   dropdown,   "TOP",   0, 0)   -- y aligned to dropdown
  copyBtn:SetPoint("RIGHT", bottomArea, "RIGHT", 0, 0)   -- x pinned to right edge
  copyBtn:SetText("Copy From Selected")
  copyBtn:SetScript("OnClick", function()
    if not selectedKey then Print("Select a profile to copy from."); return end
    local adb = EnsureAccountDB()
    local src = adb.profiles[selectedKey]
    if not (src and src.tasks and #src.tasks > 0) then Print("Selected profile is empty."); return end
    local msg = ("Copying will replace ALL tasks on %s with tasks from %s. Are you sure?"):format(
      CurrentCharKey(), selectedKey
    )
    StaticPopup_Show("WCL_COPY_CONFIRM", nil, nil, { msg = msg, srcTasks = src.tasks })
  end)

  -- Row 3: Links
  local linksTitle = bottomArea:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  linksTitle:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 16, -16)
  linksTitle:SetText("Links")

  -- Keep your helper but parent to bottomArea and use LINK icon
  local function MakeLinkButton(parent, label, url, tooltip, relTo, xOffset)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(120, 22)
    b:SetPoint("TOPLEFT", relTo, "BOTTOMLEFT", xOffset or 0, -6)

    -- OLD:
    -- NS.ApplyIcon(b, "link", { textAfter = " " .. label })
    -- NEW (plain text):
    b:SetText(label)
    b:SetWidth(math.max(120, b:GetTextWidth() + 24))  -- keeps a nice padding

    b:SetScript("OnClick", function() ShowCopyLinkPopup(url) end)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
      GameTooltip:SetText(label, 1, 1, 1)
      GameTooltip:AddLine(tooltip, 0.9, 0.9, 0.9, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
  end

  local curseBtn = MakeLinkButton(
    bottomArea, "Curse",
    "www.curseforge.com/wow/addons/checklist",
    "Click to copy the CurseForge page URL.",
    linksTitle, 0
  )
  local gitBtn = MakeLinkButton(
    bottomArea, "GitHub",
    "github.com/ctgarry/dev/tree/main/WinterChecklist",
    "Click to copy the addon source URL.",
    linksTitle, 128
  )

  -- Row 4: Contributors (stacks below the link buttons)
  local belowLinks = gitBtn  -- whichever is lower/last; either is fine since both are same height
  local contrib = bottomArea:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  contrib:SetPoint("TOPLEFT", belowLinks, "BOTTOMLEFT", 0, -12)
  contrib:SetText("Active Contributors: |cffffffffbcgarry, wizardowl, beahbabe|r")

  -- Keep dropdown fresh when Options opens
  panel:SetScript("OnShow", RefreshDropdown)

  -- Finalize & register
  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, "Checklist")
    Settings.RegisterAddOnCategory(category)
  else
    InterfaceOptions_AddCategory(panel)
  end

  UI.options.panel = panel
end

----------------------------------------------------------------------
-- Zone update
----------------------------------------------------------------------
local function UpdateZoneText()
  local db = EnsureDB()
  local zone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or ""
  if IsEmpty(zone) then zone = "—" end
  if UI.controls.zoneBtn then UI.controls.zoneBtn:SetText(("Zone: %s"):format(zone)) end
end

----------------------------------------------------------------------
-- Slash commands (auto-refresh)
----------------------------------------------------------------------
SLASH_WINTERCHECKLIST1 = "/wcl"
SLASH_WINTERCHECKLIST2 = "/checklist"
SlashCmdList["WINTERCHECKLIST"] = function(msg)
  local db = EnsureDB()
  msg = STrim(msg or "")

  if msg == "" or msg == "toggle" then
    local d = EnsureDB()
    if UI.frame:IsShown() then UI.frame:Hide() else UI.frame:Show() end
    d.window = d.window or { w = 460, h = 500, x = 0, y = 0, shown = true }
    d.window.shown = UI.frame:IsShown()
  elseif msg:sub(1, 4) == "add " then
    local text = STrim(msg:sub(5))
    if IsEmpty(text) then Print("Cannot add a blank task.") else
      table.insert(db.tasks, { text = text, frequency = "daily",  completed = false })
      UI.RefreshTaskList(); SyncProfileSnapshot(); Print("Added daily task.")
    end
  elseif msg:sub(1, 5) == "addw " then
    local text = STrim(msg:sub(6))
    if IsEmpty(text) then Print("Cannot add a blank task.") else
      table.insert(db.tasks, { text = text, frequency = "weekly", completed = false })
      UI.RefreshTaskList(); SyncProfileSnapshot(); Print("Added weekly task.")
    end
  elseif msg == "minimap" then
    db.showMinimap = not (db.showMinimap == false)
    UpdateMinimapVisibility(db)
    Print("Minimap button "..(db.showMinimap and "shown" or "hidden")..".")
  elseif msg == "help" then
    ToggleHelp(UI.frame or UIParent)
  elseif msg == "reset" or msg == "reset all" then
    ResetTasks("all");    Print("All tasks reset to incomplete.")
  elseif msg == "reset daily" then
    ResetTasks("daily");  Print("All daily tasks reset to incomplete.")
  elseif msg == "reset weekly" then
    ResetTasks("weekly"); Print("All weekly tasks reset to incomplete.")
  elseif msg == "fixframe" or msg == "resetframe" then
    db.window = { w = 460, h = 500, x = 0, y = 0, shown = true }
    if UI.frame then
      UI.frame:ClearAllPoints()
      UI.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
      UI.frame:SetSize(460, 500)
      UI.frame:Show()
    end
    Print("Frame reset to default size & centered.")
  else
    Print("Commands: /wcl (toggle), /wcl add <text>, /wcl addw <text>, /wcl minimap, /wcl reset [daily|weekly|all], /wcl fixframe, /wcl help")
  end
end

----------------------------------------------------------------------
-- Events
----------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("ZONE_CHANGED")
ev:RegisterEvent("ZONE_CHANGED_INDOORS")
ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ev:RegisterEvent("PLAYER_LOGOUT") -- to snapshot profile
ev:SetScript("OnEvent", function(self, event)
  local db = EnsureDB()
  if event == "PLAYER_LOGIN" then
    CreateMainFrame(db)
    CreateMinimapButton(db)
    CreateOptionsPanel(db)

    -- Restore position/visibility
    UI.frame:ClearAllPoints()
    UI.frame:SetPoint("CENTER", UIParent, "CENTER", db.window.x or 0, db.window.y or 0)

    -- clamp size to screen (in case saved size is too big)
    local scrW, scrH = UIParent:GetWidth(), UIParent:GetHeight()
    local minW, minH = 360, 320
    local maxW, maxH = math.max(minW, scrW - PAD*2), math.max(minH, scrH - PAD*2)
    local w = math.min(math.max(db.window.w or 460, minW), maxW)
    local h = math.min(math.max(db.window.h or 500, minH), maxH)
    UI.frame:SetSize(w, h)

    if db.window.shown == false then UI.frame:Hide() else UI.frame:Show() end

    UI.RefreshTaskList()
    UpdateZoneText()
    SyncProfileSnapshot()

  elseif event == "PLAYER_ENTERING_WORLD"
      or event == "ZONE_CHANGED"
      or event == "ZONE_CHANGED_INDOORS"
      or event == "ZONE_CHANGED_NEW_AREA" then
    UpdateZoneText()

  elseif event == "PLAYER_LOGOUT" then
    SyncProfileSnapshot()
  end
end)