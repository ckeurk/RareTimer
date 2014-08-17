-- -*- lua-indent-level: 4; -*-
--[[-----------------------------------------------------------------------------
Checkbox Widget
-------------------------------------------------------------------------------]]
local Type, Version = "CheckBox", 22
local GeminiConfigGUIPkg = Apollo.GetPackage("Gemini:ConfigGUI-1.0")
local GeminiConfigGUI = GeminiConfigGUIPkg and GeminiConfigGUIPkg.tPackage
if not GeminiConfigGUI or (GeminiConfigGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local select, pairs = select, pairs

-- WoW APIs
local PlaySound = PlaySound
local CreateFrame, UIParent = CreateFrame, UIParent

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: SetDesaturation, GameFontHighlight


--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
    ["OnAcquire"] = function(self)
        self:SetType()
        self:SetValue(false)
        self:SetTriState(nil)
        -- height is calculated from the width and required space for the description
        self:SetDisabled(nil)
        self:SetDescription(nil)
    end,

    ["SetDisabled"] = function(self, disabled)
        self.disabled = disabled
        self.button:Enable(not disabled)
    end,

    ["SetValue"] = function(self, value)
        self.checked = value
        self.button:SetCheck(self.checked)
        self:SetDisabled(self.disabled)
    end,

    ["GetValue"] = function(self)
        return self.checked
    end,

    ["SetTriState"] = function(self, enabled)
        self.tristate = enabled
        self:SetValue(self:GetValue())
    end,

    ["SetType"] = function(self, type)
    end,

    ["ToggleChecked"] = function(self)
        local value = self:GetValue()
        if self.tristate then
            --cycle in true, nil, false order
            if value then
                self:SetValue(nil)
            elseif value == nil then
                self:SetValue(false)
            else
                self:SetValue(true)
            end
        else
            self:SetValue(not self:GetValue())
        end
    end,

    ["SetLabel"] = function(self, label)
        self.button:SetText(label)
    end,

    ["SetDescription"] = function(self, desc)
        self.button:SetTooltip(desc or "")
    end,

    ["SetImage"] = function(self, path, ...)
        if false then
            local image = self.image
            image:SetTexture(path)

            if image:GetTexture() then
                local n = select("#", ...)
                if n == 4 or n == 8 then
                    image:SetTexCoord(...)
                else
                    image:SetTexCoord(0, 1, 0, 1)
                end
            end
            AlignImage(self)
        end
    end,

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
    OnMouseEnter = function(self, wndHandler, wndControl)
        if wndHandler ~= wndControl then return end
        self:Fire("OnEnter")
    end,

    OnMouseLeave = function(self, wndHandler, wndControl)
        if wndHandler ~= wndControl then return end
        self:Fire("OnLeave")
    end,

    OnButtonClick = function(self, wndHandler, wndControl)
        if wndHandler ~= wndControl then return end
        if not self.disabled then
            self.checked = wndControl:IsChecked()
            self:Fire("OnValueChanged", self.checked)
        end
    end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]

local tGeminiCheckBoxDef = {
    AnchorOffsets = { 0, 0, 300, 24 },
    RelativeToClient = true,
    BGColor = "UI_WindowBGDefault",
    TextColor = "UI_WindowTextDefault",
    Name = "GeminiCheckBox",
    SwallowMouseClicks = true,
    Escapable = true,
    Overlapped = true,
    Children = {
        {
            AnchorPoints = "FILL",
            AnchorOffsets = { 2, 0, -12, 0 },
            Class = "Button",
            Base = "BK3:btnHolo_ListView_Check",
            Font = "DefaultButton",
            ButtonType = "Check",
            DT_VCENTER = true,
            DT_CENTER = true,
            BGColor = "UI_BtnBGDefault",
            TextColor = "UI_BtnTextDefault",
            NormalTextColor = "UI_BtnTextDefault",
            PressedTextColor = "UI_BtnTextDefault",
            FlybyTextColor = "UI_BtnTextDefault",
            PressedFlybyTextColor = "UI_BtnTextDefault",
            DisabledTextColor = "ff7f7f7f",
            Name = "Button",
            Text = "",
            Events = {
                ButtonCheck = "OnButtonClick",
                ButtonUncheck = "OnButtonClick",
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

    local frame = Apollo.GetPackage("Gemini:GUI-1.0").tPackage:Create(tGeminiCheckBoxDef):GetInstance(widget, parent)
    -- create widget
    widget.frame = frame
    widget.button = frame:FindChild("Button")

    for method, func in pairs(methods) do
        widget[method] = func
    end

    return GeminiConfigGUI:RegisterAsWidget(widget)
end

GeminiConfigGUI:RegisterWidgetType(Type, Constructor, Version)
