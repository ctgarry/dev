-- WinterChecklist.lua (v1.2.1)
-- Retail + Classic Era compatible
local ADDON = ...

-- =======================
-- Saved Variables (per character)
-- =======================
WinterChecklistDB = WinterChecklistDB or {}
local function now() return time() end

-- =======================
-- Compat helpers
-- =======================
local function safeCreateFrame(frameType, name, parent, template)
    local tpl = template
    if template == "BackdropTemplate" then
        tpl = _G.BackdropTemplateMixin and "BackdropTemplate" or nil
    end
    return CreateFrame(frameType, name, parent or UIParent, tpl)
end
local function hasBackdropAPI(frame)
    return type(frame.SetBackdrop) == "function" and type(frame.SetBackdropColor) == "function"
end
local function secondsUntilDailyReset()
    if type(GetQuestResetTime) == "function" then
        local s = GetQuestResetTime(); if s and s > 0 then return s end
    end
    if C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset then
        return C_DateAndTime.GetSecondsUntilDailyReset() or (20*60*60)
    end
    return 20*60*60
end
local function secondsUntilWeeklyReset()
    if C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset then
        local s = C_DateAndTime.GetSecondsUntilWeeklyReset(); if s and s > 0 then return s end
    end
    return 7*24*60*60
end
local function openWorldMap()
    if ToggleWorldMap then ToggleWorldMap()
    elseif WorldMapFrame then if WorldMapFrame:IsShown() then HideUIPanel(WorldMapFrame) else ShowUIPanel(WorldMapFrame) end end
end
local function currentZoneName()
    if C_Map and C_Map.GetBestMapForUnit and C_Map.GetMapInfo then
        local mapID = C_Map.GetBestMapForUnit("player"); if mapID then local i = C_Map.GetMapInfo(mapID); if i and i.name then return i.name end end
    end
    if GetRealZoneText then local z = GetRealZoneText(); if z and z ~= "" then return z end end
    if GetZoneText then return GetZoneText() end
    return "Unknown Zone"
end

-- =======================
-- DB & State
-- =======================
local function initDB()
    WinterChecklistDB.tasks = WinterChecklistDB.tasks or {} -- { {name="", kind="daily"/"weekly", done=false}, ... }
    WinterChecklistDB.nextDailyReset  = WinterChecklistDB.nextDailyReset or 0
    WinterChecklistDB.nextWeeklyReset = WinterChecklistDB.nextWeeklyReset or 0
    WinterChecklistDB.framePoint = WinterChecklistDB.framePoint or {"TOPLEFT", "UIParent", "TOPLEFT", 200, -200}
    WinterChecklistDB.minimap = WinterChecklistDB.minimap or { angle = 200 }
end
local function scheduleResets()
    local t = now()
    WinterChecklistDB.nextDailyReset  = t + secondsUntilDailyReset()
    WinterChecklistDB.nextWeeklyReset = t + secondsUntilWeeklyReset()
end
local function doResetsIfNeeded()
    local t = now()
    if t >= (WinterChecklistDB.nextDailyReset or 0) then
        for _, task in ipairs(WinterChecklistDB.tasks) do if task.kind == "daily" then task.done = false end end
        WinterChecklistDB.nextDailyReset = t + secondsUntilDailyReset()
    end
    if t >= (WinterChecklistDB.nextWeeklyReset or 0) then
        for _, task in ipairs(WinterChecklistDB.tasks) do if task.kind == "weekly" then task.done = false end end
        WinterChecklistDB.nextWeeklyReset = t + secondsUntilWeeklyReset()
    end
end

-- =======================
-- Main UI
-- =======================
local f = safeCreateFrame("Frame", "WinterChecklistFrame", UIParent, "BackdropTemplate")
f:SetSize(320, 300)
do
    local p = WinterChecklistDB.framePoint or {"TOPLEFT", "UIParent", "TOPLEFT", 200, -200}
    local rel = _G[p[2]] or UIParent
    f:SetPoint(p[1], rel, p[3], p[4], p[5])
