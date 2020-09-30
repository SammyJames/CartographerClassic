--- Copyright (c) 2020 Sammy James

local ADDON_NAME = ...
local CC = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
assert(CC, ADDON_NAME .. "not found")

local DM = CC:NewModule("DungeonMaps")
local LT = LibStub("LibTouristClassic-1.0")
local LOC = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

local MAPS = {
	["Naxxramas"] = "Naxxramas",
}

local FLOORS = {
	["Naxxramas"] = 6,
}

function DM:OnInitialize()
    CC:AppendLocale("enUS", function(L)
       	L["DungeonMaps"] = "Dungeon Maps"
		L["Module which provides maps of instances."] = true
		L["Instances"] = true
		L["%d-man"] = true
    end)

    CC:AddModuleOptions(self.moduleName, {
        name = LOC["DungeonMaps"],
        desc = LOC["Module which provides maps of instances."],
        type = 'group',
        args = {},
        handler = self,
        disabled = function()
            return not CC:IsModuleEnabled(self.moduleName) or not CC:IsEnabled(self)
        end,
    })
end

function DM:OnEnable()
end

function DM:OnDisable()
end