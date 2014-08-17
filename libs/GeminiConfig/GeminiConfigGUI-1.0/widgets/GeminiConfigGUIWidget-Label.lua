-- -*- lua-indent-level: 4; -*-
--[[-----------------------------------------------------------------------------
   Label Widget
   Displays text and optionally an icon.
   -------------------------------------------------------------------------------]]
local Type, Version = "Label", 23
local GeminiConfigGUIPkg = Apollo.GetPackage("Gemini:ConfigGUI-1.0")
local GeminiConfigGUI = GeminiConfigGUIPkg and GeminiConfigGUIPkg.tPackage
if not GeminiConfigGUI or (GeminiConfigGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local max, select, pairs = math.max, select, pairs

--[[-----------------------------------------------------------------------------
   Support functions
   -------------------------------------------------------------------------------]]

local function UpdateImageAnchor(self)
    if self.resizing then return end
    local frame = self.frame
    local width = frame:GetWidth() or 0
    local image = self.image
    local label = self.label
    local height
    local imagewidth = self.imageWidth or 0
    self.label:SetAnchorPoints(0, 0, 0, 0)
    self.label:SetAnchorOffsets(0, 0, width - 4, 1000) -- size way large enough
    local lw, lh = self.label:GetContentSize() -- get actual size
    lh = lh + 10 -- padding
    if self.imageshown and imagewidth > 0 then
        if (width - imagewidth) < 200 or (label:GetText() or "") == "" then
            -- image goes on top centered when less than 200 width for the text, or if there is no text
            image:SetAnchorPoints(0.5, 0, 0.5, 0)
            image:SetAnchorOffsets(-imagewidth / 2, 0, imagewidth / 2, self.imageHeight)
            label:SetAnchorPoints(0, 0, 1, 1)
            label:SetAnchorOffsets(0, self.imageHeight, 0, 0)
            height = image:GetHeight() + lh
        else
            -- image on the left
            image:SetAnchorPoints(0, 0.5, 0, 0.5)
            image:SetAnchorOffsets(0, -self.imageHeight / 2, imagewidth, self.imageHeight / 2)
            label:SetAnchorPoints(0, 0, 1, 1)
            label:SetAnchorOffsets(self.imagewidth + 4, 0, 0, 0)
            height = max(image:GetHeight(), lh)
        end
    else
        -- no image shown
        label:SetAnchorPoints(0, 0, 1, 1)
        label:SetAnchorOffsets(0, 0, 0, 0)
        height = lh
    end
    self.resizing = true
    self:SetHeight(height)
    self.resizing = nil
end

--[[-----------------------------------------------------------------------------
   Methods
   -------------------------------------------------------------------------------]]
local methods = {
    ["OnAcquire"] = function(self)
    -- set the flag to stop constant size updates
        self.resizing = true
        -- height is set dynamically by the text and image size
        self:SetText()
        self:SetImage(nil)
        self:SetImageSize(16, 16)
        self:SetColor()
        -- reset the flag
        self.resizing = nil
        -- run the update explicitly
        UpdateImageAnchor(self)
    end,

    -- ["OnRelease"] = nil,

    ["OnWidthSet"] = function(self, width)
        UpdateImageAnchor(self)
    end,

    ["SetText"] = function(self, text)
        self.label:SetText(text or "")
        UpdateImageAnchor(self)
    end,

    ["SetColor"] = function(self, r, g, b)
        if not (r and g and b) then
            r, g, b = 1, 1, 1
        end
        self.label:SetTextColor(ApolloColor.new(r, g, b, 1))
    end,

    ["SetImage"] = function(self, path, ...)
        local image = self.image
        image:SetSprite(path)

        if path and image:GetSprite() then
            self.imageshown = true
        else
            self.imageshown = nil
        end
        UpdateImageAnchor(self)
    end,

    ["SetFont"] = function(self, font)
        self.font = font
        self.label:SetFont(font)
    end,

    ["SetImageSize"] = function(self, width, height)
        self.imageWidth = width
        self.imageHeight = height
        UpdateImageAnchor(self)
    end,
}

--[[-----------------------------------------------------------------------------
   Constructor
   -------------------------------------------------------------------------------]]
local tGeminiLabelDef = {
    AnchorOffsets = { 0, 1, 300, 30 },
    RelativeToClient = true,
    BGColor = "UI_WindowBGDefault",
    TextColor = "UI_WindowTextDefault",
    Name = "GeminiLabel",
    Border = true,
    Picture = true,
    SwallowMouseClicks = true,
    Moveable = false,
    Escapable = true,
    Overlapped = true,
    Children = {
        {
            AnchorOffsets = { 32, 0, 155, 30 },
            Class = "MLWindow",
            RelativeToClient = true,
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Name = "Label",
            Border = true,
            Picture = true,
            SwallowMouseClicks = true,
            Overlapped = true,
        },
        {
            AnchorOffsets = { 0, 0, 30, 30 },
            RelativeToClient = true,
            BGColor = "UI_WindowBGDefault",
            TextColor = "UI_WindowTextDefault",
            Name = "Image",
        },
    },
}

local function Constructor(parent)
    local widget = {
        type = Type
    }

    local frame = Apollo.GetPackage("Gemini:GUI-1.0").tPackage:Create(tGeminiLabelDef):GetInstance(widget, parent)

    -- create widget
    widget.frame = frame
    widget.label = frame:FindChild("Label")
    widget.image = frame:FindChild("Image")
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return GeminiConfigGUI:RegisterAsWidget(widget)
end

GeminiConfigGUI:RegisterWidgetType(Type, Constructor, Version)