end
f:SetMovable(true); f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, rel, relPoint, x, y = self:GetPoint(1)
    WinterChecklistDB.framePoint = {point, rel and rel:GetName() or "UIParent", relPoint, x, y}
end)
-- Resizable (Classic-safe)
f:SetResizable(true)
local MIN_W, MIN_H = 280, 240
local sizer = CreateFrame("Frame", nil, f); sizer:SetSize(16,16); sizer:SetPoint("BOTTOMRIGHT", -2, 2)
sizer:EnableMouse(true)
sizer:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
sizer:SetScript("OnMouseUp",   function() f:StopMovingOrSizing()  end)
local sizerTex = sizer:CreateTexture(nil, "OVERLAY"); sizerTex:SetAllPoints(); sizerTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
if hasBackdropAPI(f) then
    f:SetBackdrop({ bgFile="Interface/Tooltips/UI-Tooltip-Background", edgeFile="Interface/Tooltips/UI-Tooltip-Border", edgeSize=12, insets={left=3,right=3,top=3,bottom=3}})
    f:SetBackdropColor(0,0,0,0.6)
end

-- Title + Help
local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 10, -10); title:SetText("Checklist")
local helpBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
helpBtn:SetSize(22,22); helpBtn:SetPoint("TOPRIGHT", -8, -8); helpBtn:SetText("?")

-- Compact toolbar (vertical +/E/D buttons)
local toolbar = CreateFrame("Frame", nil, f); toolbar:SetSize(24, 72); toolbar:SetPoint("TOPRIGHT", -8, -36)
local function smallBtn(label, yoff, tip)
    local b = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
    b:SetSize(24, 22); b:SetPoint("TOP", 0, yoff); b:SetText(label)
    b:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText(tip, 1,1,1); GameTooltip:Show() end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end
local addBtn = smallBtn("+", 0, "Add task")
local editBtn= smallBtn("E", -24, "Edit selected")
local delBtn = smallBtn("D", -48, "Delete selected")

-- Name box (stretches to toolbar)
local nameBox = CreateFrame("EditBox", "WinterChecklistNameBox", f, "InputBoxTemplate")
nameBox:SetAutoFocus(false); nameBox:SetHeight(22)
nameBox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
nameBox:SetPoint("RIGHT", toolbar, "LEFT", -6, 0)
nameBox:SetMaxLetters(60)
nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
nameBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

-- Daily/Weekly radios (small, below name)
local dailyRB = CreateFrame("CheckButton", "WinterChecklistDailyRB", f, "UIRadioButtonTemplate")
dailyRB:SetPoint("TOPLEFT", nameBox, "BOTTOMLEFT", 0, -4); _G[dailyRB:GetName().."Text"]:SetText("Daily")
local weeklyRB = CreateFrame("CheckButton", "WinterChecklistWeeklyRB", f, "UIRadioButtonTemplate")
weeklyRB:SetPoint("LEFT", dailyRB, "RIGHT", 48, 0); _G[weeklyRB:GetName().."Text"]:SetText("Weekly")
local selectedKind = "daily"; dailyRB:SetChecked(true); weeklyRB:SetChecked(false)
local function setKind(k) selectedKind = k; dailyRB:SetChecked(k=="daily"); weeklyRB:SetChecked(k=="weekly") end
dailyRB:SetScript("OnClick", function() setKind("daily") end)
weeklyRB:SetScript("OnClick", function() setKind("weekly") end)

-- Zone label (bottom-left, clickable)
local zoneBtn = CreateFrame("Button", nil, f)
zoneBtn:SetPoint("BOTTOMLEFT", 8, 8); zoneBtn:SetSize(200, 16); zoneBtn:EnableMouse(true)
local zoneFS = zoneBtn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
zoneFS:SetAllPoints(); zoneFS:SetJustifyH("LEFT"); zoneFS:SetText(currentZoneName())
zoneBtn:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText("Click to open world map", 1,1,1); GameTooltip:Show() end)
zoneBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
zoneBtn:SetScript("OnMouseUp", openWorldMap)

