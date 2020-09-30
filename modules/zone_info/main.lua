--- Copyright (c) 2020 Sammy James

local ADDON_NAME = ...
local CC = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
assert(CC, ADDON_NAME .. "not found")

local LT = LibStub("LibTouristClassic-1.0")
local ZI = CC:NewModule("ZoneInfo", "AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0", "AceTimer-3.0")
local DP = CC:GetModule("DataProvider")
local LOC = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

local strfmt = string.format
local tinsert = table.insert
local tremove = table.remove
local tconcat = table.concat
local unpack = unpack

function ZI:OnInitialize()
    CC:AppendLocale("enUS", function(L)
        L["ZoneInfo"] = "Zone Info"
        L["Module that shows the level of zones, instances, and other details"] = true
        L["Instances"] = true
        L["%d-man"] = true
        L[" and "] = true
    end)

    CC:AddModuleOptions(self.moduleName, {
        name = LOC["ZoneInfo"],
        desc = LOC["Module that shows the level of zones, instances, and other details"],
        type = 'group',
        args = {},
        handler = self,
        disabled = function()
            return not CC:IsModuleEnabled(self.moduleName) or not CC:IsEnabled(self)
        end,
    })

    self.m_fishing = nil
    self.m_regions = {}
end

function ZI:OnEnable()
    if not self.m_frame then
        self.m_frame = CreateFrame("Frame", "CartographerZoneInfo", DP:GetMap():GetCanvasContainer())
        self.m_title = self.m_frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        self.m_desc = self.m_frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

        local font, size = GameFontHighlightLarge:GetFont()

        self.m_title:SetFont(font, size, "OUTLINE")
        self.m_title:SetPoint("TOP", DP:GetMap():GetCanvasContainer(), 0, -15)
        self.m_title:SetWidth(1024)

        font, size = GameFontHighlightSmall:GetFont()

        self.m_desc:SetFont(font, size, "OUTLINE")
        self.m_desc:SetPoint("TOP", self.m_title, "BOTTOM", 0, -5)
        self.m_desc:SetWidth(1024)
    end

    self:HookBlizzard()

    self.m_frame:Show()

    self:RegisterMessage("CARTOGRAPHER_MAP_CHANGED", "CartOnMapChanged")
    self:RegisterMessage("CARTOGRAPHER_SET_AREA_LABEL", "CartSetAreaLabel")
    self:RegisterMessage("CARTOGRAPHER_CLEAR_AREA_LABEL", "CartClearAreaLabel")

    self.m_fishing = GetSpellInfo(7620) -- 7620 Fishing

    --ViragDevTool_AddData(self, "CartographerClassic_ZoneInfo")
end

function ZI:OnDisable()
    self.m_frame:Hide()
end

function ZI:RequestUpdate()
    if self.m_timer then
        return
    end

    self.m_timer = self:ScheduleTimer("OnUpdate", 0.5)
end

function ZI:CartOnMapChanged(_, _)
    -- body
end

function ZI:CartSetAreaLabel(_, Type, Name, Desc, _, _, _)
    tinsert(self.m_regions, { Name = Name, Description = Desc })
    self:RequestUpdate()
end

function ZI:CartClearAreaLabel(_, Type)
    if #self.m_regions == 0 then
        return
    end

    tremove(self.m_regions)
    self:RequestUpdate()
end

function ZI:OnUpdate()
    self:CancelTimer(self.m_timer)
    self.m_timer = nil

    if #self.m_regions == 0 then
        self:Print("Clear")
    else
        local ToShow = tremove(self.m_regions)
        self:Print(ToShow.Name)
    end
end

function ZI:GetLabelDataProvider()
    local Result = nil
    for k in pairs(DP:GetMap().dataProviders) do
        if k and k.Label then
            Result = k
            break
        end
    end

    return Result
end

function ZI:HookBlizzard()
    local LabelDP = self:GetLabelDataProvider()
    if LabelDP then
        self:RawHook(LabelDP.Label, "SetLabel", "OurSetLabel", true)
        self:RawHook(LabelDP.Label, "ClearLabel", "OurClearLabel", true)
    end
end

