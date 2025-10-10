--[[
  @file    lua/options.lua
  @brief   Interface Options panel (Retail + Classic) incl. profile task copy.
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
  cb:SetScript("OnShow", function(self) self:SetChecked(onGet()) end)
  return cb
end

local function ensurePanel()
  if Opt.panel then return end
  local p = CreateFrame("Frame")
  p.name = L.OPT_PANEL_TITLE

  if Settings and Settings.RegisterCanvasLayoutCategory then
    local cat = Settings.RegisterCanvasLayoutCategory(p, L.OPT_PANEL_TITLE)
    Opt.panel = p; p.categoryID = cat:GetID()
    Settings.RegisterAddOnCategory(cat)
  else
    Opt.panel = p
    if InterfaceOptions_AddCategory then InterfaceOptions_AddCategory(p) end
  end

  -- Minimap icon
  local cbMinimap = CheckBox(p, L.OPT_MINIMAP, {"TOPLEFT", 16, -16},
    function() return not (WinterChecklistDB.minimap and WinterChecklistDB.minimap.hide) end,
    function(val) WinterChecklistDB.minimap.hide = not val; NS:ApplyMinimapVisibility() end
  )

  -- Debug
  local cbDebug = CheckBox(p, L.OPT_DEBUG, {"TOPLEFT", cbMinimap, "BOTTOMLEFT", 0, -8},
    function() return not not WinterChecklistDB.debug end,
    function(val) WinterChecklistDB.debug = val; NS:Print(val and L.DEBUG_ENABLED or L.DEBUG_DISABLED) end
  )

  -- Lock frame
  local cbLock = CheckBox(p, L.OPT_LOCK_FRAME, {"TOPLEFT", cbDebug, "BOTTOMLEFT", 0, -8},
    function() return not not (WinterChecklistDB.ui and WinterChecklistDB.ui.locked) end,
    function(val) WinterChecklistDB.ui.locked = val; NS:RefreshMainUIForOptions() end
  )

  -- Show help button
  local cbHelp = CheckBox(p, L.OPT_SHOW_HELP, {"TOPLEFT", cbLock, "BOTTOMLEFT", 0, -8},
    function() return WinterChecklistDB.ui and (WinterChecklistDB.ui.showHelp ~= false) end,
    function(val) WinterChecklistDB.ui.showHelp = val; NS:RefreshMainUIForOptions() end
  )

  -- Profiles: copy tasks from another character --------------------------------
  local title = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", cbHelp, "BOTTOMLEFT", 0, -24)
  title:SetText(L.OPT_PROFILE_COPY)

  local dd = CreateFrame("Frame", ADDON.."CopyFromDropdown", p, "UIDropDownMenuTemplate")
  dd:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -16, -8)

  local fromKey
  UIDropDownMenu_Initialize(dd, function(self, level)
    local chars = NS.Tasks and NS.Tasks.ListCharacters and NS.Tasks:ListCharacters() or {}
    for _, key in ipairs(chars) do
      local info = UIDropDownMenu_CreateInfo()
      info.text, info.func = key, function()
        fromKey = key
        UIDropDownMenu_SetText(dd, key)
      end
      UIDropDownMenu_AddButton(info)
    end
  end)
  UIDropDownMenu_SetText(dd, L.OPT_FROM_CHARACTER)

  local btn = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  btn:SetSize(140, 22)
  btn:SetPoint("LEFT", dd, "RIGHT", 0, 0)
  btn:SetText(L.OPT_COPY_BUTTON)
  btn:SetScript("OnClick", function()
    if fromKey and NS.Tasks and NS.Tasks.CopyFromCharacter then
      NS.Tasks:CopyFromCharacter(fromKey)
      NS:Print(L.TASKS_COPIED_FMT:format(fromKey))
    end
  end)
end

C_Timer.After(0, ensurePanel)
