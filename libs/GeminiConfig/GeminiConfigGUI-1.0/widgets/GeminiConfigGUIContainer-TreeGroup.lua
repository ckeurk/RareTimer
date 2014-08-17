-- -*- lua-indent-level: 4; -*-
--[[-----------------------------------------------------------------------------
   TreeGroup Container
   Container that uses a tree control to switch between groups.
   -------------------------------------------------------------------------------]]
local Type, Version = "TreeGroup", 36
local GeminiConfigGUIPkg = Apollo.GetPackage("Gemini:ConfigGUI-1.0")
local GeminiConfigGUI = GeminiConfigGUIPkg and GeminiConfigGUIPkg.tPackage
if not GeminiConfigGUI or (GeminiConfigGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local next, pairs, ipairs, assert, type = next, pairs, ipairs, assert, type
local math_min, math_max, floor = math.min, math.max, floor
local select, tremove, unpack, tconcat = select, table.remove, unpack, table.concat


-- Recycling functions
local new, del
do
    local pool = setmetatable({}, { __mode = 'k' })
    function new()
        local t = next(pool)
        if t then
            pool[t] = nil
            return t
        else
            return {}
        end
    end

    function del(t)
        for k in pairs(t) do
            t[k] = nil
        end
        pool[t] = true
    end
end

local DEFAULT_TREE_WIDTH = 175
local DEFAULT_TREE_SIZABLE = true

--[[-----------------------------------------------------------------------------
   Support functions
   -------------------------------------------------------------------------------]]
local function GetButtonUniqueValue(line)
    local parent = line.parent
    if parent and parent.value then
        return GetButtonUniqueValue(parent) .. "\001" .. line.value
    else
        return line.value
    end
end

local function ShouldDisplayLevel(tree)
    local result = false
    for k, v in ipairs(tree) do
        if v.children == nil and v.visible ~= false then
            result = true
        elseif v.children then
            result = result or ShouldDisplayLevel(v.children)
        end
        if result then return result end
    end
    return false
end

local function addLine(self, v, tree, level, parent)
    local line = new()
    line.value = v.value
    line.text = v.text
    line.icon = v.icon
    line.iconCoords = v.iconCoords
    line.disabled = v.disabled
    line.tree = tree
    line.level = level
    line.parent = parent
    line.visible = v.visible
    line.uniquevalue = GetButtonUniqueValue(line)
    if v.children then
        line.hasChildren = true
    else
        line.hasChildren = nil
    end
    local nodeId = self.treeframe:AddNode(line.parent and line.parent.id or 0, line.text)
    self.lines[nodeId] = line
    if line.icon then
        self.treeframe:SetNodeImage(nodeId, line.icon)
    end
    line.id = nodeId
    return line
end

--fire an update after one frame to catch the treeframes height
local function FirstFrameUpdate(frame)
    local self = frame.obj
    frame:SetScript("OnUpdate", nil)
    self:RefreshTree()
end

local function BuildUniqueValue(...)
    local n = select('#', ...)
    if n == 1 then
        return ...
    else
        return (...) .. "\001" .. BuildUniqueValue(select(2, ...))
    end
end

--[[-----------------------------------------------------------------------------
   Scripts
   -------------------------------------------------------------------------------]]

local function Button_OnDoubleClick(self, handler, button)
    if handler ~= button then return end
    local status = self.status or self.localstatus
    local status = (self.status or self.localstatus).groups
    status[button.uniquevalue] = not status[button.uniquevalue]
    --   self.treeframe:RefreshTree()
end

local function Button_OnEnter(frame)
    local self = frame.obj
    self:Fire("OnButtonEnter", frame.uniquevalue, frame)

    if self.enabletooltips then
        GameTooltip:SetOwner(frame, "ANCHOR_NONE")
        GameTooltip:SetPoint("LEFT", frame, "RIGHT")
        GameTooltip:SetText(frame.text:GetText() or "", 1, .82, 0, 1)

        GameTooltip:Show()
    end
end

local function Button_OnLeave(frame)
    local self = frame.obj
    self:Fire("OnButtonLeave", frame.uniquevalue, frame)

    if self.enabletooltips then
        GameTooltip:Hide()
    end
end

local function OnScrollValueChanged(frame, value)
    if frame.obj.noupdate then return end
    local self = frame.obj
    local status = self.status or self.localstatus
    status.scrollvalue = floor(value + 0.5)
    self:RefreshTree()
    GeminiConfigGUI:ClearFocus()
end

local function Tree_OnSizeChanged(frame)
    frame.obj:RefreshTree()
end

local function Tree_OnMouseWheel(frame, delta)
    local self = frame.obj
    if self.showscroll then
        local scrollbar = self.scrollbar
        local min, max = scrollbar:GetMinMaxValues()
        local value = scrollbar:GetValue()
        local newvalue = math_min(max, math_max(min, value - delta))
        if value ~= newvalue then
            scrollbar:SetValue(newvalue)
        end
    end
end

local function Dragger_OnLeave(frame)
    frame:SetBackdropColor(1, 1, 1, 0)
end

local function Dragger_OnEnter(frame)
    frame:SetBackdropColor(1, 1, 1, 0.8)
end

local function Dragger_OnMouseDown(frame)
    local treeframe = frame:GetParent()
    treeframe:StartSizing("RIGHT")
end

local function Dragger_OnMouseUp(frame)
    local treeframe = frame:GetParent()
    local self = treeframe.obj
    local frame = treeframe:GetParent()
    treeframe:StopMovingOrSizing()
    --treeframe:SetScript("OnUpdate", nil)
    treeframe:SetUserPlaced(false)
    --Without this :GetHeight will get stuck on the current height, causing the tree contents to not resize
    treeframe:SetHeight(0)
    treeframe:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    treeframe:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)

    local status = self.status or self.localstatus
    status.treewidth = treeframe:GetWidth()

    treeframe.obj:Fire("OnTreeResize", treeframe:GetWidth())
    -- recalculate the content width
    treeframe.obj:OnWidthSet(status.fullwidth)
    -- update the layout of the content
    treeframe.obj:DoLayout()
