-- -*- lua-indent-level: 4; -*-
--[[-----------------------------------------------------------------------------
EditBox Widget
-------------------------------------------------------------------------------]]
local Type, Version = "EditBox", 25
local GeminiConfigGUIPkg = Apollo.GetPackage("Gemini:ConfigGUI-1.0")
local GeminiConfigGUI = GeminiConfigGUIPkg and GeminiConfigGUIPkg.tPackage
if not GeminiConfigGUI or (GeminiConfigGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local tostring, pairs = tostring, pairs

-- WoW APIs
local PlaySound = PlaySound
local GetCursorInfo, ClearCursor, GetSpellInfo = GetCursorInfo, ClearCursor, GetSpellInfo
local CreateFrame, UIParent = CreateFrame, UIParent
local _G = _G

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: GeminiConfigGUIEditBoxInsertLink, ChatFontNormal, OKAY

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]
if not GeminiConfigGUIEditBoxInsertLink then
    -- upgradeable hook
    --	hooksecurefunc("ChatEdit_InsertLink", function(...) return _G.GeminiConfigGUIEditBoxInsertLink(...) end)
end

function _G.GeminiConfigGUIEditBoxInsertLink(text)
    for i = 1, GeminiConfigGUI:GetWidgetCount(Type) do
        local editbox = _G["Gemini:ConfigGUI-1.0EditBox" .. i]
        if editbox and editbox:IsVisible() and editbox:HasFocus() then
            editbox:Insert(text)
            return true
        end
    end
end

local function ShowButton(self)
    if not self.disablebutton then
        self.button:Show(true)
        self.editbox:SetAnchorOffsets(2, -31, -30, 0)
    end
end

local function HideButton(self)
    self.button:Show(false)
    self.editbox:SetAnchorOffsets(2, -31, 0, 0)
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

local function Frame_OnShowFocus(frame)
    frame.obj.editbox:SetFocus()
    frame:SetScript("OnShow", nil)
end

local function EditBox_OnReceiveDrag(frame)
    local self = frame.obj
    local type, id, info = GetCursorInfo()
    if type == "item" then
        self:SetText(info)
        self:Fire("OnEnterPressed", info)
        ClearCursor()
    elseif type == "spell" then
        local name = GetSpellInfo(id, info)
        self:SetText(name)
        self:Fire("OnEnterPressed", name)
        ClearCursor()
    elseif type == "macro" then
        local name = GetMacroInfo(id)
        self:SetText(name)
        self:Fire("OnEnterPressed", name)
        ClearCursor()
    end
    HideButton(self)
    GeminiConfigGUI:ClearFocus()
end

local function EditBox_OnFocusGained(frame)
    GeminiConfigGUI:SetFocus(frame.obj)
end

