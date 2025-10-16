--[[
  @file        WinterPetCloud.lua
  @brief       Bootstrap, SavedVariables defaults, main frame, and cross-module glue.
  @addon       WinterPetCloud
  @author      CTG
  @notes       Keep this file skinny. UI specifics live in lua/*.lua modules.
]]

local ADDON, NS = ...
NS = NS or {}
_G[ADDON] = NS

-- Namespaces ------------------------------------------------------------------
NS.Util = NS.Util or {} -- from lua/utils.lua
NS.Const = NS.Const or {} -- constants collected here
local C = NS.Const

-- Flavor helpers
function NS.IsRetail()
  local v = (select(4, GetBuildInfo())) or 0
  return v >= 100000
end
function NS.IsClassic()
  return not NS.IsRetail()
end

-- Localization table (enUS sets NS.L; fallback to key if missing)
NS.L = NS.L or setmetatable({}, {
  __index = function(_, k)
    return k
  end,
})
local L = NS.L

-- SavedVariables container (declared in TOC via ## SavedVariables)
WinterPetCloudDB = WinterPetCloudDB or {}

-- Constants -------------------------------------------------------------------
C.FRAME_W_DEFAULT = 340
C.FRAME_H_DEFAULT = 380
C.FRAME_W_DOUBLE = 600
C.FRAME_W_MIN = C.FRAME_W_DEFAULT
C.FRAME_H_MIN = C.FRAME_H_DEFAULT
C.FRAME_W_MAX = C.FRAME_W_DOUBLE
C.FRAME_H_MAX = C.FRAME_H_DEFAULT
C.HELP_BTN_W = 24
C.HELP_BTN_H = 20
C.TITLE_MARGIN_X = 12
C.TITLE_MARGIN_Y = -10