-- Scroll area (tasks)
local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", dailyRB, "BOTTOMLEFT", 0, -6)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 30)
local content = CreateFrame("Frame", nil, scrollFrame); content:SetSize(1,1); scrollFrame:SetScrollChild(content)

-- Clamp size + keep layout tidy
f:SetScript("OnSizeChanged", function(self, w, h)
    if w and h then
        local nw = (w < MIN_W) and MIN_W or w
        local nh = (h < MIN_H) and MIN_H or h
        if nw ~= w or nh ~= h then self:SetSize(nw, nh); return end
    end
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 30)
end)

-- =======================
-- Task rows: checkbox + label
-- =======================
local rows, selectedIndex = {}, nil
local function wipeRows() for _, r in ipairs(rows) do r:Hide() end wipe(rows) end
local function rowSetTextColor(fs, done)
    if not fs then return end
    if done then fs:SetTextColor(0.6,0.6,0.6) else fs:SetTextColor(1,0.82,0) end
end
local function addRow(idx, task)
    local name = "WinterChecklistRow"..idx
    local row = CreateFrame("CheckButton", name, content, "UICheckButtonTemplate")
    row:SetPoint("TOPLEFT", 0, - (idx-1)*22)
    row:SetSize(20,20)
    row:SetChecked(task.done)
    row:RegisterForClicks("AnyUp")
    row:SetScript("OnClick", function(_, btn)
        if btn == "LeftButton" then task.done = not task.done; row:SetChecked(task.done) end
        selectedIndex = idx
        _G["WinterChecklist_Refresh"]()
        -- prefill editor
        local t = WinterChecklistDB.tasks[selectedIndex]; if t then nameBox:SetText(t.name or ""); setKind(t.kind or "daily") end
    end)
    local label = _G[name.."Text"]
    if not label then
        -- fallback label
        local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("LEFT", row, "RIGHT", 6, 0); fs:SetText(task.name .. " ("..task.kind..")")
    else
        label:ClearAllPoints(); label:SetPoint("LEFT", row, "RIGHT", 6, 0)
        label:SetText(task.name .. " ("..task.kind..")")
        rowSetTextColor(label, task.done)
    end
    table.insert(rows, row)
end

_G["WinterChecklist_Refresh"] = function()
    doResetsIfNeeded()
    wipeRows()
    local y = 0
    for i, task in ipairs(WinterChecklistDB.tasks) do addRow(i, task); y = y + 22 end
    content:SetSize(260, y)
    -- highlight selected (yellow arrow prefix via text color tweak)
    for i, row in ipairs(rows) do
        local label = _G[row:GetName().."Text"]
        if label then
            rowSetTextColor(label, WinterChecklistDB.tasks[i] and WinterChecklistDB.tasks[i].done)
            if selectedIndex == i then label:SetText(("> %s (%s)"):format(WinterChecklistDB.tasks[i].name, WinterChecklistDB.tasks[i].kind))
            else label:SetText(("%s (%s)"):format(WinterChecklistDB.tasks[i].name, WinterChecklistDB.tasks[i].kind)) end
        end
    end
end

-- =======================
-- Task ops + wire buttons
-- =======================
local function addTask(kind, name)
    kind = (kind or ""):lower()
    name = (name or ""):gsub("^%s+",""):gsub("%s+$","")
    if (kind~="daily" and kind~="weekly") or name == "" then print("|cffff5555WinterChecklist:|r choose Daily/Weekly and enter a name."); return end
    table.insert(WinterChecklistDB.tasks, {name=name, kind=kind, done=false})
    selectedIndex = #WinterChecklistDB.tasks
    _G["WinterChecklist_Refresh"]()
