--- Copyright (c) 2020 Sammy James

local ADDON_NAME = ...
local CC = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
assert(CC, ADDON_NAME .. "not found")

local BG = CC:NewModule("BattleGrounds")
local LOC = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

function BG:OnInitialize()
    CC:AppendLocale("enUS", function(L)
        L["BattleGrounds"] = "Battlegrounds"
        L["Module which provides maps of battlegrounds."] = true
        L["%d-man"] = true
    end)

    CC:AddModuleOptions(self.moduleName, {
        name = LOC["BattleGrounds"],
        desc = LOC["Module which provides maps of battlegrounds."],
        type = 'group',
        args = {},
        handler = self,
        disabled = function()
            return not CC:IsModuleEnabled(self.moduleName) or not CC:IsEnabled(self)
        end,
    })
end

function BG:OnEnable()
end

function BG:OnDisable()
end