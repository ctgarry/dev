--[[
  @file    lua/minimap.lua
  @brief   LDB launcher + LibDBIcon minimap toggle.
  @deps    LibDataBroker-1.1, LibDBIcon-1.0 (bundled in lib/)
]]
local ADDON, NS = ...
local L = NS.L

local ICON_PATH = "Interface\\AddOns\\WinterPetCloud\\img\\minimap"
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_Snowball_10"

