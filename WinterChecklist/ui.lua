local ADDON, NS = ...

local PAD, BOTTOM_BAR_H = 12, 72

UI:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                 edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 12 })
UI:SetBackdropColor(0,0,0,0.85)

-- Title
local title = UI:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOPLEFT", 12, -12)
title:SetText("WinterChecklist")

-- Task list (simple)
local scroll = CreateFrame("ScrollFrame", nil, UI, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 12, -40)
scroll:SetPoint("BOTTOMRIGHT", -12, 80)

local content = CreateFrame("Frame", nil, scroll)
content:SetSize(1,1)
scroll:SetScrollChild(content)

-- Example row builder
local rows = {}
local function buildRows(tasks)
  -- clear old
  for _, r in ipairs(rows) do r:Hide() end
  wipe(rows)

  local y = -4
  for i, t in ipairs(tasks) do
    local r = CreateFrame("Button", nil, content, "BackdropTemplate")
    r:SetSize(420, 24)
    r:SetPoint("TOPLEFT", 0, y)
    r:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8x8" })
    r:SetBackdropColor(0,0,0,0.2)

    local cb = CreateFrame("CheckButton", nil, r, "ChatConfigCheckButtonTemplate")
    cb:SetPoint("LEFT", 4, 0)
    cb:SetScript("OnClick", function(self)
      t.done = self:GetChecked() and true or false
    end)

    local fs = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    fs:SetText(t.text or "")

    r:SetScript("OnClick", function()
      NS.SelectTask(i)
    end)

    rows[#rows+1] = r
    y = y - 26
  end
  content:SetSize(420, math.max(1, -y))
end

-- Bottom buttons
local editBtn = CreateFrame("Button", nil, UI, "UIPanelButtonTemplate")
editBtn:SetSize(80, 22) editBtn:SetPoint("BOTTOMLEFT", 12, 12) editBtn:SetText("Edit")
editBtn:SetScript("OnClick", function()
  local i = NS.GetSelection()
  if i then
    StaticPopupDialogs["WC_EDIT"] = {
      text = "Edit task", button1 = "OK", button2 = "Cancel", hasEditBox = true,
      OnAccept = function(self) NS.EditSelected(self.editBox:GetText()) end,
      EditBoxOnEnterPressed = function(self) NS.EditSelected(self:GetText()); self:GetParent():Hide() end,
      timeout = 0, whileDead = true, hideOnEscape = true,
    }
    StaticPopup_Show("WC_EDIT")
  end
end)

local delBtn = CreateFrame("Button", nil, UI, "UIPanelButtonTemplate")
delBtn:SetSize(80, 22) delBtn:SetPoint("LEFT", editBtn, "RIGHT", 8, 0) delBtn:SetText("Delete")
delBtn:SetScript("OnClick", NS.DeleteSelected)

local impBtn = CreateFrame("Button", nil, UI, "UIPanelButtonTemplate")
impBtn:SetSize(100, 22) impBtn:SetPoint("LEFT", delBtn, "RIGHT", 8, 0) impBtn:SetText("Import/Export")
impBtn:SetScript("OnClick", function()
  if not IsAddOnLoaded("WinterChecklist_ImportExport") then
    LoadAddOn("WinterChecklist_ImportExport")
  end
  if NS.ShowImportExport then NS.ShowImportExport(UI) end
end)

-- Slash + ready
SLASH_WINTERCHECKLIST1 = "/winter"
SlashCmdList["WINTERCHECKLIST"] = function() UI:SetShown(not UI:IsShown()) end

function NS.RefreshUI()
  local db = NS.EnsureDB()
  local list = NS.FilterTasks(NS.GetTasks(), db.search or "", db.filterMode)
  if buildRows then buildRows(list) end
  if UpdateTitleCount then UpdateTitleCount(db, list) end
end

local function UpdateTitleCount(db, viwsibleTasks)
  if not WinterChecklistMain or not WinterChecklistMain.TitleText then return end
  local vis = #visibleTasks
  local done = 0
  for _, t in ipairs(visibleTasks) do if t.completed then done = done + 1 end end
  WinterChecklistMain.TitleText:SetText(("WinterChecklist  (%d/%d)"):format(done, vis))
end

NS.OnReady = function()
  if not NS.GetTasks()[1] then
    NS.SaveTasks({ {text="Sample task", done=false} })
  end
  NS.RefreshUI()
end

----------------------------------------------------------------------
-- Copy-to-clipboard popup (Blizzard StaticPopup)
----------------------------------------------------------------------
StaticPopupDialogs["WCL_COPY_LINK"] = {
  text = "Ctrl+A, Ctrl+C to Copy to your Clipboard.",
  button1 = OKAY,
  hasEditBox = true,
  showAlert = true,            -- yellow '!' icon
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
    local db2 = NS.EnsureDB()
    db2.tasks = DeepCopyTasks(data.srcTasks)
    NS.RefreshUI()
    NS.SyncProfileSnapshot()
  end,
  timeout = 20, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

local function ShowCopyLinkPopup(url)
  StaticPopup_Show("WCL_COPY_LINK", nil, nil, url)
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
    local d = NS.EnsureDB()
    d.window = d.window or { w = 460, h = 500, x = 0, y = 0, shown = UI.frame and UI.frame:IsShown() or true }
    d.window.x, d.window.y = x - px, y - py
  end)
  f:SetScript("OnSizeChanged", function(self, w, h)
    local d = NS.EnsureDB()
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
    NS.RefreshUI()
  end)

  -- Add/Edit/Delete with guard
  bAdd:SetScript("OnClick", function()
    local defaultFreq = (db.filterMode == "WEEKLY") and "weekly" or ((db.filterMode == "DAILY") and "daily" or "daily")
    SimplePrompt(f, "Add Task", "", function(text)
      table.insert(db.tasks, { text = text, frequency = defaultFreq, completed = false })
      NS.RefreshUI(); NS.SyncProfileSnapshot()
    end)
  end)

  bEdit:SetScript("OnClick", function()
    local idx = UI.lastClickedIndex
    if not idx or not UI.filtered or not UI.filtered[idx] then NS.Print("Click a task first, then press E to edit."); return end
    local task = UI.filtered[idx]
    SimplePrompt(f, "Edit Task", task.text or "", function(text)
      task.text = text
      NS.RefreshUI(); NS.SyncProfileSnapshot()
    end)
  end)

  bDel:SetScript("OnClick", function()
    local idx = UI.lastClickedIndex
    if not idx or not UI.filtered or not UI.filtered[idx] then NS.Print("Click a task first, then press - to delete."); return end
    local toDelete = UI.filtered[idx]
    for i,t in ipairs(db.tasks) do if t == toDelete then table.remove(db.tasks, i); break end end
    UI.lastClickedIndex = nil
    NS.RefreshUI(); NS.SyncProfileSnapshot()
  end)

  bHelp:SetScript("OnClick", function() ToggleHelp(f) end)
  bGear:SetScript("OnClick", function() NS.ShowImportExport(f) end)

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

  -- Filter (row above radios)
  local filterLabel = bottom:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  filterLabel:SetPoint("BOTTOMLEFT", bottom, "BOTTOMLEFT", 0, 44)
  filterLabel:SetText("Filter:")

  local search = CreateFrame("EditBox", nil, bottom, "InputBoxTemplate")
  search:SetAutoFocus(false)
  search:SetHeight(22)
  search:SetPoint("LEFT", filterLabel, "RIGHT", 6, 0)
  search:SetPoint("RIGHT", bottom, "RIGHT", 0, 44)
  search:SetText("")                  -- always blank at startup
  UI.controls.search = search
  UI.searchTerm = ""

  search:SetScript("OnTextChanged", function(self)
    UI.searchTerm = self:GetText() or ""
    NS.RefreshUI()
  end)

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
      db.filterMode = mode; NS.RefreshUI()
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
  refreshBtn:SetScript("OnClick", function() NS.RefreshUI() end)
  UI.controls.refresh = refreshBtn

  -- Initialize radios
  radios.all:SetChecked(db.filterMode == "ALL")
  radios.daily:SetChecked(db.filterMode == "DAILY")
  radios.weekly:SetChecked(db.filterMode == "WEEKLY")
end

NS.OnReady = function() CreateMainFrame(NS.EnsureDB()) end

----------------------------------------------------------------------
-- Zone update
----------------------------------------------------------------------
function NS.UpdateZoneText()
  local db = NS.EnsureDB()
  local zone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or ""
  if NS.IsEmpty(zone) then zone = "—" end
  if UI.controls.zoneBtn then UI.controls.zoneBtn:SetText(("Zone: %s"):format(zone)) end
end

----------------------------------------------------------------------
-- Minimap button
----------------------------------------------------------------------
function NS.UpdateMinimapVisibility(db) 
  if UI.minimap 
  then UI.minimap:SetShown(db.showMinimap ~= false) 
  end 
end

function NS.CreateMinimapButton(db)
  if UI.minimap or not Minimap 
  then return 
  end

  -- 31x31 is the “classic” minimap button footprint
  local btn = CreateFrame("Button", "WinterChecklist_MinimapButton", Minimap)
  btn:SetSize(31, 31)
  btn:SetFrameStrata("MEDIUM")
  btn:SetFrameLevel(8)
  btn:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 4, -4)

  -- Big golden ring (oversized so it reads as a circle)
  local ring = btn:CreateTexture(nil, "OVERLAY")
  ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  ring:SetSize(54, 54)
  ring:SetPoint("TOPLEFT", 0, 0)

  -- Dark circular background disk
  local back = btn:CreateTexture(nil, "BACKGROUND")
  back:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  back:SetSize(20, 20)
  back:SetPoint("TOPLEFT", 7, -5)

  -- The actual icon
  local icon = btn:CreateTexture(nil, "ARTWORK")
  icon:SetTexture("Interface\\Buttons\\UI-CheckBox-Check") -- use your own texture here if you add one
  icon:SetSize(17, 17)
  icon:SetPoint("TOPLEFT", 7, -6)
  icon:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- crop corners so it sits nicely in the circle
  UI.minimapIcon = icon

  -- Standard highlight ring
  btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

  btn:SetScript("OnClick", function()
    local d = NS.EnsureDB()
    if UI.frame:IsShown() then UI.frame:Hide() else UI.frame:Show() end
    d.window = d.window or { w = 460, h = 500, x = 0, y = 0, shown = true }
    d.window.shown = UI.frame:IsShown()
  end)

  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
    GameTooltip:SetText("Checklist", 1, 1, 1)
    GameTooltip:AddLine("Left-click to toggle window.", .8, .8, .8)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

  UI.minimap = btn
  NS.UpdateMinimapVisibility(db)
