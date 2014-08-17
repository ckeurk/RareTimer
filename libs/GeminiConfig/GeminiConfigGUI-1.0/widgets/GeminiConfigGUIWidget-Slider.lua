-- -*- lua-indent-level: 4; -*-
--[[-----------------------------------------------------------------------------
   Slider Widget
   Graphical Slider, like, for Range values.
   -------------------------------------------------------------------------------]]
local Type, Version = "Slider", 21
local GeminiConfigGUIPkg = Apollo.GetPackage("Gemini:ConfigGUI-1.0")
local GeminiConfigGUI = GeminiConfigGUIPkg and GeminiConfigGUIPkg.tPackage
if not GeminiConfigGUI or (GeminiConfigGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local min, max, floor = math.min, math.max, math.floor
local tonumber, pairs = tonumber, pairs

-- WoW APIs
local PlaySound = PlaySound
local CreateFrame, UIParent = CreateFrame, UIParent

local tLibError = Apollo.GetPackage("Gemini:LibError-1.0")
local errorhandler = tLibError and tLibError.tPackage and tLibError.tPackage.Error or Print

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: GameFontHighlightSmall

--[[-----------------------------------------------------------------------------
   Support functions
   -------------------------------------------------------------------------------]]
local function UpdateText(self)
    local value = self.value or 0
    if self.ispercent then
        self.editbox:SetText(("%s%%"):format(floor(value * 1000 + 0.5) / 10))
    else
        self.editbox:SetText(floor(value * 100 + 0.5) / 100)
    end
end

local function UpdateLabels(self)
    local min, max = (self.min or 0), (self.max or 100)
    if self.ispercent then
        self.lowtext:SetFormattedText("%s%%", (min * 100))
        self.hightext:SetFormattedText("%s%%", (max * 100))
    else
        self.lowtext:SetText(tostring(min))
        self.hightext:SetText(tostring(max))
    end
end

--[[-----------------------------------------------------------------------------
   Scripts
   -------------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
    frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
    frame.obj:Fire("OnLeave")
end

local function Frame_OnMouseDown(frame)
    frame.obj.slider:EnableMouseWheel(true)
    GeminiConfigGUI:ClearFocus()
end

local function Slider_OnMouseUp(frame)
    local self = frame.obj
    self:Fire("OnMouseUp", self.value)
end

local function Slider_OnMouseWheel(frame, v)
    local self = frame.obj
    if not self.disabled then
        local value = self.value
        if v > 0 then
            value = min(value + (self.step or 1), self.max)
        else
            value = max(value - (self.step or 1), self.min)
        end
        self.slider:SetValue(value)
    end
end


local function EditBox_OnEnter(frame)
    frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
end

local function EditBox_OnLeave(frame)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
end

--[[-----------------------------------------------------------------------------
   Methods
   -------------------------------------------------------------------------------]]
local methods = {
    ["OnAcquire"] = function(self)
        self:SetDisabled(false)
        self:SetIsPercent(nil)
        self:SetSliderValues(0, 100, 1)
        self:SetValue(0)
    end,

    -- ["OnRelease"] = nil,

    ["SetDisabled"] = function(self, disabled)
        self.disabled = disabled
        if disabled then
            self.slider:Enable(false)
            self.label:SetTextColor("ff7f7f7f")
            self.hightext:SetTextColor("ff7f7f7f")
            self.lowtext:SetTextColor("ff7f7f7f")
            self.editbox:SetTextColor("ff7f7f7f")
            self.editbox:Enable(false)
            self.editbox:ClearFocus()
        else
            self.slider:Enable(true)
            self.label:SetTextColor("UI_WindowTitleYellow")
            self.hightext:SetTextColor("ffffffff")
            self.lowtext:SetTextColor("ffffffff")
            --self.valuetext:SetTextColor("ffffffff")
            self.editbox:SetTextColor("ffffffff")
            self.editbox:Enable(true)
        end
    end,

    ["SetValue"] = function(self, value)
        self.sliderSetup = true
        self.slider:SetValue(value)
        self.value = value
        UpdateText(self)
        self.sliderSetup = nil
    end,

    ["GetValue"] = function(self)
        return self.value
    end,

    ["SetLabel"] = function(self, text)
        self.label:SetText(text or "")
    end,

    ["SetSliderValues"] = function(self, min, max, step)
        local frame = self.slider
        self.sliderSetup = true
        self.min = min
        self.max = max
        self.step = step
        frame:SetMinMax(min or 0, max or 100, step or 1)
        UpdateLabels(self)
        if self.value then
            frame:SetValue(self.value)
        end
        self.sliderSetup = nil
    end,

    ["SetIsPercent"] = function(self, value)
        self.ispercent = value
        UpdateLabels(self)
        UpdateText(self)
    end,

    OnSliderBarChanged = function(self, wndHandler, wndControl)
        xpcall(function()
            if wndHandler ~= wndControl then return end
            if not self.sliderSetup then
                local newvalue = wndControl:GetValue()
                if self.step and self.step > 0 then
                    local min_value = self.min or 0
                    newvalue = floor((newvalue - min_value) / self.step + 0.5) * self.step + min_value
                end
                if newvalue ~= self.value and not self.disabled then
                    self.value = newvalue
                    self:Fire("OnValueChanged", newvalue)
                end
                if self.value then
                    UpdateText(self)
                end
            end
        end, errorhandler)
    end,

    OnEditBoxReturn = function(self, wndHandler, wndControl)
        if wndHandler ~= wndControl then return end
        local value = wndControl:GetText()
        if self.ispercent then
            value = value:gsub('%%', '')
            value = tonumber(value) / 100
        else
            value = tonumber(value)
        end

        if value then
            --PlaySound("igMainMenuOptionCheckBoxOn")
            self.slider:SetValue(value)
            self:Fire("OnMouseUp", value)
        end
    end
}

--[[-----------------------------------------------------------------------------
   Constructor
   -------------------------------------------------------------------------------]]
local SliderBackdrop = {
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 }
}

local ManualBackdrop = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true,
    edgeSize = 1,
    tileSize = 5,
}

local tGeminiSliderDef = {
    AnchorOffsets = { 10, 10, 232, 87 },
    RelativeToClient = true,
    BGColor = "UI_WindowBGDefault",
    TextColor = "UI_WindowTextDefault",
    Name = "GeminiSlider",
    Children = {
        {
            AnchorOffsets = { 0, 21, -10, 54 },
            AnchorPoints = "HFILL",
            RelativeToClient = true,
            Name = "SliderBackground",
            BGColor = "white",
            TextColor = "white",
            Picture = true,
            IgnoreMouse = true,
            Sprite = "BK3:UI_BK3_Holo_InsetSlider",
            Children = {
                {
                    AnchorOffsets = { 20, -4, -20, -4 },
                    AnchorPoints = "FILL",
                    Class = "SliderBar",
                    Template = "Holo_Scrolllist_Options",
                    Name = "Slider",
                    BGColor = "white",
                    TextColor = "white",
                    LeftCap = "",
                    RightCap = "",
                    TickAmount = 0.100000,
                    InitialValue = 1.000000,
                    Min = 0.000000,
                    Max = 1.000000,
                    InstantMouseReact = false,
                    Events = {
                        SliderBarChanged = "OnSliderBarChanged",
                    },
                },
                {
                    AnchorOffsets = { 2, -4, 27, -4 },
                    AnchorPoints = "VFILL",
                    RelativeToClient = true,
                    Name = "LeftDisabled",
                    BGColor = "white",
                    TextColor = "UI_TextHoloBodyHighlight",
                    DT_RIGHT = true,
                    DT_VCENTER = true,
                    Sprite = "BK3:btnHolo_Options_DragLeftDisabled",
                    Picture = true,
                    IgnoreMouse = true,
                },
                {
                    AnchorOffsets = { -22, -4, 3, -4 },
                    AnchorPoints = "VFILLRIGHT",
                    RelativeToClient = true,
                    Name = "RightDisabled",
                    BGColor = "white",
                    TextColor = "UI_TextHoloBodyHighlight",
                    DT_VCENTER = true,
                    Sprite = "BK3:btnHolo_Options_DragRightDisabled",
                    Picture = true,
                    IgnoreMouse = true,
                },
            },
        },
        {
            AnchorOffsets = { 0, 0, -10, 20 },
            AnchorPoints = "HFILL",
            RelativeToClient = true,
            Font = "CRB_HeaderSmall_O",
            Text = "Slider Title",
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTitleYellow",
            Name = "Title",
            DT_VCENTER = true,
            DT_CENTER = true,
        },
        {
            AnchorOffsets = { -50, 42, 50, -7 },
            AnchorPoints = { 0.5, 0, 0.5, 1 },
            Class = "EditBox",
            RelativeToClient = true,
            Text = "EditBox",
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Template = "Holo_InputBox",
            Name = "EditBox",
            DT_VCENTER = true,
            DT_CENTER = true,
            UseTemplateBG = true,
            Border = true,
            Events = {
                EditBoxReturn = "OnEditBoxReturn",
            },
        },
        {
            AnchorOffsets = { 2, -34, 35, -11 },
            AnchorPoints = "BOTTOMLEFT",
            RelativeToClient = true,
            Font = "CRB_Pixel_O",
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Name = "MinValue",
            TextId = "CRB_0",
            DT_VCENTER = true,
            IgnoreMouse = true,
        },
        {
            AnchorOffsets = { -45, -34, -12, -11 },
            AnchorPoints = "BOTTOMRIGHT",
            RelativeToClient = true,
            Font = "CRB_Pixel_O",
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Name = "MaxValue",
            TextId = "CRB_0",
            DT_VCENTER = true,
            DT_RIGHT = true,
            IgnoreMouse = true,
        },
    },
}

local function Constructor(parent)
    local widget = {
        type = Type,
    }

    local frame = Apollo.GetPackage("Gemini:GUI-1.0").tPackage:Create(tGeminiSliderDef):GetInstance(widget, parent)

    widget.label = frame:FindChild("Title")
    widget.slider = frame:FindChild("Slider")
    widget.lowtext = frame:FindChild("MinValue")
    widget.hightext = frame:FindChild("MaxValue")
    widget.editbox = frame:FindChild("EditBox")
    widget.frame = frame

    for method, func in pairs(methods) do
        widget[method] = func
    end

    return GeminiConfigGUI:RegisterAsWidget(widget)
end

GeminiConfigGUI:RegisterWidgetType(Type, Constructor, Version)