end
local function editTask(idx, kind, name)
    local t = idx and WinterChecklistDB.tasks[idx]; if not t then print("|cffff5555WinterChecklist:|r select a task first."); return end
    name = (name or ""):gsub("^%s+",""):gsub("%s+$",""); if name=="" then print("|cffff5555WinterChecklist:|r task needs a name."); return end
    if kind ~= "daily" and kind ~= "weekly" then kind = t.kind end
    t.name, t.kind = name, kind; _G["WinterChecklist_Refresh"]()
end
local function deleteTask(idx)
    if not idx or not WinterChecklistDB.tasks[idx] then print("|cffff5555WinterChecklist:|r select a task to delete."); return end
    table.remove(WinterChecklistDB.tasks, idx); selectedIndex = nil; _G["WinterChecklist_Refresh"]()
end
addBtn:SetScript("OnClick", function() addTask(selectedKind, nameBox:GetText()) end)
editBtn:SetScript("OnClick", function() editTask(selectedIndex, selectedKind, nameBox:GetText()) end)
delBtn:SetScript("OnClick", function() deleteTask(selectedIndex) end)

-- =======================
-- Help panel (UI-first)
-- =======================
local help = safeCreateFrame("Frame", nil, f, "BackdropTemplate")
help:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -32)
help:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 28)
help:Hide()
if hasBackdropAPI(help) then
    help:SetBackdrop({ bgFile="Interface/Tooltips/UI-Tooltip-Background", edgeFile="Interface/Tooltips/UI-Tooltip-Border", edgeSize=10, insets={left=3,right=3,top=3,bottom=3}})
    help:SetBackdropColor(0,0,0,0.7)
end
local helpScroll = CreateFrame("ScrollFrame", nil, help, "UIPanelScrollFrameTemplate")
helpScroll:SetPoint("TOPLEFT", 8, -8); helpScroll:SetPoint("BOTTOMRIGHT", -28, 8)
local helpContent = CreateFrame("Frame", nil, helpScroll); helpContent:SetSize(1,1); helpScroll:SetScrollChild(helpContent)
local helpText = helpContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
helpText:SetPoint("TOPLEFT", 0, 0); helpText:SetJustifyH("LEFT"); helpText:SetWidth( 560 )
helpText:SetText(table.concat({
    "|cff00ff00Checklist — quick UI guide|r",
    "• Type a name, choose Daily/Weekly, click +.",
    "• Click the checkbox beside a task to mark done/undone (clicking also selects it).",
    "• With a task selected: change name/kind, click E to edit.",
    "• With a task selected: click D to delete.",
    "• Drag the window; resize from the bottom-right.",
    "• Click the zone name (bottom-left) to open the world map.",
    "• Use the minimap button to toggle this window.",
    "",
    "|cff00ff00Slash commands (optional)|r",
    "/wcl show, /wcl hide, /wcl add daily <name>, /wcl add weekly <name>, /wcl done <name>, /wcl remove <name>",
}, "\n"))
helpBtn:SetScript("OnClick", function() help:SetShown(not help:IsShown()) end)

-- =======================
-- Slash (kept)
-- =======================
local function markDoneByName(name)
    if not name or name == "" then return end
    for i, t in ipairs(WinterChecklistDB.tasks) do if t.name:lower()==name:lower() then t.done=true; selectedIndex=i; break end end
    _G["WinterChecklist_Refresh"]()
end
local function removeByName(name)
    if not name or name == "" then return end
    for i=#WinterChecklistDB.tasks,1,-1 do if WinterChecklistDB.tasks[i].name:lower()==name:lower() then table.remove(WinterChecklistDB.tasks,i); selectedIndex=nil; break end end
    _G["WinterChecklist_Refresh"]()
