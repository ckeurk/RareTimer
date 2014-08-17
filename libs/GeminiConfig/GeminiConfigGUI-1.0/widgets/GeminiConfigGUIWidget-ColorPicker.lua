-- -*- lua-indent-level: 4; -*-
--[[-----------------------------------------------------------------------------
   ColorPicker Widget
   -------------------------------------------------------------------------------]]
local Type, Version = "ColorPicker", 21
local GeminiConfigGUIPkg = Apollo.GetPackage("Gemini:ConfigGUI-1.0")
local GeminiConfigGUI = GeminiConfigGUIPkg and GeminiConfigGUIPkg.tPackage
if not GeminiConfigGUI or (GeminiConfigGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs

-- WildStar APIs
local Apollo = Apollo

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: ShowUIPanel, HideUIPanel, ColorPickerFrame, OpacitySliderFrame

--[[-----------------------------------------------------------------------------
   Support functions
   -------------------------------------------------------------------------------]]
local function ColorCallback(self, r, g, b, a, isAlpha)
    if not self.HasAlpha then
        a = 1
    end
    self:SetColor(r, g, b, a)
    if ColorPickerFrame:IsVisible() then
        --colorpicker is still open
        self:Fire("OnValueChanged", r, g, b, a)
    else
        --colorpicker is closed, color callback is first, ignore it,
        --alpha callback is the final call after it closes so confirm now
        if isAlpha then
            self:Fire("OnValueConfirmed", r, g, b, a)
        end
    end
end

--[[-----------------------------------------------------------------------------
   Methods
   -------------------------------------------------------------------------------]]
local methods = {
    ["OnAcquire"] = function(self)
        self:SetHasAlpha(false)
        self:SetColor(0, 0, 0, 1)
        self:SetDisabled(nil)
        self:SetLabel(nil)
    end,

    -- ["OnRelease"] = nil,

    ["SetLabel"] = function(self, text)
        self.text:SetText(text or "")
    end,

    ["SetColor"] = function(self, r, g, b, a, hex)
        self.r, self.g, self.b, self.a = r, r, b, a
        if not hex then
            hex = self.GeminiColor:RGBAPercToHex(r, g, b, a)
        end
        self.hex = hex
        self.colorSwatch:SetBGColor(hex)
    end,

    ["SetHasAlpha"] = function(self, HasAlpha)
        self.HasAlpha = HasAlpha
    end,

    ["SetDisabled"] = function(self, disabled)
        self.disabled = disabled
        if self.disabled then
            self.frame:Enable(false)
            self.text:SetTextColor("ff7f7f7f")
        else
            self.frame:Enable(true)
            self.text:SetTextColor("ffffffff")
        end
    end,

    --[[-----------------------------------------------------------------------------
       Scripts
       -------------------------------------------------------------------------------]]
    OnMouseEnter = function(self, wnd, ctr)
        if wnd ~= ctr then return end
        frame.obj:Fire("OnEnter")
    end,

    OnMouseExit = function(self, wnd, ctr)
        if wnd ~= ctr then return end
        frame.obj:Fire("OnLeave")
    end,

    OnSelectColor = function(self, wnd, ctr)
        if wnd ~= ctr then return end
        if not self.disabled then
            local tColorOpts = {
                callback = "OnColorPicked",
                bCustomColor = true,
                bAlpha = self.HasAlpha,
                strInitialColor = self.hex
            }
            self.GeminiColor:ShowColorPicker(self, tColorOpts)
        end
    end,

    OnColorPicked = function(self, strColor)
        local r, g, b, a = self.GeminiColor:HexToRGBAPerc(strColor)
        self:SetColor(r, g, b, a)
        self:Fire("OnValueChanged", r, g, b, a)
    end,
}

--[[-----------------------------------------------------------------------------
   Constructor
   -------------------------------------------------------------------------------]]
local tGeminiColorPickerDef = {
    AnchorOffsets = { 867, 464, 1168, 496 },
    RelativeToClient = true,
    BGColor = "white",
    TextColor = "UI_WindowTextDefault",
    Name = "GeminiColorPicker",
    Border = true,
    SwallowMouseClicks = true,
    Overlapped = true,
    Events = {
        MouseButtonUp = "OnSelectColor",
        MouseEnter = "OnMouseEnter",
        MouseExit = "OnMouseExit",
    },
    Children = {
        {
            AnchorOffsets = { 31, 3, -4, -4 },
            AnchorPoints = "FILL",
            RelativeToClient = true,
            Font = "CRB_Pixel",
            Text = "This color is yours to pick",
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Name = "Label",
            DT_VCENTER = true,
        },
        {
            AnchorOffsets = { 1, 1, 27, -1 },
            AnchorPoints = "VFILL",
            RelativeToClient = true,
            BGColor = "black",
            TextColor = "UI_WindowTextDefault",
            Name = "ColorBG",
            Sprite = "BK3:UI_BK3_ItemQualityWhite",
            Picture = true,
            IgnoreMouse = true,
            Border = true,
            UseTemplateBG = true,
            Children = {
                {
                    AnchorOffsets = { 1, 1, -1, -1 },
                    AnchorPoints = "FILL",
                    RelativeToClient = true,
                    BGColor = "AttributeDexterity",
                    TextColor = "UI_WindowTextDefault",
                    Name = "ColorPreview",
                    Sprite = "BasicSprites:WhiteFill",
                    Picture = true,
                    IgnoreMouse = true,
                    Border = true,
                },
            },
        },
    },
}

local function Constructor(parent)
    local widget = {
        type = Type,
    }
    local GeminiColor = Apollo.GetPackage("GeminiColor")
    assert(GeminiColor, "Gemini Color is required to use the color picker.")

    local frame = Apollo.GetPackage("Gemini:GUI-1.0").tPackage:Create(tGeminiColorPickerDef):GetInstance(widget, parent)
    widget.colorSwatch = frame:FindChild("ColorPreview")
    widget.text = frame:FindChild("Label")
    widget.frame = frame
    widget.GeminiColor = GeminiColor.tPackage

    for method, func in pairs(methods) do
        widget[method] = func
    end

    return GeminiConfigGUI:RegisterAsWidget(widget)
end

GeminiConfigGUI:RegisterWidgetType(Type, Constructor, Version)
