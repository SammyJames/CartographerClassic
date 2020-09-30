--- Copyright (c) 2020 Sammy James

local ADDON_NAME = ...
local CC = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
assert(CC, ADDON_NAME .. "not found")

local DP = CC:NewModule("DataProvider", "AceConsole-3.0", "AceEvent-3.0")
local LOC = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

function DP:OnEnable(...)
    CC:AppendLocale("enUS", function(L)
        L["DataProvider"] = "Data Provider"
    end)

    WorldMapFrame:AddDataProvider(self)
end

function DP:OnDisable(...)
    WorldMapFrame:RemoveDataProvider(self)
end

function DP:OnAdded(OwningMap)
    self.m_map = OwningMap

    self.m_set_area_label = function(_, ...)
        self:SendMessage("CARTOGRAPHER_SET_AREA_LABEL", ...)
    end

    self.m_clear_area_label = function(_, ...)
        self:SendMessage("CARTOGRAPHER_CLEAR_AREA_LABEL", ...)
    end

    self.m_map:RegisterCallback("SetAreaLabel", self.m_set_area_label)
    self.m_map:RegisterCallback("ClearAreaLabel", self.m_clear_area_label)
end

function DP:OnRemoved(OwningMap)
    assert(self.m_map == OwningMap)

    self.m_map:UnregisterCallback("SetAreaLabel", self.m_set_area_label)
    self.m_map:UnregisterCallback("ClearAreaLabel", self.m_clear_area_label)

    self.m_map = nil
end

function DP:GetMap()
    return self.m_map
end

function DP:SignalEvent(Event, ...)
end

function DP:OnShow(...)
    self:SendMessage("CARTOGRAPHER_MAP_OPENED")
end

function DP:OnHide(...)
    self:SendMessage("CARTOGRAPHER_MAP_CLOSED")
end

function DP:RemoveAllData(...)
    -- body
end

function DP:RefreshAllData(...)
    -- body
end

function DP:OnMapChanged(...)
    local CurrentMapId = WorldMapFrame:GetMapID()
    self:SendMessage("CARTOGRAPHER_MAP_CHANGED", CurrentMapId)
end

function DP:OnGlobalAlphaChanged(...)
    -- body
end

function DP:OnMapInsetSizeChanged(...)
    -- body
end

function DP:OnMapInsetMouseEnter(...)
    -- body
end

function DP:OnMapInsetMouseLeave(...)
    -- body
end

function DP:OnCanvasScaleChanged(...)
    -- body
end

function DP:OnCanvasPanChanged(...)
    -- body
end

function DP:OnCanvasSizeChanged(...)
    -- body
end