end

---------------------------------------------------------------------
-- Options Panel (help + profiles + extras)
----------------------------------------------------------------------
function NS.CreateOptionsPanel(db)
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
    NS.UpdateMinimapVisibility(db)
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
    local d = NS.EnsureDB()
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
    local adb = NS.EnsureAccountDB()
    local items, selfKey = {}, CurrentCharKey()
    for key, val in pairs(adb.profiles or {}) do
      if key ~= selfKey and val.tasks and #val.tasks > 0 
      then table.insert(items, key) 
      end
    end

    table.sort(items)

    UIDropDownMenu_SetText(dropdown, selectedKey or "Select a character profile")

    UIDropDownMenu_Initialize(dropdown, function(self, level)
      for _, key in ipairs(items) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = key
        info.func = function() 
          selectedKey = key; 
          UIDropDownMenu_SetText(dropdown, key) 
        end
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
    if not selectedKey 
    then 
      NS.Print("Select a profile to copy from."); 
      return 
    end
    local adb = NS.EnsureAccountDB()
    local src = adb.profiles[selectedKey]
    if not (src and src.tasks and #src.tasks > 0) 
    then 
      NS.Print("Selected profile is empty."); 
      return 
    end
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
    local t = NS.STrim(eb:GetText() or "")
    if NS.IsEmpty(t) then NS.Print("Please enter text."); return end
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
    ("• Minimap button %s toggles this window (can be hidden)."):format(arrow),
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

local function ParseTasksStrict(s)
  local list = {}
  local ln = 0
  for line in (s.."\n"):gmatch("([^\n]*)\n") do
    ln = ln + 1
    local L = NS.STrim(line)
    if not NS.IsEmpty(L) then
      local tag, rest = L:match("^([dDwW])%s*:%s*(.+)$")
      if not tag then return nil, ln end
      local freq = (tag == "w" or tag == "W") and "weekly" or "daily"
      table.insert(list, { text = rest, frequency = freq, completed = false })
    end
  end
  return list, nil
end

-- Reuse the anchor spot (near the frame's X button)
local function AnchorPopupNearClose(popup, parent)
  local f = parent or UI.frame
  popup:ClearAllPoints()
  local closeBtn = f and _G[((f:GetName() or "") .. "CloseButton")]
  if closeBtn then
    popup:SetPoint("TOPLEFT", closeBtn, "BOTTOMRIGHT", 8, -6)
  else
    popup:SetPoint("TOPRIGHT", f or UIParent, "TOPRIGHT", 8, 0)
  end
end

local function ToggleHelp(parent)
  if UI.help and UI.help:IsShown() then UI.help:Hide(); return end
  HideAllPopups()

  local h = CreateFrame("Frame", nil, parent, "BasicFrameTemplateWithInset")
  h:SetSize(380, 420)
  AnchorPopupNearClose(h, parent)

  h:SetFrameStrata("DIALOG")
  h:SetToplevel(true)
  h:SetResizable(false)
  C_Timer.After(0, function()
    if h and h:IsShown() then AnchorPopupNearClose(h, parent) end
  end)

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
    local L = NS.STrim(line)
    if not NS.IsEmpty(L) then
      local freq, txt = "daily", L
      local tag, rest = L:match("^([dDwW])%s*:%s*(.*)$")
      if tag and rest 
      then freq = (tag == "w" or tag == "W") and "weekly" or "daily"; txt = rest 
      end
      table.insert(list, { text = txt, frequency = freq, completed = false })
    end
  end
  return list
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

  addBtn("Make Daily",  -12, function() task.frequency = "daily"; NS.RefreshUI(); NS.SyncProfileSnapshot() end)
  addBtn("Make Weekly", -36, function() task.frequency = "weekly"; NS.RefreshUI(); NS.SyncProfileSnapshot() end)
  addBtn("Delete",      -60, function()
    local db = NS.EnsureDB()
    for i,t in ipairs(db.tasks) do if t == task then table.remove(db.tasks, i); break end end
    UI.lastClickedIndex = nil
    NS.RefreshUI()
    NS.SyncProfileSnapshot()
  end)

  UI.context = f
  f:Show()
end

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
    local d = NS.EnsureDB()
    d.window = d.window or { w = 460, h = 500, x = 0, y = 0, shown = UI.frame and UI.frame:IsShown() or true }
    d.window.w, d.window.h = p:GetSize()
  end)
end

local function SafeSetResizeBounds(frame, minW, minH, maxW, maxH)
  if frame.SetResizeBounds then frame:SetResizeBounds(minW, minH, maxW, maxH)
  elseif frame.SetMinResize then frame:SetMinResize(minW, minH) end
end
