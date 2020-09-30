--- Copyright (c) 2020 Sammy James

local ADDON_NAME = ...
local CC = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
assert(CC, ADDON_NAME .. "not found")

local GP = CC:NewModule("GuildPositions")
local LOC = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

function GP:OnInitialize()
    CC:AppendLocale("enUS", function(L)
        L["GuildPositions"] = "Guild Positions"
        L["Module that shows your guild members' positions, and allows them to see you"] = true
        L["%.0f yd"] = true
        L["%.0f m"] = true
    end)

    CC:AddModuleOptions(self.moduleName, {
        name = LOC["GuildPositions"],
        desc = LOC["Module that shows your guild members' positions, and allows them to see you"],
        type = 'group',
        args = {},
        handler = self,
        disabled = function()
            return not CC:IsModuleEnabled(self.moduleName) or not CC:IsEnabled(self)
        end,
    })
end

function GP:OnEnable()
end

function GP:OnDisable()
end