function ZI:OurSetLabel(_, Type, Name, _, _, _, _)
    local Low, High = LT:GetLevel(Name)
    local r, g, b = LT:GetLevelColor(Name)

    local LevelText
    if Low == 0 then
        LevelText = ""
    elseif Low == High then
        LevelText = strfmt([[|cff%02x%02x%02x [%d]|r]], r * 255, g * 255, b * 255, High)
    else
        LevelText = strfmt([[|cff%02x%02x%02x [%d-%d]|r]], r * 255, g * 255, b * 255, Low, High)
    end

    r, g, b = LT:GetFactionColor(Name)
    local Title = ("|cff%02x%02x%02x%s|r%s"):format(r * 255, g * 255, b * 255, Name, LevelText)
    local Texts = {}

    local HasInst = LT:DoesZoneHaveInstances(Name)
    if HasInst then
        tinsert(Texts, strfmt([[|cffffff00%s:|r]], LOC["Instances"]))
        for Instance in LT:IterateZoneInstances(Name) do
            local Complex = LT:GetComplex(Instance)
            local InstLow, InstHigh = LT:GetLevel(Instance)
            local r1, g1, b1 = LT:GetFactionColor(Instance)
            local r2, g2, b2 = LT:GetLevelColor(Instance)
            local InstGroupSize = LT:GetInstanceGroupSize(Instance)
            local InstAltGroupSize = LT:GetInstanceAltGroupSize(Instance)
            local InstName = Instance
            if Complex then
                InstName = Complex .. " - " .. Instance
            end

            if InstLow == InstHigh then
                if (InstAltGroupSize > 0) and (InstGroupSize > 0) then
                    tinsert(Texts,
                            strfmt([[|cff%02x%02x%02x%s|r |cff%02x%02x%02x[%d]|r ]] .. LOC["%d-man"] .. LOC[" and "] .. LOC["%d-man"],
                                    r1 * 255, g1 * 255, b1 * 255,
                                    InstName,
                                    r2 * 255, g2 * 255, b2 * 255,
                                    InstHigh,
                                    InstGroupSize,
                                    InstAltGroupSize))
                elseif InstGroupSize > 0 then
                    tinsert(Texts,
                            strfmt([[|cff%02x%02x%02x%s|r |cff%02x%02x%02x[%d]|r ]] .. LOC["%d-man"],
                                    r1 * 255, g1 * 255, b1 * 255,
                                    InstName,
                                    r2 * 255, g2 * 255, b2 * 255,
                                    InstHigh,
                                    InstGroupSize))
                else
                    tinsert(Texts,
                            strfmt([[|cff%02x%02x%02x%s|r |cff%02x%02x%02x[%d]|r]],
                                    r1 * 255, g1 * 255, b1 * 255,
                                    InstName,
                                    r2 * 255, g2 * 255, b2 * 255,
                                    InstHigh))
                end
            else
                if (InstAltGroupSize > 0) and (InstGroupSize > 0) then
                    tinsert(Texts,
                            strfmt([[|cff%02x%02x%02x%s|r |cff%02x%02x%02x[%d-%d]|r ]] .. LOC["%d-man"] .. LOC[" and "] .. LOC["%d-man"],
                                    r1 * 255, g1 * 255, b1 * 255,
                                    InstName,
                                    r2 * 255, g2 * 255, b2 * 255,
                                    InstLow,
                                    InstHigh,
                                    InstGroupSize,
                                    InstAltGroupSize))
                elseif InstGroupSize > 0 then
                    tinsert(Texts,
                            strfmt([[|cff%02x%02x%02x%s|r |cff%02x%02x%02x[%d-%d]|r ]] .. LOC["%d-man"],
                                    r1 * 255, g1 * 255, b1 * 255,
                                    InstName,
                                    r2 * 255, g2 * 255, b2 * 255,
                                    InstLow,
                                    InstHigh,
                                    InstGroupSize))
                else
                    tinsert(Texts,
                            strfmt([[|cff%02x%02x%02x%s|r |cff%02x%02x%02x[%d-%d]|r]],
                                    r1 * 255, g1 * 255, b1 * 255,
                                    InstName,
                                    r2 * 255, g2 * 255, b2 * 255,
                                    InstLow,
                                    InstHigh))
                end
            end
        end
    end

    local FishLevel = LT:GetFishingLevel(Name)
    if FishLevel then
        for i = 1, GetNumSkillLines() do
            local SkillName, _, _, SkillRank = GetSkillLineInfo(i)
            if SkillName == self.m_fishing then
                local r, g, b = 1, 1, 0
                local r1, g1, b1 = 1, 0, 0
                if FishLevel < SkillRank then
                    r1, g1, b1 = 0, 1, 0
                end
                tinsert(Texts, strfmt([[|cff%02x%02x%02x%s|r |cff%02x%02x%02x[%d]|r]], r * 255, g * 255, b * 255, self.m_fishing, r1 * 255, g1 * 255, b1 * 255, FishLevel))
            end
        end
    end

    tinsert(self.m_regions, { Name = Title, Description = tconcat(Texts, "\n") })
    self:RequestUpdate()
end

function ZI:OurClearLabel(_, Type)
    if #self.m_regions == 0 then
        return
    end

    tremove(self.m_regions)
    self:RequestUpdate()
end