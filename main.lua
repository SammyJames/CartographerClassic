--- Copyright (c) 2020 Sammy James

local ADDON_NAME, ADDON_TABLE = ...
local CC = LibStub("AceAddon-3.0"):NewAddon(ADDON_TABLE, ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0")
local LOC = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
local LCD = LibStub("AceConfigDialog-3.0")
local LDB = LibStub("AceDB-3.0")
local LCR = LibStub("AceConfigRegistry-3.0")
local LDBO = LibStub("AceDBOptions-3.0")
local LT = LibStub("LibTouristClassic-1.0")

local States = {
    CLOSED = 0,
    OPEN = 1,
    UNKNOWN = 2,
}

local _
local strfmt = string.format
local tinsert = table.insert
local tsort = table.sort
local UNKNOWN = UNKNOWN

CC.m_state = States.UNKNOWN
CC.m_map_buttons = {}
CC.m_view_menu = {}
CC.m_view_menu_map = nil
CC.m_view_btn = nil
CC.m_profile = nil

local Defaults = {
    profile = {
        enabled = true,
        enabled_modules = {
            ['*'] = true
        }
    }
}

local Options = {
    type = "group",
    name = LOC["Cartographer"],
    desc = LOC["Addon to manipulate the map."],
    args = {
        enabled = {
            type = "toggle",
            name = LOC["Enable Cartographer"],
            desc = LOC["Enable or disable Cartographer"],
            order = 1,
            get = function(_)
                return CC.m_profile.enabled
            end,
            set = function(_, v)
                CC.m_profile.enabled = v
                if v then
                    CC:Enable()
                else
                    CC:Disable()
                end
            end,
            disabled = false,
        },
        overall_settings = {
            type = "group",
            name = LOC["Overall Settings"],
            desc = LOC["Overall settings that affect everything"],
            order = 10,
            get = function(info)
                return CC.m_profile[info.arg]
            end,
            set = function(info, v)
                local arg = info.arg
                CC.m_profile[arg] = v
            end,
            disabled = function()
                return not CC.m_profile.enabled
            end,
            args = {
                desc = {
                    name = LOC["These settings control the look and feel of Cartographer globally."],
                    type = "description",
                    order = 0,
                }
            }
        }
    }
}

function CC:OnInitialize()
    self.m_db = LDB:New(ADDON_NAME .. "DB", Defaults)
    self.m_db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.m_db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    self.m_db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
    self.m_profile = self.m_db.profile

    self:RegisterChatCommand("cartographer", function()
        LCD:Open(ADDON_NAME)
    end)
    LCD:AddToBlizOptions(ADDON_NAME, LOC["Cartographer"])
end

function CC:OnEnable()
    self:RegisterMessage("CARTOGRAPHER_MAP_OPENED", "CartOnMapOpened")
    self:RegisterMessage("CARTOGRAPHER_MAP_CLOSED", "CartOnMapClosed")
    self:RegisterMessage("CARTOGRAPHER_MAP_CHANGED", "CartOnMapChanged")

    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneChangedNewArea")
    self:RegisterEvent("ZONE_CHANGED", "OnZoneChanged")
    self:RegisterEvent("ZONE_CHANGED_INDOORS", "OnZoneChangedIndoors")

    self:CreateOptionsButton()
    self:CreateViewButton()

    for Name, Module in self:IterateModules() do
        if Name ~= "DataProvider" then
            Options.args.overall_settings.args[Name] = {
                name = LOC[Name],
                desc = LOC["Suspend/resume this module."],
                type = "toggle",
                order = -1,
                get = function(_)
                    return self.m_profile.enabled_modules[Name] and self:IsEnabled(Name)
                end,
                set = function(_)
                    if not self:IsEnabled(Name) or not self.m_profile.enabled_modules[Name] then
                        self:EnableModule(Name)
                        self.m_profile.enabled_modules[Name] = true
                    else
                        self:DisableModule(Name)
                        self.m_profile.enabled_modules[Name] = false
                    end
                end
            }
        end
    end

    LCR:RegisterOptionsTable(ADDON_NAME, Options)
    Options.args.profiles = LDBO:GetOptionsTable(self.m_db)
    Options.args.profiles.disabled = Options.args.overall_settings.disabled

    --ViragDevTool_AddData(Options, "CC: Options")
end

function CC:OnDisable()
    -- stub
end

function CC:GetProfile()
    return self.m_profile
end

function CC:IsModuleEnabled(ModuleName)
    return self.m_profile.enabled_modules[ModuleName]
end

function CC:CreateOptionsButton()
    local options_btn = CreateFrame("Button", "CartographerOptionsButton", WorldMapFrame, "UIPanelButtonTemplate")
    options_btn:SetText(LOC["Cartographer"])
    options_btn:SetScript("OnClick", function()
        LCD:Open(ADDON_NAME)
    end)

    local width = options_btn:GetTextWidth() + 30
    if width < 110 then
        width = 110
    end
    options_btn:SetWidth(width)
    options_btn:SetHeight(22)
    options_btn:SetFrameStrata("FULLSCREEN_DIALOG")

    self:RegisterButton(options_btn, 1)
end

function CC:CreateViewButton()
    local view_btn = CreateFrame("Button", "CartographerViewButton", WorldMapFrame, "UIPanelButtonTemplate")
    view_btn:SetText(UNKNOWN)
    view_btn:SetScript("OnClick", function()
        L_ToggleDropDownMenu(1, nil, self.m_view_menu, "cursor", 3, -3)
    end)
    view_btn:SetScript("OnHide", function()
        L_CloseDropDownMenus()
    end)

    local width = view_btn:GetTextWidth() + 30
    if width < 220 then
        width = 220
    end
    view_btn:SetWidth(width)
    view_btn:SetHeight(22)
    view_btn:SetFrameStrata("FULLSCREEN_DIALOG")

    self:RegisterButton(view_btn, 0)

    self.m_view_menu = L_Create_UIDropDownMenu("Cartographer_ViewMenu", view_btn)
    L_UIDropDownMenu_Initialize(self.m_view_menu, function(...)
        self:GenerateViewMenu(...)
    end, "MENU")

    self.m_view_btn = view_btn
end

function CC:GenerateViewMenu(_, Level, MenuList)
    local Info = L_UIDropDownMenu_CreateInfo()

    if Level == 1 then

        Info.text, Info.hasArrow, Info.menuList, Info.isNotRadio, Info.notCheckable = LOC["Cities"], true, "ShowCities", true, true
        L_UIDropDownMenu_AddButton(Info)

        Info.text, Info.hasArrow, Info.menuList, Info.isNotRadio, Info.notCheckable = LOC["Zones"], true, "ShowZones", true, true
        L_UIDropDownMenu_AddButton(Info)

        Info.text, Info.checked, Info.hasArrow, Info.isNotRadio, Info.notCheckable = LOC["Close"], false, false, true, true
        Info.func = function()
            L_CloseDropDownMenus()
        end
        L_UIDropDownMenu_AddButton(Info)

    elseif Level == 2 and (MenuList == "ShowCities" or MenuList == "ShowZones") then

        for i, _ in pairs(LT:GetMapContinentsAlt()) do
            local Validate = LT:GetMapZonesAlt(i)
            for k, v in pairs(Validate) do
                local Text = v
                local Low, High = LT:GetLevel(v)
                local r, g, b = LT:GetLevelColor(v)

                if (MenuList == "ShowCities" and LT:IsCity(v)) or (MenuList == "ShowZones" and not LT:IsCity(v)) then

                    local LevelText
                    if Low == 0 then
                        LevelText = ""
                    elseif Low == High then
                        LevelText = ("|cff%02x%02x%02x[%d]|r"):format(r * 255, g * 255, b * 255, High)
                    else
                        LevelText = ("|cff%02x%02x%02x[%d-%d]|r"):format(r * 255, g * 255, b * 255, Low, High)
                    end
                    local r, g, b = LT:GetFactionColor(v)
                    Text = ("|cff%02x%02x%02x%s|r%s"):format(r * 255, g * 255, b * 255, tostring(Text), LevelText)

                    Info.text, Info.hasArrow, Info.menuList, Info.isNotRadio, Info.notCheckable = Text, false, MenuList, true, true
                    Info.func = function(_)
                        L_CloseDropDownMenus()
                        self:OnViewMenuClick(i, k)
                    end

                    L_UIDropDownMenu_AddButton(Info, Level)

                end
            end
        end

    end
end

function CC:OnViewMenuClick(_, Zone)
    WorldMapFrame:SetMapID(Zone)
end

function CC:CartOnMapOpened(_)
    if self.m_state == States.CLOSED or self.m_state == States.UNKNOWN then
        self.m_state = States.OPEN
    end
end

function CC:CartOnMapClosed(_)
    if self.m_state == States.OPEN then
        self.m_state = States.CLOSED
    end
end

function CC:CartOnMapChanged(_, CurrentMapId)
    local Text = LT:GetMapNameByIDAlt(CurrentMapId)
    self.m_view_btn:SetText(Text)
end

function CC:OnZoneChangedNewArea(...)
    --self:Print("On Zone Changed New Area: " .. tostring(...))
end

function CC:OnZoneChanged(...)
    --self:Print("On Zone Changed: " .. tostring(...))
end

function CC:OnZoneChangedIndoors(...)
    --self:Print("On Zone Changed Indoors: " .. tostring(...))
end

function CC:OnProfileChanged(_, Database, _)
    self.m_profile = Database.profile
end

function CC:RegisterButton(frame, order)
    if self.m_map_buttons[frame] then
        error(strfmt("Cannot add %q to map buttons, it already exists", frame:GetName() or "anonymous frame"), 2)
    end

    self.m_map_buttons[frame] = order
    self:UpdateMapButtons()
end

function CC:UpdateMapButtons()
    local tmp = {}
    for k in pairs(self.m_map_buttons) do
        tinsert(tmp, k)
    end

    tsort(tmp, function(lhs, rhs)
        return self.m_map_buttons[lhs] < self.m_map_buttons[rhs]
    end)

    local width = -10
    for _, frame in ipairs(tmp) do
        width = width + frame:GetWidth() + 10
    end

    local last = tmp[1]
    last:SetPoint("BOTTOM", WorldMapZoomOutButton, "BOTTOM", 0, 0)
    last:SetPoint("LEFT", WorldMapFrame.ScrollContainer, "CENTER", -width / 2, 0)
    for i = 2, #tmp do
        local iter = tmp[i]
        iter:SetPoint("LEFT", last, "RIGHT", 10, 0)
        last = iter
    end
end

function CC:AppendLocale(Lang, Callback)
    local locale = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, Lang, false)
    if locale ~= nil then
        Callback(locale)
    end
end

function CC:AddModuleOptions(ModuleName, InOptions)
    Options.args[ModuleName] = InOptions
end