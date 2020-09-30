--- Copyright (c) 2020 Sammy James

local ADDON_NAME = ...
local CC = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
assert(CC, ADDON_NAME .. "not found")

local FL = CC:NewModule("FogLight")
local LOC = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

function FL:OnInitialize()
    CC:AppendLocale("enUS", function(L)
        L["FogLight"] = "Fog Light"
        L["Module to show unexplored areas on the map."] = true
        L["Unexplored color"] = true
        L["Change the color of the unexplored areas"] = true
    end)

    CC:AddModuleOptions(self.moduleName, {
        name = LOC["FogLight"],
        desc = LOC["Module to show unexplored areas on the map."],
        type = 'group',
        args = {},
        handler = self,
        disabled = function()
            return not CC:IsModuleEnabled(self.moduleName) or not CC:IsEnabled(self)
        end,
    })
end

function FL:OnEnable()
end

function FL:OnDisable()
end