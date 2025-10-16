--[[
  @file    i18n/enUS.lua
  @brief   American English strings. Missing keys fall back to key name.
]]
local _, NS = ...
local L = {}
NS.L = setmetatable(L, {
  __index = function(_, k)
    return k
  end,
})

-- General
L.ADDON_NAME = "WinterPetCloud"
L.OK = "OK"
L.CANCEL = "Cancel"
L.CLOSE = "Close"
L.HELP = "Help"
L.DEBUG_ENABLED = "Debug enabled."
L.DEBUG_DISABLED = "Debug disabled."
L.FILTER_LABEL = "Filter:"
L.CLEAR_SHORT = "X"
L.DELETE_SHORT = "x"
L.OPEN_MAIN = "Open Main Window"
L.RESET = "Reset"
L.RESET_ALL = "Reset All"
L.CONFIRM = "Confirm"
L.YES = "Yes"
L.NO = "No"

-- Options
L.OPT_PANEL_TITLE = L.ADDON_NAME
L.OPT_MINIMAP = "Show minimap icon"
