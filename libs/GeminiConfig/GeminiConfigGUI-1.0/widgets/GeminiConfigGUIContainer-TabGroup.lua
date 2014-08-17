-- -*- lua-indent-level: 4; -*-
--[[-----------------------------------------------------------------------------
   TabGroup Container
   Container that uses tabs on top to switch between groups.
   -------------------------------------------------------------------------------]]
local Type, Version = "TabGroup", 35
local GeminiConfigGUIPkg = Apollo.GetPackage("Gemini:ConfigGUI-1.0")
local GeminiConfigGUI = GeminiConfigGUIPkg and GeminiConfigGUIPkg.tPackage
if not GeminiConfigGUI or (GeminiConfigGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs, ipairs, assert, type, wipe = pairs, ipairs, assert, type, wipe

-- WoW APIs
local PlaySound = PlaySound
local CreateFrame, UIParent = CreateFrame, UIParent
local _G = _G
local tLibError = Apollo.GetPackage("Gemini:LibError-1.0")
local errorhandler = tLibError and tLibError.tPackage and tLibError.tPackage.Error or Print

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: PanelTemplates_TabResize, PanelTemplates_SetDisabledTabState, PanelTemplates_SelectTab, PanelTemplates_DeselectTab

-- local upvalue storage used by BuildTabs
local widths = {}
local rowwidths = {}
local rowends = {}


--[[-----------------------------------------------------------------------------
   Scripts
   -------------------------------------------------------------------------------]]
local function Tab_OnClick(frame)
    if not (frame.selected or frame.disabled) then
        PlaySound("igCharacterInfoTab")
        frame.obj:SelectTab(frame.value)
    end
end

local function Tab_OnEnter(frame)
    local self = frame.obj
    self:Fire("OnTabEnter", self.tabs[frame.id].value, frame)
end

local function Tab_OnLeave(frame)
    local self = frame.obj
    self:Fire("OnTabLeave", self.tabs[frame.id].value, frame)
end

local function Tab_OnShow(frame)
    _G[frame:GetName() .. "HighlightTexture"]:SetWidth(frame:GetTextWidth() + 30)
end

--[[-----------------------------------------------------------------------------
   Methods
   -------------------------------------------------------------------------------]]
local methods = {
    ["OnAcquire"] = function(self)
        self:SetTitle()
    end,

    ["OnRelease"] = function(self)
        self.status = nil

        for k in pairs(self.localstatus) do
            self.localstatus[k] = nil
        end
        self.tablist = nil
        for i, tab in pairs(self.tabs) do
            tab:Destroy()
            self.tabs[i] = nil
        end
    end,

    ["CreateTab"] = function(self, id)
        local tab = self.buttonDef:GetInstance(self, self.buttons)
        tab:SetData(id)
        return tab
    end,

    ["SetTitle"] = function(self, text)
        self.titletext:SetText(text or "")
        if text and text ~= "" then
            self.alignoffset = 0
        else
            self.alignoffset = -18
        end
        self:BuildTabs()
    end,

    ["SetStatusTable"] = function(self, status)
        assert(type(status) == "table")
        self.status = status
    end,

    ["SelectTab"] = function(self, value)
        xpcall(function()
            local status = self.status or self.localstatus
            local found
            for i, v in ipairs(self.tabs) do
                if v:GetData() == value then
                    v:SetCheck(true)
                    found = true
                else
                    v:SetCheck(false)
                end
            end
            status.selected = value
            if found then
                self:Fire("OnGroupSelected", value)
            end
        end, errorhandler)
    end,

    ["SetTabs"] = function(self, tabs)
        self.tablist = tabs
        self:BuildTabs()
    end,

    ["BuildTabs"] = function(self)
        xpcall(function()
            local hastitle = (self.titletext:GetText() and self.titletext:GetText() ~= "")
            local status = self.status or self.localstatus
            local tablist = self.tablist
            local tabs = self.tabs

            if not tablist then return end

            for i, v in ipairs(tablist) do
                local tab = tabs[i]
                if not tab then
                    tab = self:CreateTab(i)
                    tabs[i] = tab
                end
                tab:SetText(v.text)
                tab:Enable(not v.disabled)
                tab:SetData(v.value)
                local width = Apollo.GetTextWidth("DefaultButton", v.text)
                local left, top, right, bottom = tab:GetAnchorOffsets()
                tab:SetAnchorOffsets(left, top, left + width + 30, bottom)
            end

            for i = (#tablist) + 1, #tabs, 1 do
                tabs[i]:Destroy()
                tabs[i] = nil
            end
            self.buttons:ArrangeChildrenHorz()
        end, errorhandler)
    end,

    OnButtonCheck = function(self, handler, ctrl)
        if handler ~= ctrl then return end
        self:SelectTab(ctrl:GetData())
    end,

    OnTabEnter = function(self, handler, ctrl)
        if handler ~= ctrl then return end
        self:Fire("OnTabEnter", ctrl:GetValue(), ctrl)
    end,

    OnTabExit = function(self, handler, ctrl)
        if handler ~= ctrl then return end
        self:Fire("OnTabLeave", ctrl:GetValue(), ctrl)
    end
}

--[[-----------------------------------------------------------------------------
   Constructor
   -------------------------------------------------------------------------------]]
local tGeminiTabGroupDef = {
    AnchorOffsets = { 10, 3, 610, 411 },
    RelativeToClient = true,
    BGColor = "UI_WindowBGDefault",
    TextColor = "UI_WindowTextDefault",
    Name = "GeminiTabGroup",
    Border = true,
    Picture = true,
    SwallowMouseClicks = true,
    Escapable = true,
    Overlapped = true,
    Children = {
        {
            AnchorOffsets = { 8, 4, -8, 29 },
            AnchorPoints = "HFILL",
            RelativeToClient = true,
            Font = "CRB_HeaderMedium",
            Text = "Example Title",
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTitleYellow",
            Name = "Title",
            DT_CENTER = true,
        },
        {
            AnchorOffsets = { 0, 48, 0, 0 },
            AnchorPoints = "FILL",
            RelativeToClient = true,
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Template = "CRB_Hologram",
            Name = "ContentBackground",
            IgnoreMouse = true,
            UseTemplateBG = true,
            Border = true,
            NoClip = true,
            Children = {
                {
                    AnchorOffsets = { 0, 5, 0, 0 },
                    AnchorPoints = "FILL",
                    RelativeToClient = true,
                    BGColor = "UI_WindowBGDefault",
                    TextColor = "UI_WindowTextDefault",
                    Name = "Content",
                },
            },
        },
        {
            AnchorOffsets = { 3, 22, -3, 72 },
            AnchorPoints = "HFILL",
            RelativeToClient = true,
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Name = "ButtonContainer",
            IgnoreMouse = true,
            Children = {},
        },
    },
}
local tButtonTabDef = {
    AnchorOffsets = { 0, 0, 100, 40 },
    Class = "Button",
    Base = "CRB_ChallengeTrackerSprites:btnChallengeTab",
    Font = "DefaultButton",
    ButtonType = "Check",
    RadioGroup = "GeminiTabGroupRadio",
    DT_CENTER = true,
    BGColor = "UI_BtnBGDefault",
    TextColor = "UI_BtnTextDefault",
    NormalTextColor = "UI_BtnTextBlueNormal",
    PressedTextColor = "UI_BtnTextBluePressed",
    FlybyTextColor = "UI_BtnTextBlueFlyby",
    PressedFlybyTextColor = "UI_BtnTextBluePressedFlyby",
    DisabledTextColor = "UI_BtnTextBlueDisabled",
    Name = "Button",
    Text = "Tab Text",
    WindowSoundTemplate = "",
    GlobalRadioGroup = "",
    RadioDisallowNonSelection = true,
    Events = {
        ButtonCheck = "OnButtonCheck",
        MouseEnter = "OnTabEnter",
        MouseExit = "OnTabExit",
    },
}

local function Constructor(parent)
    local widget = {
        localstatus = {},
        alignoffset = 0,
        tabs        = {},
        type        = Type
    }

    local ggui = Apollo.GetPackage("Gemini:GUI-1.0").tPackage
    local frame = ggui:Create(tGeminiTabGroupDef):GetInstance(widget, parent)
    widget.titletext = frame:FindChild("Title")
    widget.content = frame:FindChild("Content")
    widget.buttons = frame:FindChild("ButtonContainer")
    widget.buttonDef = ggui:Create(tButtonTabDef)
    widget.frame = frame

    for method, func in pairs(methods) do
        widget[method] = func
    end

    return GeminiConfigGUI:RegisterAsContainer(widget)
end

GeminiConfigGUI:RegisterWidgetType(Type, Constructor, Version)
