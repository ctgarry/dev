--[[
  @file    lua/options.lua
  @brief   Interface Options panel (Retail + Classic) incl. profile task copy and feedback (sound).
           Adds an "About" subcategory conservatively; guards against double registration.
]]
local ADDON, NS = ...
local L, U = NS.L, NS.Util

local Opt = {}
NS.Options = Opt

function Opt:Open()
  if Settings and Settings.OpenToCategory and self.panel and self.panel.categoryID then
    Settings.OpenToCategory(self.panel.categoryID)
  else
    if InterfaceOptionsFrame_OpenToCategory and self.panel then
      InterfaceOptionsFrame_OpenToCategory(self.panel)
      InterfaceOptionsFrame_OpenToCategory(self.panel) -- Blizzard bug
    end
  end
end

local function CheckBox(parent, label, anchor, onGet, onSet)
  local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
  if anchor then cb:SetPoint(unpack(anchor)) else cb:SetPoint("TOPLEFT", 16, -16) end
  cb.Text:SetText(label)
  cb:SetScript("OnClick", function(self) onSet(self:GetChecked()) end)
  cb:SetScript("OnShow", function(self)
    self:SetChecked(onGet())
    local w = self.Text and (self.Text:GetStringWidth() + 24) or 140
    self:SetHitRectInsets(0, -w, 0, 0)
  end)
  return cb
end

local function addAboutSubcategory(parentPanel)
  if parentPanel._wclAboutPanel then return end  -- guard: only create once

  local p = CreateFrame("Frame")
  p.name   = L.OPT_ABOUT_TITLE
  p.parent = parentPanel.name
  parentPanel._wclAboutPanel = p

  -- Static text only (no scroll frames)
  local title = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)

  local addonName = (GetAddOnMetadata and GetAddOnMetadata(ADDON, "Title")) or ADDON or "WinterChecklist"
  local version   = (GetAddOnMetadata and GetAddOnMetadata(ADDON, "Version")) or ""
  if version ~= "" then
    title:SetText(string.format("%s  |cffffd100%s|r", addonName, version))
  else
    title:SetText(addonName)
  end

  local text = p:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
  text:SetWidth(680)
  text:SetJustifyH("LEFT")
  local chunks = { L.OPT_ABOUT_INFO, "", L.OPT_ABOUT_USAGE, "", L.OPT_ABOUT_SLASH, "", L.OPT_ABOUT_CREDITS }
  text:SetText(table.concat(chunks, "\n"))

  -- Register subcategory (Retail path)
  if Settings and Settings.RegisterCanvasLayoutSubcategory and parentPanel.categoryID then
    local parentCat = Settings.GetCategory and Settings.GetCategory(parentPanel.categoryID)
    if parentCat then
      local sub = Settings.RegisterCanvasLayoutSubcategory(parentCat, p, p.name)
      Settings.RegisterAddOnCategory(sub)
      return
    end
  end

  -- Classic / fallback: legacy API
  if InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(p)
  end
end