local function Button_OnClick(frame)
    local editbox = frame.obj.editbox
    editbox:ClearFocus()
    EditBox_OnEnterPressed(editbox)
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
    ["OnAcquire"] = function(self)
        self:SetDisabled(false)
        self:SetLabel()
        self:SetText()
        self:DisableButton(false)
        self:SetMaxLetters(0)
    end,

    ["OnRelease"] = function(self)
        self:ClearFocus()
    end,

    ["SetDisabled"] = function(self, disabled)
        self.disabled = disabled
        self.editbox:Enable(not disabled)
        if disabled then
            self.editbox:SetTextColor("ff7f7f7f")
            self.label:SetTextColor("ff7f7f7f")
        else
            self.editbox:SetTextColor("ffffffff")
            self.label:SetTextColor("UI_TextHoloTitle")
        end
    end,

    ["SetText"] = function(self, text)
        self.lasttext = text or ""
        self.editbox:SetText(text or "")
        --self.editbox:SetCursorPosition(0)
        HideButton(self)
    end,

    ["GetText"] = function(self, text)
        return self.editbox:GetText()
    end,

    ["SetLabel"] = function(self, text)
        if text and text ~= "" then
            self.label:SetText(text)
            self.label:Show(true)
            self:SetHeight(51)
        else
            self.label:SetText("")
            self.label:Show(false)
            self:SetHeight(31)
        end
    end,

    ["DisableButton"] = function(self, disabled)
        self.disablebutton = disabled
        if disabled then
            HideButton(self)
        end
    end,

    ["SetMaxLetters"] = function(self, num)
        if num and num > 0 then
            self.editbox:SetMaxTextLength(num)
        end
    end,

    ["ClearFocus"] = function(self)
        self.editbox:ClearFocus()
    end,

    ["SetFocus"] = function(self)
        self.editbox:SetFocus()
    end,

    OnEditBoxReturn = function(self, wndHandler, wndControl)
        if wndHandler ~= wndControl then return end
        local value = self.editbox:GetText()
        local cancel = self:Fire("OnEnterPressed", value)
        if not cancel then
            HideButton(self)
        end
    end,

    OnEditBoxChanged = function(self, wndHandler, wndControl)
        if wndHandler ~= wndControl then return end
        local value = wndControl:GetText()
        if tostring(value) ~= tostring(self.lasttext) then
            self:Fire("OnTextChanged", value)
            self.lasttext = value
            ShowButton(self)
        end
    end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local tGeminiEditBoxDef = {
    AnchorOffsets = { 0, 0, 259, 51 },
    RelativeToClient = true,
    BGColor = "UI_WindowBGDefault",
    TextColor = "UI_WindowTextDefault",
    Name = "GeminiEditBox",
    SwallowMouseClicks = true,
    Escapable = true,
    Overlapped = true,
    Children = {
        {
            AnchorOffsets = { 2, -31, -30, 0 },
            AnchorPoints = "HFILLBOTTOM",
            Class = "EditBox",
            RelativeToClient = true,
            Text = "My Edit Box",
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Template = "Holo_InputBox",
            Name = "EditBox",
            Border = true,
            UseTemplateBG = true,
            Escapable = true,
            Events = {
                EditBoxReturn = "OnEditBoxReturn",
                EditBoxChanged = "OnEditBoxChanged",
            },
        },
        {
            AnchorOffsets = { 9, 0, 0, 19 },
            AnchorPoints = "HFILL",
            RelativeToClient = true,
            Font = "CRB_Header_Small",
            Text = "Edit Box Title",
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_TextHoloTitle",
            Name = "Label",
            DT_VCENTER = true,
        },
        {
            AnchorOffsets = { -40, -44, 8, 12 },
            AnchorPoints = "BOTTOMRIGHT",
            Class = "Button",
            Base = "BK3:btnHolo_Blue_Med",
            Font = "DefaultButton",
            ButtonType = "PushButton",
            DT_VCENTER = true,
            DT_CENTER = true,
            NoClip = true,
            BGColor = "UI_BtnBGDefault",
            TextColor = "UI_BtnTextDefault",
            NormalTextColor = "UI_BtnTextDefault",
            PressedTextColor = "UI_BtnTextDefault",
            FlybyTextColor = "UI_BtnTextDefault",
            PressedFlybyTextColor = "UI_BtnTextDefault",
            DisabledTextColor = "UI_BtnTextDefault",
            Name = "OkButton",
            TextId = "EldanAugmentation_Ok",
            Events = {
                ButtonSignal = "OnEditBoxReturn",
            },
        },
    },
}

local function Constructor(parent)
    local widget = {
        type = Type,
    }

    local frame = Apollo.GetPackage("Gemini:GUI-1.0").tPackage:Create(tGeminiEditBoxDef):GetInstance(widget, parent)
    widget.button = frame:FindChild("OkButton")
    widget.label = frame:FindChild("Label")
    widget.editbox = frame:FindChild("EditBox")
    widget.frame = frame

    for method, func in pairs(methods) do
        widget[method] = func
    end
    return GeminiConfigGUI:RegisterAsWidget(widget)
end

GeminiConfigGUI:RegisterWidgetType(Type, Constructor, Version)
