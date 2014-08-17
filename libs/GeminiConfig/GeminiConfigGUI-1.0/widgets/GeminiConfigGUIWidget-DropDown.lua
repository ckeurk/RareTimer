-- -*- lua-indent-level: 4; -*-
--[[ $Id: GeminiConfigGUIWidget-DropDown.lua 1101 2013-10-25 12:46:47Z nevcairiel $ ]] --
local GeminiConfigGUIPkg = Apollo.GetPackage("Gemini:ConfigGUI-1.0")
local GeminiConfigGUI = GeminiConfigGUIPkg and GeminiConfigGUIPkg.tPackage
if not GeminiConfigGUI then return end

-- Lua APIs
local min, max, floor = math.min, math.max, math.floor
local select, pairs, ipairs, type = select, pairs, ipairs, type
local tsort = table.sort

-- WoW APIs
local _G = _G
local xpcall = xpcall
local tLibError = Apollo.GetPackage("Gemini:LibError-1.0")
local error = tLibError and tLibError.tPackage and tLibError.tPackage.Error or Print


do
    local widgetType = "Dropdown"
    local widgetVersion = 1

    --[[ Static data ]] --

    --[[ UI event handler ]] --

    local function Control_OnEnter(self, wndHandler, wndControl)
        if wndControl ~= wndHandler then return end
        self:Fire("OnEnter")
    end

    local function Control_OnLeave(self, wndHandler, wndControl)
        if wndControl ~= wndHandler then return end
        self:Fire("OnLeave")
    end

    local function ShowMultiText(self)
        local text
        for i, widget in self.pullout:IterateItems() do
            if widget.type == "Dropdown-Item-Toggle" then
                if widget:GetValue() then
                    if text then
                        text = text .. ", " .. widget:GetText()
                    else
                        text = widget:GetText()
                    end
                end
            end
        end
        self:SetText(text)
    end

    local function OnItemValueChanged(self, value, checked)
        if self.multiselect then
            self:Fire("OnValueChanged", value, checked)
            ShowMultiText(self)
        else
            if checked then
                self:SetValue(value)
                self:Fire("OnValueChanged", value)
            else
                self:SetValue(true)
            end
            if self.open then
                self.dropdown:Show(false)
            end
        end
    end

    --[[ Exported methods ]] --

    -- exported, GeminiConfigGUI callback
    local function OnAcquire(self)
        self.dropdown:Show(false)
    end

    -- exported, GeminiConfigGUI callback
    local function OnRelease(self)
        if self.open then
            self.dropdown:Show()
        end
        self:SetText("")
        self:SetDisabled(false)
        self:SetMultiselect(false)

        self.value = nil
        self.list = nil
        self.open = nil
        self.hasClose = nil

        self.frame:Show()
    end

    -- exported
    local function SetDisabled(self, disabled)
        self.disabled = disabled
        self.button:Enable(not disabled)
        if disabled then
            self.label:SetTextColor("ff7f7f7f")
        else
            self.label:SetTextColor(ApolloColor.new(1, .82, 0, 1))
        end
    end

    -- exported
    local function ClearFocus(self)
        if self.open then
            self.dropdown:Show(false)
        end
    end

    -- exported
    local function SetText(self, text)
        self.button:SetText(text or "")
    end

    -- exported
    local function SetLabel(self, text)
        if not self.label then return end
        if text and text ~= "" then
            self.label:SetText(text)
            self.label:Show(true)
            --	 self.dropdown:SetPoint("TOPLEFT",self.frame,"TOPLEFT",-15,-14)
            --	 self:SetHeight(40)
            self.alignoffset = 26
        else
            self.label:SetText("")
            self.label:Show()
            --	 self.dropdown:SetPoint("TOPLEFT",self.frame,"TOPLEFT",-15,0)
            --	 self:SetHeight(26)
            self.alignoffset = 12
        end
    end

    -- exported
    local function SetValue(self, value)
        if self.list then
            self:SetText(self.list[value] or "")
        end
        self.value = value
    end

    -- exported
    local function GetValue(self)
        return self.value
    end

    -- exported
    local function SetItemValue(self, item, value)
        if not self.multiselect then return end
        for i, widget in self.pullout:IterateItems() do
            if widget.userdata.value == item then
                if widget.SetValue then
                    widget:SetValue(value)
                end
            end
        end
        ShowMultiText(self)
    end

    -- exported
    local function SetItemDisabled(self, item, disabled)
        for i, widget in self.pullout:IterateItems() do
            if widget.userdata.value == item then
                widget:SetDisabled(disabled)
            end
        end
    end

    local function AddListItem(self, value, text)
        local item
        if self.multiselect then
            item = self.multiButtonTemplate:GetInstance(self, self.container)
        else
            item = self.radioButtonTemplate:GetInstance(self, self.container)
        end
        item:SetText(text)
        item:SetData(value)
    end

    -- exported
    local sortlist = {}
    local function SetList(self, list, order)
        self.list = list
        self.hasClose = nil
        self.container:DestroyChildren()
        if not list then return end

        if type(order) ~= "table" then
            for v in pairs(list) do
                sortlist[#sortlist + 1] = v
            end
            tsort(sortlist)

            for i, key in ipairs(sortlist) do
                AddListItem(self, key, list[key], itemType)
                sortlist[i] = nil
            end
        else
            for i, key in ipairs(order) do
                AddListItem(self, key, list[key], itemType)
            end
        end
        self.container:ArrangeChildrenVert()
    end

    -- exported
    local function AddItem(self, value, text, itemType)
        if self.list then
            self.list[value] = text
            AddListItem(self, value, text, itemType)
        end
    end

    -- exported
    local function SetMultiselect(self, multi)
        if multi == self.multiselect then return end
        self.multiselect = multi
        for _, w in pairs(self.container:GetChildren()) do
            AddListItem(self, w:GetData(), w:GetText())
            w:Destroy()
        end
        self.container:ArrangeChildrenVert()
    end

    -- exported
    local function GetMultiselect(self)
        return self.multiselect
    end

    local function SetPulloutWidth(self, width)
        self.pulloutWidth = width
    end

    local function OnDropdownShow(self)
        local value = self.value

        if not self.multiselect then
            for i, item in ipairs(self.container:GetChildren()) do
                item:SetCheck(item:GetData() == value)
            end
        end
        self.open = true
        self:Fire("OnOpened")
    end

    local function OnDropdownHide(self, wndHandler, wndControl)
        if wndHandler ~= wndControl then return end
        self.open = nil
        self:Fire("OnClosed")
    end


    local function OnDropDownOptionPicked(self, wndHandler, wndControl)
        if wndHandler ~= wndControl then return end
        OnItemValueChanged(self, wndControl:GetData(), wndControl:IsChecked())
    end

    --[[ Constructor ]] --
    local tGeminiDropDownDef = {
        AnchorOffsets = { 0, 0, 252, 59 },
        RelativeToClient = true,
        Name = "GeminiDropDown",
        BGColor = "white",
        TextColor = "white",
        Picture = true,
        Events = {
            MouseEnter = "OnMouseEnter",
            MouseExit = "OnMouseExit",
        },
        Children = {
            {
                Class = "MLWindow",
                AnchorOffsets = { 2, 0, -2, -35 },
                AnchorPoints = "FILL",
                RelativeToClient = true,
                Font = "CRB_Header_Small",
                BGColor = "UI_WindowBGDefault",
                TextColor = "UI_TextHoloTitle",
                Name = "Label",
                DT_VCENTER = true,
                DT_CENTER = true,
            },
            {
                AnchorOffsets = { 0, 23, -20, 0 },
                AnchorPoints = "FILL",
                Class = "Button",
                Base = "CRB_Basekit:kitBtn_Dropdown_TextBaseHolo3",
                Font = "CRB_Button",
                ButtonType = "Check",
                DT_VCENTER = true,
                DT_CENTER = true,
                Name = "DropDownButton",
                BGColor = "white",
                TextColor = "white",
                NormalTextColor = "UI_BtnTextHoloNormal",
                PressedTextColor = "UI_BtnTextHoloPressed",
                FlybyTextColor = "UI_BtnTextHoloFlyby",
                PressedFlybyTextColor = "UI_BtnTextHoloPressedFlyby",
                DisabledTextColor = "UI_BtnTextHoloDisabled",
                Text = "Drop Down Button",
                RadioDisallowNonSelection = false,
                Children = {
                    {
                        AnchorPoints = { 1, 0, 1, 0 },
                        AnchorOffsets = { 0, -30, 360, 160 },
                        RelativeToClient = true,
                        Template = "Holo_Small_YesNoFlyout",
                        Name = "DropDownBackground",
                        BGColor = "white",
                        TextColor = "white",
                        Picture = true,
                        IgnoreMouse = false,
                        NoClip = true,
                        NewWindowDepth = 1,
                        CloseOnExternalClick = true,
                        TestAlpha = true,
                        SwallowMouseClicks = true,
                        Border = true,
                        UseTemplateBG = true,
                        Events = {
                            WindowHide = "OnDropdownHide",
                            WindowShow = "OnDropdownShow",
                        },
                        Children = {
                            {
                                AnchorPoints = "FILL",
                                RelativeToClient = true,
                                NewWindowDepth = 1,
                                BGColor = "UI_WindowBGDefault",
                                TextColor = "UI_WindowTextDefault",
                                Template = "Holo_ScrollListSmall",
                                Name = "ButtonContainer",
                                VScroll = true,
                                IgnoreMouse = false,
                                NoClip = false,
                                AutoHideScroll = true,
                            },
                        },
                    },
                },
            },
        },
    }

    local tMultiButtonTemplate = {
        AnchorOffsets = { 0, 0, 0, 27 },
        AnchorPoints = "HFILL",
        Class = "Button",
        NewWindowDepth = 1,
        Base = "BK3:btnHolo_ListView_Check",
        Font = "CRB_Button",
        ButtonType = "Check",
        DT_VCENTER = true,
        DT_CENTER = true,
        Name = "MultiButtonTemplate",
        BGColor = "white",
        TextColor = "white",
        NormalTextColor = "UI_BtnTextHoloNormal",
        PressedTextColor = "UI_BtnTextHoloPressed",
        FlybyTextColor = "UI_BtnTextHoloFlyby",
        PressedFlybyTextColor = "UI_BtnTextHoloPressedFlyby",
        DisabledTextColor = "UI_BtnTextHoloDisabled",
        RadioDisallowNonSelection = true,
        Events = {
            ButtonCheck = "OnDropDownOptionPicked",
            --ButtonUncheck = "OnDropDownOptionPicked",
        },
    }
    local tRadioButtonTemplate = {
        AnchorOffsets = { 0, 0, 0, 27 },
        AnchorPoints = "HFILL",
        NewWindowDepth = 1,
        Class = "Button",
        Base = "BK3:btnHolo_ListView_Check",
        Font = "CRB_Button",
        ButtonType = "Check",
        DT_VCENTER = true,
        DT_CENTER = true,
        Name = "RadioButtonTemplate",
        BGColor = "white",
        TextColor = "white",
        NormalTextColor = "UI_BtnTextHoloNormal",
        PressedTextColor = "UI_BtnTextHoloPressed",
        FlybyTextColor = "UI_BtnTextHoloFlyby",
        PressedFlybyTextColor = "UI_BtnTextHoloPressedFlyby",
        DisabledTextColor = "UI_BtnTextHoloDisabled",
        RadioDisallowNonSelection = true,
        Events = {
            ButtonCheck = "OnDropDownOptionPicked",
            --ButtonUncheck = "OnDropDownOptionPicked",
        },
    }

    local function Constructor(parent)
        local widget = {
            type       = widgetType,
            radioGroup = "GeminiRadioGroup:" .. GeminiConfigGUI:GetNextWidgetNum(widgetType)
        }
        widget.OnRelease = OnRelease
        widget.OnAcquire = OnAcquire

        widget.ClearFocus = ClearFocus

        widget.SetText = SetText
        widget.SetValue = SetValue
        widget.GetValue = GetValue
        widget.SetList = SetList
        widget.SetLabel = SetLabel
        widget.SetDisabled = SetDisabled
        widget.AddItem = AddItem
        widget.SetMultiselect = SetMultiselect
        widget.GetMultiselect = GetMultiselect
        widget.SetItemValue = SetItemValue
        widget.SetItemDisabled = SetItemDisabled
        widget.SetPulloutWidth = SetPulloutWidth
        widget.OnMouseExit = Control_OnLeave
        widget.OnMouseEnter = Control_OnEnter
        widget.OnDropdownHide = OnDropdownHide
        widget.OnDropDownOptionPicked = OnDropDownOptionPicked
        widget.OnDropdownShow = OnDropdownShow

        local ggui = Apollo.GetPackage("Gemini:GUI-1.0").tPackage
        local frame = ggui:Create(tGeminiDropDownDef):GetInstance(widget, parent)
        widget.multiButtonTemplate = ggui:Create(tMultiButtonTemplate)
        tRadioButtonTemplate.RadioGroup = widget.radioGroup
        widget.radioButtonTemplate = ggui:Create(tRadioButtonTemplate)

        widget.dropdown = frame:FindChild("DropDownBackground")
        widget.container = frame:FindChild("ButtonContainer")
        widget.label = frame:FindChild("Label")
        widget.button = frame:FindChild("DropDownButton")
        widget.frame = frame

        widget.button:AttachWindow(widget.dropdown)

        GeminiConfigGUI:RegisterAsWidget(widget)
        return widget
    end

    GeminiConfigGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)
end
