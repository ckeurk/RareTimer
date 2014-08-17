-- -*- lua-indent-level: 4; -*-
--[[-----------------------------------------------------------------------------
   Heading Widget
   -------------------------------------------------------------------------------]]
local Type, Version = "Heading", 20
local GeminiConfigGUIPkg = Apollo.GetPackage("Gemini:ConfigGUI-1.0")
local GeminiConfigGUI = GeminiConfigGUIPkg and GeminiConfigGUIPkg.tPackage
if not GeminiConfigGUI or (GeminiConfigGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs

--[[-----------------------------------------------------------------------------
   Methods
   -------------------------------------------------------------------------------]]
local methods = {
    ["OnAcquire"] = function(self)
        self:SetFullWidth()
    end,

    ["SetText"] = function(self, text)
        text = text or ""
        if text == "" then
            self.label:Show(false)
        else
            self.label:Show(true)
            self.label:SetText(text)
            local width = (Apollo.GetTextWidth(self.font, text) + 20) / 2
            local left, top, right, bottom = self.label:GetAnchorOffsets()
            self.label:SetAnchorOffsets(-width, top, width, bottom)
        end
    end
}

--[[-----------------------------------------------------------------------------
   Constructor
   -------------------------------------------------------------------------------]]
local tGeminiHeaderDef = {
    AnchorOffsets = { 8, 8, 500, 36 },
    RelativeToClient = true,
    BGColor = "UI_WindowBGDefault",
    TextColor = "UI_WindowTitleYellow",
    Name = "GeminiHeader",
    Border = true,
    Picture = true,
    SwallowMouseClicks = true,
    Moveable = true,
    Escapable = true,
    Overlapped = true,
    Children = {
        {
            AnchorOffsets = { 0, -4, 0, 4 },
            AnchorPoints = { 0, 0.5, 1, 0.5 },
            RelativeToClient = true,
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Name = "Backing Line",
            Sprite = "AbilitiesSprites:spr_StatBlue",
            Picture = true,
            IgnoreMouse = true,
        },
        {
            AnchorOffsets = { -50, 2, 50, -2 },
            AnchorPoints = { 0.5, 0, 0.5, 1 },
            RelativeToClient = true,
            Font = "CRB_HeaderSmall",
            Text = "Test Header",
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTitleYellow",
            Name = "Label",
            DT_CENTER = true,
            DT_RIGHT = true,
            DT_VCENTER = true,
            IgnoreMouse = true,
            NewWindowDepth = 1,
            Picture = true,
            Sprite = "ChatLogSprites:sprChat_BlueBG",
        },
    },
}

local function Constructor(parent)
    local widget = {
        type = Type
    }

    local frame = Apollo.GetPackage("Gemini:GUI-1.0").tPackage:Create(tGeminiHeaderDef):GetInstance(widget, parent)

    -- create widget
    widget.frame = frame
    widget.font = tGeminiHeaderDef.Children[2].Font
    widget.label = frame:FindChild("Label")

    for method, func in pairs(methods) do
        widget[method] = func
    end

    return GeminiConfigGUI:RegisterAsWidget(widget)
end

GeminiConfigGUI:RegisterWidgetType(Type, Constructor, Version)