end
SLASH_WINTERCHECKLIST1 = "/wcl"
SlashCmdList["WINTERCHECKLIST"] = function(msg)
    local cmd, a, b = msg:match("^(%S*)%s*(%S*)%s*(.*)$"); cmd = (cmd or ""):lower()
    if cmd == "" or cmd == "help" then
        print("|cff55ff55WinterChecklist|r commands: /wcl show, /wcl hide, /wcl add daily <name>, /wcl add weekly <name>, /wcl done <name>, /wcl remove <name>"); return
    end
    if cmd == "show" then f:Show(); return end
    if cmd == "hide" then f:Hide(); return end
    if cmd == "add" and a ~= "" and b ~= "" then addTask(a, b); return end
    if cmd == "done" and a ~= "" then markDoneByName((a.." "..(b or "")):gsub("%s+$","")); return end
    if cmd == "remove" and a ~= "" then removeByName((a.." "..(b or "")):gsub("%s+$","")); return end
    print("|cffff5555WinterChecklist:|r unknown command. Try /wcl help")
end

-- =======================
-- Minimap button (unchanged)
-- =======================
local mm = CreateFrame("Button", "WinterChecklistMinimapButton", Minimap)
mm:SetSize(32, 32); mm:SetFrameStrata("MEDIUM"); mm:SetMovable(true); mm:RegisterForDrag("LeftButton")
mm:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local icon = mm:CreateTexture(nil, "ARTWORK"); icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01"); icon:SetAllPoints()
local function updateMinimapPos()
    local angle = (WinterChecklistDB.minimap and WinterChecklistDB.minimap.angle) or 200
    local r = (Minimap:GetWidth()/2) + 5; local rad = math.rad(angle)
    mm:ClearAllPoints(); mm:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad)*r, math.sin(rad)*r)
end
mm:SetScript("OnDragStart", function(self) self:StartMoving() end)
mm:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local mx,my = Minimap:GetCenter(); local bx,by = mm:GetCenter()
    local angle = math.deg(math.atan2(by-my, bx-mx)); if angle < 0 then angle = angle + 360 end
    WinterChecklistDB.minimap.angle = angle; updateMinimapPos()
end)
mm:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:AddLine("Checklist",1,1,1)
    GameTooltip:AddLine("Left-click: toggle window",0,1,0); GameTooltip:AddLine("Drag: move around minimap",0,1,0); GameTooltip:Show()
end)
mm:SetScript("OnLeave", function() GameTooltip:Hide() end)
mm:SetScript("OnClick", function(_, btn)
    if btn == "LeftButton" then if f:IsShown() then f:Hide() else f:Show() end
    elseif btn == "RightButton" then
        if Settings and Settings.OpenToCategory then Settings.OpenToCategory("WinterChecklist")
        elseif InterfaceOptionsFrame_OpenToCategory then InterfaceOptionsFrame_OpenToCategory("WinterChecklist"); InterfaceOptionsFrame_OpenToCategory("WinterChecklist") end
    end
end)

-- =======================
-- Options panel (AddOns list)
-- =======================
local optionsPanel = CreateFrame("Frame"); optionsPanel.name = "WinterChecklist"
local desc = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
desc:SetPoint("TOPLEFT", 16, -16); desc:SetWidth(600); desc:SetJustifyH("LEFT")
desc:SetText("WinterChecklist — daily/weekly checklist.\nCompact UI with +/E/D and checkboxes.")
local function registerOptionsPanel()
    if Settings and Settings.RegisterAddOnCategory then
        local cat = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name); cat.ID = optionsPanel.name; Settings.RegisterAddOnCategory(cat)
    elseif InterfaceOptions_AddCategory then InterfaceOptions_AddCategory(optionsPanel) end
end

-- =======================
-- Events
-- =======================
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN"); ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("ZONE_CHANGED"); ev:RegisterEvent("ZONE_CHANGED_INDOORS"); ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        initDB(); if (WinterChecklistDB.nextDailyReset or 0)==0 or (WinterChecklistDB.nextWeeklyReset or 0)==0 then scheduleResets() end
        _G["WinterChecklist_Refresh"](); registerOptionsPanel(); updateMinimapPos()
    end
    if event == "PLAYER_ENTERING_WORLD" or event:match("^ZONE_CHANGED") then zoneFS:SetText(currentZoneName()) end
end)
