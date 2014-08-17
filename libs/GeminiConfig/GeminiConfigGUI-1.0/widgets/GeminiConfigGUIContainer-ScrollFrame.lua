-- -*- lua-indent-level: 4; -*-
--[[-----------------------------------------------------------------------------
   ScrollFrame Container
   Plain container that scrolls its content and doesn't grow in height.
   -------------------------------------------------------------------------------]]
local Type, Version = "ScrollFrame", 23
local GeminiConfigGUIPkg = Apollo.GetPackage("Gemini:ConfigGUI-1.0")
local GeminiConfigGUI = GeminiConfigGUIPkg and GeminiConfigGUIPkg.tPackage
if not GeminiConfigGUI or (GeminiConfigGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs, assert, type = pairs, assert, type
local min, max, floor, abs = math.min, math.max, math.floor, math.abs

--[[-----------------------------------------------------------------------------
   Support functions
   -------------------------------------------------------------------------------]]
local function FixScrollOnUpdate(frame)
    frame:SetScript("OnUpdate", nil)
    frame.obj:FixScroll()
end

--[[-----------------------------------------------------------------------------
   Scripts
   -------------------------------------------------------------------------------]]
local function ScrollFrame_OnMouseWheel(frame, value)
    frame.obj:MoveScroll(value)
end

local function ScrollFrame_OnSizeChanged(frame)
    frame:SetScript("OnUpdate", FixScrollOnUpdate)
end

local function ScrollBar_OnScrollValueChanged(frame, value)
    frame.obj:SetScroll(value)
end

--[[-----------------------------------------------------------------------------
   Methods
   -------------------------------------------------------------------------------]]
local methods = {
    ["OnAcquire"] = function(self)
        self:SetScroll(0)
    end,

    ["OnRelease"] = function(self)
        self.status = nil
        for k in pairs(self.localstatus) do
            self.localstatus[k] = nil
        end
    end,

    ["SetScroll"] = function(self, value)
        local status = self.status or self.localstatus
        local viewheight = self.frame:GetHeight()
        local height = self.content:GetHeight()
        local offset

        if viewheight > height then
            offset = 0
        else
            offset = floor((height - viewheight) / 1000.0 * value)
        end
        --      self.content:ClearAllPoints()
        --      self.content:SetPoint("TOPLEFT", 0, offset)
        --      self.content:SetPoint("TOPRIGHT", 0, offset)
        status.offset = offset
        status.scrollvalue = value
    end,

    ["MoveScroll"] = function(self, value)
        local status = self.status or self.localstatus
        local height, viewheight = self.scrollframe:GetHeight(), self.content:GetHeight()

        if self.scrollBarShown then
            local diff = height - viewheight
            local delta = 1
            if value < 0 then
                delta = -1
            end
            self.scrollbar:SetValue(min(max(status.scrollvalue + delta * (1000 / (diff / 45)), 0), 1000))
        end
    end,

    ["LayoutFinished"] = function(self, width, height)
    --self.content:SetHeight(height or 0 + 20)
    --- self.scrollframe:SetScript("OnUpdate", FixScrollOnUpdate)
    end,

    ["SetStatusTable"] = function(self, status)
        assert(type(status) == "table")
        self.status = status
        if not status.scrollvalue then
            status.scrollvalue = 0
        end
    end,

    ["OnWidthSet"] = function(self, width)
    --      local content = self.content
    --      content.width = width
    end,

    ["OnHeightSet"] = function(self, height)
    --      local content = self.content
    --      content.height = height
    end
}
--[[-----------------------------------------------------------------------------
   Constructor
   -------------------------------------------------------------------------------]]
local tGeminiScrollListDef = {
    AnchorOffsets = { 0, 0, 600, 300 },
    RelativeToClient = true,
    BGColor = "UI_WindowBGDefault",
    TextColor = "UI_WindowTextDefault",
    Name = "GeminiScrollList",
    Border = true,
    Picture = true,
    SwallowMouseClicks = true,
    Moveable = false,
    Escapable = true,
    Overlapped = true,
    Events = {
        WindowSizeChanged = "OnFrameResize",
    },
    Children = {
        {
            AnchorPoints = "FILL",
            RelativeToClient = true,
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Template = "Holo_ScrollList",
            Name = "Content",
            VScroll = true,
            IgnoreMouse = true,
            UseTemplateBG = true,
            Border = true,
            AutoHideScroll = true,
            Events = {
                WindowSizeChanged = "OnContentResize",
            },
        },
    },
}

local function Constructor(parent)

    local widget = {
        localstatus = { scrollvalue = 0 },
        type        = Type
    }
    local frame = Apollo.GetPackage("Gemini:GUI-1.0").tPackage:Create(tGeminiScrollListDef):GetInstance(widget, parent)
    widget.content = frame:FindChild("Content")
    widget.frame = frame

    for method, func in pairs(methods) do
        widget[method] = func
    end

    return GeminiConfigGUI:RegisterAsContainer(widget)
end

GeminiConfigGUI:RegisterWidgetType(Type, Constructor, Version)
