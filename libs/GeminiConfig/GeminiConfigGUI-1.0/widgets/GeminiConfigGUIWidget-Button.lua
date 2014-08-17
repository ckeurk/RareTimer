-- -*- lua-indent-level: 4; -*-
--[[-----------------------------------------------------------------------------
   Button Widget
   Graphical Button.
   -------------------------------------------------------------------------------]]
local Type, Version = "Button", 23
local GeminiConfigGUIPkg = Apollo.GetPackage("Gemini:ConfigGUI-1.0")
local GeminiConfigGUI = GeminiConfigGUIPkg and GeminiConfigGUIPkg.tPackage
if not GeminiConfigGUI or (GeminiConfigGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs

local _G = _G

local BUTTON_FONT = "CRB_Pixel_O"

--[[-----------------------------------------------------------------------------
   Methods
   -------------------------------------------------------------------------------]]
local methods = {
    ["OnAcquire"] = function(self)
    -- restore default values
        self:SetDisabled(false)
        self:SetAutoWidth(false)
        self:SetText()
    end,

    -- ["OnRelease"] = nil,

    ["SetText"] = function(self, text)
        self.button:SetText(text or "")
        if self.autoWidth then
            self:SetAutoWidth(true)
        end
    end,

    ["SetAutoWidth"] = function(self, autoWidth)
        self.autoWidth = autoWidth
        if self.autoWidth then
            self:SetWidth(Apollo.GetTextWidth(BUTTON_FONT, self.frame:GetText()) + 30)
        end
    end,

    ["SetDisabled"] = function(self, disabled)
        self.disabled = disabled
        self.button:Enable(not disabled)
    end,

--[[-----------------------------------------------------------------------------
    Event Handlers
    -------------------------------------------------------------------------------]]
    OnButtonSignal = function(self, button, ...)
        GeminiConfigGUI:ClearFocus()
        self:Fire("OnClick", ...)
    end,

    OnMouseEnter = function(self)
        self:Fire("OnEnter")
    end,

    OnMouseExit = function(self)
        self:Fire("OnLeave")
    end
}

--[[-----------------------------------------------------------------------------
   Constructor
   -------------------------------------------------------------------------------]]
local tGeminiButtonDef = {
    Name = "GeminiButton",
    AnchorOffsets = { 0, 0, 168, 33 },
    Children = {
        {
            AnchorPoints = "FILL",
            AnchorOffsets = { 0, 0, -10, 0 },
            Class = "Button",
            Base = "CRB_Basekit:kitBtn_Metal",
            Font = BUTTON_FONT,
            ButtonType = "PushButton",
            DT_VCENTER = true,
            DT_CENTER = true,
            BGColor = "UI_BtnBGDefault",
            TextColor = "UI_BtnTextDefault",
            NormalTextColor = "UI_BtnTextHoloNormal",
            PressedTextColor = "UI_BtnTextGreenNormal",
            FlybyTextColor = "UI_BtnTextHoloFlyby",
            PressedFlybyTextColor = "UI_BtnTextHoloPressedFlyby",
            DisabledTextColor = "UI_BtnTextHoloDisabled",
            Name = "Button",
            Border = true,
            Picture = true,
            SwallowMouseClicks = true,
            Overlapped = true,
            NoClip = true,
            DT_SINGLELINE = true,
            Events = {
                ButtonSignal = "OnButtonSignal",
                MouseEnter = "OnMouseEnter",
                MouseExit = "OnMouseExit",
            },
        },
    },
}
local function Constructor(parent)
    local widget = {
        type = Type
    }

    widget.frame = Apollo.GetPackage("Gemini:GUI-1.0").tPackage:Create(tGeminiButtonDef):GetInstance(widget, parent)
    widget.button = widget.frame:FindChild("Button")
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return GeminiConfigGUI:RegisterAsWidget(widget)
end

GeminiConfigGUI:RegisterWidgetType(Type, Constructor, Version)