local function ensurePanel()
  if Opt.panel then return end
  local p = CreateFrame("Frame")
  p.name = L.OPT_PANEL_TITLE

  if Settings and Settings.RegisterCanvasLayoutCategory then
    local cat = Settings.RegisterCanvasLayoutCategory(p, p.name)
    Opt.panel = p; p.categoryID = cat:GetID()
    Settings.RegisterAddOnCategory(cat)
  else
    Opt.panel = p
    if InterfaceOptions_AddCategory then InterfaceOptions_AddCategory(p) end
  end

  -- Minimap icon
  local cbMinimap = CheckBox(p, L.OPT_MINIMAP, {"TOPLEFT", 16, -16},
    function() return not (WinterChecklistDB.minimap and WinterChecklistDB.minimap.hide) end,
    function(val) WinterChecklistDB.minimap.hide = not val; NS.ApplyMinimapVisibility() end
  )
  p._wclMinimap = cbMinimap

  -- Account-wide tasks
  local cbAccount = CheckBox(p, L.OPT_ACCOUNT_WIDE, {"TOPLEFT", cbMinimap, "BOTTOMLEFT", 0, -8},
    function() return not not (WinterChecklistDB and WinterChecklistDB.accountWide) end,
    function(val)
      WinterChecklistDB.accountWide = val and true or false
      if NS.UIList and NS.UIList.Refresh then NS.UIList:Refresh() end
    end
  )
  cbAccount.tooltipText = L.OPT_ACCOUNT_WIDE_TT
  p._wclAccountCheck = cbAccount

  -- Debug
  local cbDebug = CheckBox(p, L.OPT_DEBUG, {"TOPLEFT", cbAccount, "BOTTOMLEFT", 0, -8},
    function() return not not WinterChecklistDB.debug end,
    function(val) WinterChecklistDB.debug = val; NS:Print(val and L.DEBUG_ENABLED or L.DEBUG_DISABLED) end
  )

  -- Lock frame
  local cbLock = CheckBox(p, L.OPT_LOCK_FRAME, {"TOPLEFT", cbDebug, "BOTTOMLEFT", 0, -8},
    function() return not not (WinterChecklistDB.ui and WinterChecklistDB.ui.locked) end,
    function(val) WinterChecklistDB.ui.locked = val; NS.RefreshMainUIForOptions() end
  )

  -- Show help button
  local cbHelp = CheckBox(p, L.OPT_SHOW_HELP, {"TOPLEFT", cbLock, "BOTTOMLEFT", 0, -8},
    function() return WinterChecklistDB.ui and (WinterChecklistDB.ui.showHelp ~= false) end,
    function(val) WinterChecklistDB.ui.showHelp = val; NS.RefreshMainUIForOptions() end
  )

  -- Feedback section: sound on task add ---------------------------------------
  local fbTitle = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  fbTitle:SetPoint("TOPLEFT", cbHelp, "BOTTOMLEFT", 0, -24)
  fbTitle:SetText(L.OPT_FEEDBACK_SECTION)

  local cbSound = CheckBox(p, L.OPT_SOUND_ON_ADD, {"TOPLEFT", fbTitle, "BOTTOMLEFT", 0, -8},
    function() return not (WinterChecklistDB.ui and WinterChecklistDB.ui.soundOnAdd == false) end,
    function(val) WinterChecklistDB.ui.soundOnAdd = val end
  )

  local dd = CreateFrame("Frame", ADDON.."SoundDropdown", p, "UIDropDownMenuTemplate")
  dd:SetPoint("TOPLEFT", cbSound, "BOTTOMLEFT", -16, -8)

  local selectedName = WinterChecklistDB.ui and WinterChecklistDB.ui.soundName or ""
  UIDropDownMenu_Initialize(dd, function(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = L.OPT_SOUND_NONE
    info.func = function() selectedName = ""; UIDropDownMenu_SetText(dd, L.OPT_SOUND_NONE); WinterChecklistDB.ui.soundName = "" end
    UIDropDownMenu_AddButton(info)

    if NS.Media and NS.Media.GetSoundList then
      local sounds = NS.Media:GetSoundList()
      for _, name in ipairs(sounds) do
        local info2 = UIDropDownMenu_CreateInfo()
        info2.text = name
        info2.func = function()
          selectedName = name
          UIDropDownMenu_SetText(dd, name)
          WinterChecklistDB.ui.soundName = name
        end
        UIDropDownMenu_AddButton(info2)
      end
    end
  end)
  UIDropDownMenu_SetText(dd, (selectedName and selectedName ~= "" and selectedName) or L.OPT_SOUND_NONE)

  -- Profiles: copy tasks from another character --------------------------------
  local title = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 16, -24)
  title:SetText(L.OPT_PROFILE_COPY)

  local dd2 = CreateFrame("Frame", ADDON.."CopyFromDropdown", p, "UIDropDownMenuTemplate")
  dd2:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -16, -8)

  local fromKey
  UIDropDownMenu_Initialize(dd2, function(self, level)
    local chars = NS.Tasks and NS.Tasks.ListCharacters and NS.Tasks:ListCharacters() or {}
    for _, key in ipairs(chars) do
      local info = UIDropDownMenu_CreateInfo()
      info.text, info.func = key, function()
        fromKey = key
        UIDropDownMenu_SetText(dd2, key)
      end
      UIDropDownMenu_AddButton(info)
    end
  end)
  UIDropDownMenu_SetText(dd2, L.OPT_FROM_CHARACTER)

  local btn = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  btn:SetSize(140, 22)
  UIDropDownMenu_SetWidth(dd2, 180)
  UIDropDownMenu_JustifyText(dd2, "LEFT")
  btn:SetPoint("LEFT", dd2, "RIGHT", 12, 0)
  btn:SetSize(120, 22)
  btn:SetText(L.OPT_COPY_BUTTON)
  btn:SetScript("OnClick", function()
    if fromKey and NS.Tasks and NS.Tasks.CopyFromCharacter then
      NS.Tasks:CopyFromCharacter(fromKey)
      NS:Print(L.TASKS_COPIED_FMT:format(fromKey))
    end
  end)

  -- Add "About" subcategory (safe registration)
  addAboutSubcategory(p)
end

C_Timer.After(0, ensurePanel)


-- Add discoverability: register category and add "Open Main Window" button
local function wcl_add_open_button()
  if not NS.Options or not NS.Options.panel then return end
  local p = NS.Options.panel
  if p._wclOpenButton then return end

  local btn = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  btn:SetSize(160, 24)
  btn:SetPoint("TOPRIGHT", -24, -24)
  btn:SetText((NS.L.OPEN_MAIN))
  btn:SetScript("OnClick", function() if NS.ToggleUI then NS.ToggleUI() end end)
  p._wclOpenButton = btn

  if NS.IsRetail and NS.IsRetail() and Settings and Settings.RegisterAddOnCategory then
    if not p.categoryID then
      p.categoryID = Settings.RegisterAddOnCategory(p)
    end
  end
end

C_Timer.After(0.25, wcl_add_open_button)
