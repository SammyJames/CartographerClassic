--- Copyright (c) 2020 Sammy James

local ADDON_NAME = ...
local CC = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
assert(CC, ADDON_NAME .. "not found")

local Look = CC:NewModule("Look", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0")
local LOC = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

local tinsert = table.insert
local tremove = table.remove
local UIParent = UIParent

function Look:OnInitialize()

    CC:AppendLocale("enUS", function(L)
        L["Look"] = "Look 'n Feel"
        L["Module which allows you to change the transparency, position, and scale of the world map."] = true
        L["Transparency"] = true
        L["Transparency of the World Map"] = true
        L["Overlay transparency"] = true
        L["Transparency of World Map overlays"] = true
        L["Scale"] = true
        L["Scale of the World Map"] = true
        L["Tooltip scale"] = true
        L["Scale of the World Map tooltip"] = true
    end)

    CC:AddModuleOptions(self.moduleName, {
        name = LOC["Look"],
        desc = LOC["Module which allows you to change the transparency, position, and scale of the world map."],
        type = 'group',
        args = {},
        handler = self,
        disabled = function()
            return not CC:IsModuleEnabled(self.moduleName) or not CC:IsEnabled(self)
        end,
    })

end

function Look:OnEnable()
    self:RegisterMessage("CARTOGRAPHER_ZONE_CHANGED", "CartOnZoneChanged")

    UIPanelWindows["WorldMapFrame"] = nil
    WorldMapFrame:SetAttribute("UIPanelLayout-area", nil)
    WorldMapFrame:SetAttribute("UIPanelLayout-enabled", false)

    WorldMapFrame:SetMovable(true)
    WorldMapFrame:RegisterForDrag("LeftButton")
    WorldMapFrame:SetScript("OnDragStart", function()
        self:StartDragging()
    end)
    WorldMapFrame:SetScript("OnDragStop", function()
        self:StopDragging()
    end)

    WorldMapFrame:SetIgnoreParentScale(false)
    WorldMapFrame.BlackoutFrame:Hide()
    WorldMapFrame.IsMaximized = function()
        return false
    end

    WorldMapFrame:SetFrameStrata("HIGH")
    WorldMapFrame.BorderFrame:SetFrameStrata("LOW")

    WorldMapFrame.ContinentDropDown:Hide()
    WorldMapFrame.ZoneDropDown:Hide()
    WorldMapZoomOutButton:Hide()

    self:RawHook(WorldMapFrame.ScrollContainer, "GetCursorPosition", "OurGetCursorPosition", true)

    tinsert(UISpecialFrames, "WorldMapFrame")
    self.m_frame_index = #UISpecialFrames
end

function Look:OnDisable()
    tremove(UISpecialFrames, self.m_frame_index)

    UIPanelWindows["WorldMapFrame"] = WorldMapFrame
    WorldMapFrame:SetAttribute("UIPanelLayout-area", nil)
    WorldMapFrame:SetAttribute("UIPanelLayout-enabled", true)

    WorldMapFrame:SetMovable(false)
    WorldMapFrame:SetScript("OnDragStart", nil)
    WorldMapFrame:SetScript("OnDragStop", nil)

    WorldMapFrame:SetIgnoreParentScale(true)
    WorldMapFrame.BlackoutFrame:Show()
    WorldMapFrame.IsMaximized = function()
        return true
    end

    WorldMapFrame.ContinentDropDown:Show()
    WorldMapFrame.ZoneDropDown:Show()
    WorldMapZoomOutButton:Show()
end

function Look:StartDragging()
    if not WorldMapFrame:IsMaximized() then
        WorldMapFrame:StartMoving()
    end
end

function Look:StopDragging()
    WorldMapFrame:StopMovingOrSizing()
    if not WorldMapFrame:IsMaximized() then
        --LibWindow.SavePosition(WorldMapFrame)
    end
end

function Look:CartOnZoneChanged()
end

function Look:OurGetCursorPosition()
    local x, y = self.hooks[WorldMapFrame.ScrollContainer].GetCursorPosition(WorldMapFrame.ScrollContainer)
    local Scale = WorldMapFrame:GetScale() * UIParent:GetEffectiveScale()
    return x / Scale, y / Scale
end