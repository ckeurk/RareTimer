-- -*- lua-indent-level: 4; -*-
--[[-----------------------------------------------------------------------------
   DropdownGroup Container
   Container controlled by a dropdown on the top.
   -------------------------------------------------------------------------------]]
local Type, Version = "DropdownGroup", 21
local GeminiConfigGUIPkg = Apollo.GetPackage("Gemini:ConfigGUI-1.0")
local GeminiConfigGUI = GeminiConfigGUIPkg and GeminiConfigGUIPkg.tPackage
if not GeminiConfigGUI or (GeminiConfigGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local assert, pairs, type = assert, pairs, type

--[[-----------------------------------------------------------------------------
   Scripts
   -------------------------------------------------------------------------------]]
local function SelectedGroup(self, event, value)
    local group = self.parentgroup
    local status = group.status or group.localstatus
    status.selected = value
    self.parentgroup:Fire("OnGroupSelected", value)
end

--[[-----------------------------------------------------------------------------
   Methods
   -------------------------------------------------------------------------------]]
local methods = {
    ["OnAcquire"] = function(self)
        self.dropdown:SetText("")
        self:SetTitle("")
    end,
    ["OnRelease"] = function(self)
        self.dropdown.list = nil
        self.status = nil
        for k in pairs(self.localstatus) do
            self.localstatus[k] = nil
        end
    end,

    ["SetTitle"] = function(self, title)
        self.titletext:SetText(title or "")
        if title and title ~= "" then
            -- self.dropdown.frame:SetPoint("TOPRIGHT", -2, 0)
        else
            -- self.dropdown.frame:SetPoint("TOPLEFT", -1, 0)
        end
    end,

    ["SetGroupList"] = function(self, list, order)
        Print("Change group list.")
        self.dropdown:SetList(list, order)
    end,

    ["SetStatusTable"] = function(self, status)
        assert(type(status) == "table")
        self.status = status
    end,

    ["SetGroup"] = function(self, group)
        self.dropdown:SetValue(group)
        local status = self.status or self.localstatus
        status.selected = group
        self:Fire("OnGroupSelected", group)
    end,

    ["SetDropdownWidth"] = function(self, width)
        self.dropdown:SetWidth(width)
    end
}

--[[-----------------------------------------------------------------------------
   Constructor
   -------------------------------------------------------------------------------]]
local tGeminiDropDownGroupDef = {
    AnchorOffsets = { 0, 0, 600, 400 },
    RelativeToClient = true,
    BGColor = "UI_WindowBGDefault",
    TextColor = "UI_WindowTextDefault",
    Name = "GeminiDropDownGroup",
    Border = true,
    SwallowMouseClicks = true,
    Escapable = true,
    Overlapped = true,
    UseTemplateBG = true,
    Children = {
        {
            AnchorOffsets = { 7, 2, -7, 23 },
            AnchorPoints = "HFILL",
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
        },
        {
            AnchorOffsets = { 4, 67, -4, 0 },
            AnchorPoints = "FILL",
            RelativeToClient = true,
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Name = "Content",
        },
        {
            AnchorOffsets = { 5, 8, 257, 65 },
            RelativeToClient = true,
            Name = "GeminiDropDown",
            BGColor = "white",
            TextColor = "white",
            Picture = true,
            IgnoreMouse = true,
            Children = {
                {
                    AnchorOffsets = { 2, 0, -2, -35 },
                    AnchorPoints = "FILL",
                    RelativeToClient = true,
                    Font = "CRB_Header13",
                    BGColor = "UI_WindowBGDefault",
                    TextColor = "UI_BtnTextGreenNormal",
                    Name = "Window",
                    DT_VCENTER = true,
                    DT_CENTER = true,
                },
            },
        },
    },
}

local function Constructor(parent)
    local widget = {
        type        = Type,
        localstatus = {},
    }
    local frame = Apollo.GetPackage("Gemini:GUI-1.0").tPackage:Create(tGeminiDropDownGroupDef):GetInstance(widget, parent)
    local dropdown = GeminiConfigGUI:Create("Dropdown", frame)
    dropdown.frame:SetAnchorOffsets(5, 8, 257, 65)
    dropdown:SetLabel("")
    dropdown:SetCallback("OnValueChanged", SelectedGroup)

    widget.frame = frame
    widget.dropdown = dropdown
    widget.titletext = frame:FindChild("Label")
    widget.content = frame:FindChild("Content")

    for method, func in pairs(methods) do
        widget[method] = func
    end
    dropdown.parentgroup = widget

    return GeminiConfigGUI:RegisterAsContainer(widget)
end

GeminiConfigGUI:RegisterWidgetType(Type, Constructor, Version)