end

--[[-----------------------------------------------------------------------------
   Methods
   -------------------------------------------------------------------------------]]
local methods = {
    ["OnAcquire"] = function(self)
        self:SetTreeWidth(DEFAULT_TREE_WIDTH, DEFAULT_TREE_SIZABLE)
        self:EnableButtonTooltips(true)
    end,

    ["OnRelease"] = function(self)
        self.status = nil
        for k, v in pairs(self.localstatus) do
            if k == "groups" then
                for k2 in pairs(v) do
                    v[k2] = nil
                end
            else
                self.localstatus[k] = nil
            end
        end
        self.localstatus.scrollvalue = 0
        self.localstatus.treewidth = DEFAULT_TREE_WIDTH
        self.localstatus.treesizable = DEFAULT_TREE_SIZABLE
    end,

    ["EnableButtonTooltips"] = function(self, enable)
        self.enabletooltips = enable
    end,

    ["CreateButton"] = function(self)
    --		local num = GeminiConfigGUI:GetNextWidgetNum("TreeGroupButton")
    --		local button = CreateFrame("Button", ("GeminiConfigGUI30TreeButton%d"):format(num), self.treeframe, "OptionsListButtonTemplate")
    --		button.obj = self
    --
    --		local icon = button:CreateTexture(nil, "OVERLAY")
    --		icon:SetWidth(14)
    --		icon:SetHeight(14)
    --		button.icon = icon
    --
    --		button:SetScript("OnClick",Button_OnClick)
    --		button:SetScript("OnDoubleClick", Button_OnDoubleClick)
    --		button:SetScript("OnEnter",Button_OnEnter)
    --		button:SetScript("OnLeave",Button_OnLeave)
    --
    --		button.toggle.button = button
    --		button.toggle:SetScript("OnClick",Expand_OnClick)
    --
        return button
    end,

    ["SetStatusTable"] = function(self, status)
        assert(type(status) == "table")
        self.status = status
        if not status.groups then
            status.groups = {}
        end
        if not status.scrollvalue then
            status.scrollvalue = 0
        end
        if not status.treewidth then
            status.treewidth = DEFAULT_TREE_WIDTH
        end
        if status.treesizable == nil then
            status.treesizable = DEFAULT_TREE_SIZABLE
        end
        self:SetTreeWidth(status.treewidth, status.treesizable)
        self:RefreshTree()
    end,

    --sets the tree to be displayed
    ["SetTree"] = function(self, tree, filter)
        self.filter = filter
        if tree then
            assert(type(tree) == "table")
        end
        self.tree = tree
        self:RefreshTree()
    end,

    ["BuildLevel"] = function(self, tree, level, parent)
        local groups = (self.status or self.localstatus).groups
        local hasChildren = self.hasChildren
        --      Print("Building level "..level.." with parent "..tostring(parent and parent.id).." and has children = "..tostring(hasChildren))
        for i, v in ipairs(tree) do
            if v.children then
                --	    Print("Should display level ="..tostring(ShouldDisplayLevel(v.children)))
                if not self.filter or ShouldDisplayLevel(v.children) then
                    local line = addLine(self, v, tree, level, parent)
                    self:BuildLevel(v.children, level + 1, line)
                    if not groups[line.uniquevalue] then
                        self.treeframe:CollapseNode(line.id)
                    end
                end
            elseif v.visible ~= false or not self.filter then
                addLine(self, v, tree, level, parent)
            end
        end
    end,

    ["RefreshTree"] = function(self, scrollToSelection)

        local treeframe = self.treeframe
        local lines = self.lines
        for k, t in pairs(lines) do
            --	 Print("Removing node "..tostring(t.id))
            if not t.parent then
                treeframe:DeleteNode(t.id)
            end
            for k in pairs(t) do
                t[k] = nil
            end
            del(t)
            lines[k] = nil
        end

        if not self.tree then return end
        --Build the list of visible entries from the tree and status tables
        local status = self.status or self.localstatus
        local groupstatus = status.groups
        local tree = self.tree

        status.scrollToSelection = status.scrollToSelection or scrollToSelection -- needs to be cached in case the control hasn't been drawn yet (code bails out below)

        self:BuildLevel(tree, 1)

        local numlines = #lines

    --		local maxlines = (floor(((self.treeframe:GetHeight()or 0) - 20 ) / 18))
    --		if maxlines <= 0 then return end

    --		local first, last

    --		scrollToSelection = status.scrollToSelection
    --		status.scrollToSelection = nil
    end,

    ["SetSelected"] = function(self, value)
        local status = self.status or self.localstatus
        if status.selected ~= value then
            status.selected = value
            self:Fire("OnGroupSelected", value)
        end
    end,

    ["Select"] = function(self, uniquevalue, ...)
        self.filter = false
        local status = self.status or self.localstatus
        local groups = status.groups
        local path = { ... }
        for i = 1, #path do
            groups[tconcat(path, "\001", 1, i)] = true
        end
        status.selected = uniquevalue
        self:RefreshTree(true)
        self:Fire("OnGroupSelected", uniquevalue)
    end,

    ["SelectByPath"] = function(self, ...)
        self:Select(BuildUniqueValue(...), ...)
    end,

    ["SelectByValue"] = function(self, uniquevalue)
        self:Select(uniquevalue, GeminiConfigGUI:split(uniquevalue, "\001"))
    end,

    ["ShowScroll"] = function(self, show)
        self.showscroll = show
        if show then
            self.scrollbar:Show()
            if self.buttons[1] then
                self.buttons[1]:SetPoint("TOPRIGHT", self.treeframe, "TOPRIGHT", -22, -10)
            end
        else
            self.scrollbar:Hide()
            if self.buttons[1] then
                self.buttons[1]:SetPoint("TOPRIGHT", self.treeframe, "TOPRIGHT", 0, -10)
            end
        end
    end,

    ["OnWidthSet"] = function(self, width)
        local content = self.content
        local treeframe = self.treeframe
        local status = self.status or self.localstatus
        status.fullwidth = width

        local contentwidth = width - status.treewidth - 20
        if contentwidth < 0 then
            contentwidth = 0
        end
        --content:SetWidth(contentwidth)
        --		content.width = contentwidth

        local maxtreewidth = math_min(400, width - 50)

        if maxtreewidth > 100 and status.treewidth > maxtreewidth then
            self:SetTreeWidth(maxtreewidth, status.treesizable)
        end
    --		treeframe:SetMaxResize(maxtreewidth, 1600)
    end,

    ["OnHeightSet"] = function(self, height)
    end,

    ["SetTreeWidth"] = function(self, treewidth, resizable)
        if not resizable then
            if type(treewidth) == 'number' then
                resizable = false
            elseif type(treewidth) == 'boolean' then
                resizable = treewidth
                treewidth = DEFAULT_TREE_WIDTH
            else
                resizable = false
                treewidth = DEFAULT_TREE_WIDTH
            end
        end
        local left, top, right, bottom = self.treecontainer:GetAnchorOffsets()
        local treeRight = left + treewidth
        self.treecontainer:SetAnchorOffsets(left, top, treeRight, bottom)
        local _, top, right, bottom = self.content:GetAnchorOffsets()
        self.content:SetAnchorOffsets(treeRight + 6, top, right, bottom)

        --		self.dragger:EnableMouse(resizable)

        local status = self.status or self.localstatus
        status.treewidth = treewidth
        status.treesizable = resizable

        -- recalculate the content width
        if status.fullwidth then
            self:OnWidthSet(status.fullwidth)
        end
    end,

    ["GetTreeWidth"] = function(self)
        local status = self.status or self.localstatus
        return status.treewidth or DEFAULT_TREE_WIDTH
    end,

    LayoutFinished = function(self, width, height)
        self.treeframe:DeleteNode(self.treeframe:AddNode(0, "bugfix"))
    end,

    OnTreeNodeSelectionChanged = function(self, wndHandler, wndControl, selectedNode)
        if wndHandler ~= wndControl then return end
        local line = self.lines[selectedNode]
       -- Print("Selection = " .. selectedNode .. " out of " .. #self.lines)
        self:Fire("OnClick", line.uniquevalue, line.selected)
       -- if not line.selected then
            self:SetSelected(line.uniquevalue)
            line.selected = true
            --    frame:LockHighlight()
            --      self:RefreshTree()
        --end
        GeminiConfigGUI:ClearFocus()
    end
}

--[[-----------------------------------------------------------------------------
   Constructor
   -------------------------------------------------------------------------------]]
local tGeminiTreeGroupDef = {
    AnchorOffsets = { 0, 0, 400, 200 },
    RelativeToClient = true,
    BGColor = "UI_WindowBGDefault",
    TextColor = "UI_WindowTextDefault",
    Template = "CRB_Scroll_HoloSmall",
    Name = "GeminiTreeGroup",
    IgnoreMouse = true,
    UseTemplateBG = true,
    Border = true,
    Events = {
        WindowSizeChanged = "OnFrameResize",
    },
    Children = {
        {
            AnchorOffsets = { 192, 0, 0, 0 },
            AnchorPoints = "FILL",
            RelativeToClient = true,
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Template = "Holo_ScrollList",
            Name = "Content",
            IgnoreMouse = true,
            UseTemplateBG = true,
            Border = true,
            Events = {
                WindowSizeChanged = "OnContentResize",
            },
        },
        {
            AnchorOffsets = { 0, 0, 186, 0 },
            AnchorPoints = "VFILL",
            RelativeToClient = true,
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Name = "TreeContainer",
            IgnoreMouse = true,
            Children = {
                {
                    AnchorOffsets = { -9, -8, 12, 12 },
                    AnchorPoints = "VFILLRIGHT",
                    RelativeToClient = true,
                    BGColor = "5fffffa0",
                    TextColor = "UI_WindowTextDefault",
                    Name = "Dragger",
                    IgnoreMouse = true,
                    NoClip = true,
                    Sprite = "Crafting_CircuitSprites:sprCircuit_Line_WhiteVertical",
                    Picture = true,
                },
                {
                    AnchorOffsets = { 0, 0, 2, 0 },
                    AnchorPoints = "FILL",
                    Class = "TreeControl",
                    RelativeToClient = true,
                    Font = "CRB_Pixel",
                    BGColor = "UI_WindowBGDefault",
                    TextColor = "UI_WindowTextDefault",
                    Template = "Holo_ScrollList",
                    Name = "TreeFrame",
                    VScroll = true,
                    UseTemplateBG = true,
                    Border = true,
                    AutoHideScroll = true,
                    Events = {
                        TreeDoubleClick = "OnTreeNodeDoubleClick",
                        TreeSelectionChanged = "OnTreeNodeSelectionChanged",
                    },
                },
            },
        },
    },
}


local function Constructor(parent)
    local widget = {
        lines       = {},
        levels      = {},
        buttons     = {},
        hasChildren = {},
        localstatus = { groups = {}, scrollvalue = 0 },
        filter      = false,
        type        = Type
    }
    local frame = Apollo.GetPackage("Gemini:GUI-1.0").tPackage:Create(tGeminiTreeGroupDef):GetInstance(widget, parent)

    widget.treecontainer = frame:FindChild("TreeContainer")
    widget.treeframe = frame:FindChild("TreeFrame")
    widget.content = frame:FindChild("Content")
    widget.dragger = frame:FindChild("Dragger")
    widget.frame = frame

    for method, func in pairs(methods) do
        widget[method] = func
    end
    return GeminiConfigGUI:RegisterAsContainer(widget)
end

GeminiConfigGUI:RegisterWidgetType(Type, Constructor, Version)
