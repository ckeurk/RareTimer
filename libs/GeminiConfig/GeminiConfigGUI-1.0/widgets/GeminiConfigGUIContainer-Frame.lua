-- -*- lua-indent-level: 4; -*-
--[[-----------------------------------------------------------------------------
Frame Container
-------------------------------------------------------------------------------]]
local Type, Version = "Frame", 1
local GeminiConfigGUIPkg = Apollo.GetPackage("Gemini:ConfigGUI-1.0")
local GeminiConfigGUI = GeminiConfigGUIPkg and GeminiConfigGUIPkg.tPackage
if not GeminiConfigGUI or (GeminiConfigGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs, assert, type = pairs, assert, type
local wipe = function(tbl)
    for k in pairs(tbl) do
        tbl[k] = nil
    end
end

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: CLOSE

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
    ["OnAcquire"] = function(self)
        self:SetTitle()
        self:SetStatusText()
        self:ApplyStatus()
        self:Show()
        self:EnableResize(true)
    end,

    ["OnRelease"] = function(self)
        self.status = nil
        wipe(self.localstatus)
    end,

    ["SetTitle"] = function(self, title)
        self.titletext:SetText(title or "")
    end,

    ["SetStatusText"] = function(self, text)
        self.statustext:SetText(text or "")
    end,

    ["Hide"] = function(self)
        self.frame:Show(false)
    end,

    ["Show"] = function(self)
        self.frame:Show(true)
    end,

    ["EnableResize"] = function(self, state)
        self.sizer:Show(state)
        self.frame:SetStyle("Sizable", state)
    end,

    -- called to set an external table to store status in
    ["SetStatusTable"] = function(self, status)
        assert(type(status) == "table")
        self.status = status
        self:ApplyStatus()
    end,

    ["ApplyStatus"] = function(self)
        local status = self.status or self.localstatus
        local frame = self.frame
        self:SetWidth(status.width or 700)
        self:SetHeight(status.height or 500)
    end,

    --[[-----------------------------------------------------------------------------
       Scripts
       -------------------------------------------------------------------------------]]
    OnWindowCloseBtn = function(self, wndHandler, wndControl)
        if wndHandler ~= wndControl then return end
        --PlaySound("gsTitleOptionExit")
        self:Hide()
    end,

    OnWindowHide = function(self, wndHandler, wndControl)
        if wndHandler ~= wndControl then return end
        self:Fire("OnClose")
    end,

    OnWindowMouseDown = function()
        GeminiConfigGUI:ClearFocus()
    end,


    --local function MoverSizer_OnMouseUp(mover)
    --	local frame = mover:GetParent()
    --	frame:StopMovingOrSizing()
    --	local self = frame.obj
    --	local status = self.status or self.localstatus
    --	status.width = frame:GetWidth()
    --	status.height = frame:GetHeight()
    --	status.top = frame:GetTop()
    --	status.left = frame:GetLeft()
    --end
    --
    --local function SizerSE_OnMouseDown(frame)
    --	frame:GetParent():StartSizing("BOTTOMRIGHT")
    --	GeminiConfigGUI:ClearFocus()
    --end
    --
    --local function SizerS_OnMouseDown(frame)
    --	frame:GetParent():StartSizing("BOTTOM")
    --	GeminiConfigGUI:ClearFocus()
    --end
    --
    --local function SizerE_OnMouseDown(frame)
    --	frame:GetParent():StartSizing("RIGHT")
    --	GeminiConfigGUI:ClearFocus()
    --end
    --
    OnStatusTextMouseEnter = function(wndHandler)
        wndHandler:Fire("OnEnterStatusBar")
    end,

    OnStatusTextMouseExit = function(wndHandler)
        wndHandler:Fire("OnLeaveStatusBar")
    end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local tGeminiWindowDef = {
    AnchorOffsets = { -400, -300, 400, 300 },
    AnchorPoints = { 0.5, 0.5, 0.5, 0.5 },
    RelativeToClient = true,
    Sprite = "BK3:sprHolo_Alert_Confirm",
    Name = "GeminiWindow",
    SwallowMouseClicks = true,
    Moveable = true,
    Escapable = true,
    Overlapped = true,
    BGColor = "white",
    TextColor = "white",
    Visible = false,
    Sizable = true,
    Scalable = 0,
    TooltipColor = "white",
    TooltipFont = "CRB_InterfaceSmall",
    Events = {
        WindowHide = "OnWindowHide",
        MouseButtonDown = "OnWindowMouseDown",
        WindowSizeChanged = "OnFrameResize",
    },
    Children = {
        {
            AnchorOffsets = { 22, 67, -22, -70 },
            AnchorPoints = { 0, 0, 1, 1 },
            RelativeToClient = true,
            Template = "Holo_Background_General",
            Name = "BGGridArt",
            BGColor = "white",
            TextColor = "white",
            Picture = true,
            IgnoreMouse = true,
            UseTemplateBG = true,
            Border = true,
            Children = {
                {
                    AnchorOffsets = { -2, 2, -2, 2 },
                    AnchorPoints = { 0, 0, 1, 1 },
                    RelativeToClient = true,
                    BGColor = "UI_WindowBGDefault",
                    TextColor = "UI_WindowTextDefault",
                    Name = "Content",
                    Events = {
                        WindowSizeChanged = "OnContentResize",
                    },
                },
            },
        },
        {
            AnchorOffsets = { 61, 22, -61, 59 },
            AnchorPoints = { 0, 0, 1, 0 },
            RelativeToClient = true,
            Name = "Title",
            BGColor = "white",
            TextColor = "white",
            Picture = true,
            IgnoreMouse = true,
            Sprite = "BK3:sprMetal_Framing_Header",
            NewWindowDepth = 1,
            AutoScaleText = true,
            Children = {
                {
                    AnchorOffsets = { 15, 0, -15, 0 },
                    AnchorPoints = { 0, 0, 1, 1 },
                    RelativeToClient = true,
                    Font = "CRB_Header13",
                    Name = "TitleText",
                    BGColor = "white",
                    TextColor = "UI_WindowTitleYellow",
                    DT_CENTER = true,
                    DT_VCENTER = true,
                    IgnoreMouse = true,
                    AutoScaleText = true,
                },
            },
        },
        {
            AnchorOffsets = { 22, -71, -22, -18 },
            AnchorPoints = { 0, 1, 1, 1 },
            RelativeToClient = true,
            Name = "BGBottom",
            BGColor = "white",
            TextColor = "white",
            Picture = true,
            IgnoreMouse = true,
            Pixies = {
                {
                    AnchorOffsets = { 148, 11, -10, -9 },
                    AnchorPoints = { 0, 0, 1, 1 },
                    Sprite = "BK3:UI_BK3_Metal_Inset_SharpCorner",
                    BGColor = "white",
                    TextColor = "black",
                },
            },
            Children = {
                {
                    AnchorOffsets = { 149, 13, -9, -11 },
                    AnchorPoints = { 0, 0, 1, 1 },
                    Class = "Window",
                    RelativeToClient = true,
                    Font = "CRB_HeaderSmall",
                    BGColor = "UI_WindowBGDefault",
                    TextColor = "UI_WindowTextDefault",
                    Name = "StatusText",
                    DT_VCENTER = true,
                    DT_CENTER = true,
                    DT_WORDBREAK = true,
                    MultiLine = false,
                    SizeToFit = true,
                    Events = {
                        MouseEnter = "OnStatusTextMouseEnter",
                        MouseExit = "OnStatusTextMouseEnter",
                    },
                },
            },
        },
        {
            AnchorOffsets = { -6, -6, 6, 6 },
            AnchorPoints = { 0, 0, 1, 1 },
            RelativeToClient = true,
            Name = "BGFrame",
            BGColor = "white",
            TextColor = "white",
            Picture = true,
            IgnoreMouse = true,
            NoClip = true,
            Border = true,
            UseTemplateBG = true,
            NewControlDepth = 5,
        },
        {
            AnchorOffsets = { -52, -54, -1, -3 },
            AnchorPoints = { 1, 1, 1, 1 },
            Name = "BottomRightResize",
            BGColor = "white",
            TextColor = "white",
            Sprite = "CRB_Basekit:kitBtn_ExpandNormal",
            Picture = true,
            IgnoreMouse = true,
            NoClip = true,
        },
        {
            AnchorOffsets = { -50, 23, -23, 52 },
            AnchorPoints = { 1, 0, 1, 0 },
            Class = "Button",
            Base = "CRB_UIKitSprites:btn_close_Hologram",
            Font = "Thick",
            ButtonType = "PushButton",
            DT_VCENTER = true,
            DT_CENTER = true,
            Name = "CloseBtn",
            BGColor = "white",
            TextColor = "white",
            NormalTextColor = "white",
            PressedTextColor = "white",
            FlybyTextColor = "white",
            PressedFlybyTextColor = "white",
            DisabledTextColor = "white",
            Overlapped = true,
            NewWindowDepth = 1,
            Events = {
                ButtonSignal = "OnWindowCloseBtn",
            },
        },
    },
}

local function Constructor(parent)
    local widget = {
        localstatus = {},
        type        = Type
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end
    local frame = Apollo.GetPackage("Gemini:GUI-1.0").tPackage:Create(tGeminiWindowDef):GetInstance(widget, parent)
    frame:Show(false)
    widget.frame = frame
    widget.titletext = frame:FindChild("TitleText")
    widget.statustext = frame:FindChild("StatusText")
    widget.content = frame:FindChild("Content")
    widget.sizer = frame:FindChild("BottomRightResize")
    widget.frame:SetSizingMinimum(600, 400)
    return GeminiConfigGUI:RegisterAsContainer(widget)
end

GeminiConfigGUI:RegisterWidgetType(Type, Constructor, Version)
