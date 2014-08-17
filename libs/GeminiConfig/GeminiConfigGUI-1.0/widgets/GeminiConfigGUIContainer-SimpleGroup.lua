-- -*- lua-indent-level: 4; -*-
--[[-----------------------------------------------------------------------------
SimpleGroup Container
Simple container widget that just groups widgets.
-------------------------------------------------------------------------------]]
local Type, Version = "SimpleGroup", 20
local GeminiConfigGUIPkg = Apollo.GetPackage("Gemini:ConfigGUI-1.0")
local GeminiConfigGUI = GeminiConfigGUIPkg and GeminiConfigGUIPkg.tPackage
if not GeminiConfigGUI or (GeminiConfigGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent


--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
    ["OnAcquire"] = function(self)
        self:SetWidth(300)
        self:SetHeight(100)
    end,

    -- ["OnRelease"] = nil,

    ["LayoutFinished"] = function(self, width, height)
        if self.noAutoHeight then return end
        self:SetHeight(height or 0)
    end,

    ["OnWidthSet"] = function(self, width)
        local content = self.content
        content:SetWidth(width)
        content.width = width
    end,

    ["OnHeightSet"] = function(self, height)
        local content = self.content
        content:SetHeight(height)
        content.height = height
    end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")

    --Container Support
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT")
    content:SetPoint("BOTTOMRIGHT")

    local widget = {
        frame   = frame,
        content = content,
        type    = Type
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return GeminiConfigGUI:RegisterAsContainer(widget)
end

GeminiConfigGUI:RegisterWidgetType(Type, Constructor, Version)
