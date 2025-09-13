local Window = class("widgets.widget")
local Vector = require("utils.classes.vector")
local MEASURES = require("draw.measures")
local FONT = require("draw.fonts").MEDIUM
local ITEM_SIZE = MEASURES.ITEM_SIZE
local ITEM_MARGIN = MEASURES.WINDOW_ITEM_MARGIN
local BUTTON_CLOSE_SIZE = require("elements.button_close").SIZE
function Window:initialize(width, height)
    Window:super(self, "initialize")
    self.window = self:addElement("window", 0, 0, width, height or 32)
    self.windowTitle = false
    self.buttonClose = false
    self._titleDivider = false
end

function Window:setWidth(width)
    if self.window.rect.width ~= width then
        self.window.rect.width = width
        if self._titleDivider then
            self._titleDivider.length = width - MEASURES.BORDER_WINDOW * 2
        end

        if self.buttonClose then
            self.buttonClose:setPosition(self:_getButtonClosePosition())
        end

    end

end

function Window:decorateTitleIcon(itemIcon)
end

if PortSettings.IS_MOBILE then
    function Window:moveElementToTop(element)
        Window:super(self, "moveElementToTop", element)
        if self.buttonClose and element ~= self.buttonClose then
            Window:super(self, "moveElementToTop", self.buttonClose)
        end

    end

end

function Window:addTitle(title, icon, iconStrokeColor, noDivider, titleColor)
    local MARGIN_INTERNAL = MEASURES.MARGIN_INTERNAL + 1
    local currentY = MEASURES.BORDER_WINDOW
    local startingX = MEASURES.BORDER_WINDOW
    if not icon then
        self.windowTitle = self:addElement("text", startingX + MARGIN_INTERNAL, currentY + MARGIN_INTERNAL, title, FONT, titleColor or false)
        currentY = currentY + FONT.height + MARGIN_INTERNAL * 2
    else
        local TOP_HEIGHT = ITEM_MARGIN * 2 + ITEM_SIZE
        local MARGIN_TOP = (TOP_HEIGHT - FONT.height) / 2
        local itemIcon = self:addElement("sprite", startingX + ITEM_MARGIN, currentY + ITEM_MARGIN, "items", ITEM_SIZE)
        self:decorateTitleIcon(itemIcon)
        itemIcon:setCell(icon)
        if iconStrokeColor then
            local itemStroke = self:addElement("sprite", startingX + ITEM_MARGIN - 1, currentY + ITEM_MARGIN - 1, "items_stroke", ITEM_SIZE + 2)
            itemStroke:setCell(icon)
            itemStroke:setColor(iconStrokeColor)
        end

        self:addElement("divider", startingX + TOP_HEIGHT, currentY, TOP_HEIGHT, true)
        self.windowTitle = self:addElement("text", startingX + TOP_HEIGHT + MEASURES.BORDER_WINDOW + MARGIN_TOP, currentY + MARGIN_TOP, title, FONT)
        currentY = currentY + TOP_HEIGHT
    end

    if not noDivider then
        self._titleDivider = self:addElement("divider", startingX, currentY, self.window.rect.width - MEASURES.BORDER_WINDOW * 2)
        currentY = currentY + 1
    end

    return currentY
end

function Window:_getButtonClosePosition()
    local TOP_HEIGHT = self.windowTitle.position.y * 2 - MEASURES.BORDER_WINDOW * 2 + FONT.height
    local MARGIN = (TOP_HEIGHT - BUTTON_CLOSE_SIZE) / 2
    return Vector:new(self.window.rect.width - MEASURES.BORDER_WINDOW - MARGIN, MEASURES.BORDER_WINDOW + MARGIN)
end

function Window:addButtonClose()
    local position = self:_getButtonClosePosition()
    self.buttonClose = self:addElement("button_close", position.x, position.y)
    self.buttonClose.input.shortcut = Tags.KEYCODE_CANCEL
    return self.buttonClose
end

return Window

