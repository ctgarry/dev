--[[
  @file    lua/help.lua
  @brief   Quick "?" popup summary, anchored to main frame if provided.
]]
local ADDON, NS = ...
local L = NS.L
local C = NS.Const or {}

local H = {}
NS.Help = H

local HELP_W = 360
local HELP_H = 200

function H:Show(anchorFrame)
  if self.f then self.f:Hide() end
  local f = CreateFrame("Frame", ADDON.."Help", UIParent, "BackdropTemplate")
  self.f = f
  f:SetBackdrop(C.BACKDROP or { bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
                                 edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
                                 tile=true, tileSize=16, edgeSize=12,
                                 insets={left=3,right=3,top=3,bottom=3} })
  f:SetSize(HELP_W, HELP_H)
  if anchorFrame then
    f:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 10, 0)
  else
    f:SetPoint("CENTER")
  end

  local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 12, -12)
  title:SetText(L.HELP_SUMMARY_TITLE)

  local body = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  body:SetWidth(HELP_W - 30)
  body:SetJustifyH("LEFT")
  body:SetText(L.HELP_SUMMARY_BODY .. "\n\n" .. L.SLASH_TOGGLE .. "\n" .. L.SLASH_OPTIONS)

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 2, 2)
  f:Show()
end
