local ListSlot = class("elements.element")
local Rect = require("utils.classes.rect")
local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local MEASURES = require("draw.measures")
local ITEM_SIZE = MEASURES.ITEM_SIZE
local FONT = require("draw.fonts").MEDIUM
local DrawCommand = require("utils.love2d.draw_command")
local DrawMethods = require("draw.methods")
local DrawText = require("draw.text")
local drawCommand = DrawCommand:new("items")
local strokeCommand = DrawCommand:new("items_stroke")
local MARGIN = 4
drawCommand.position = Vector:new(MARGIN + 1, MARGIN + 1)
drawCommand:setRectFromDimensions(ITEM_SIZE, ITEM_SIZE)
strokeCommand.position = Vector:new(MARGIN, MARGIN)
strokeCommand:setRectFromDimensions(ITEM_SIZE + 2, ITEM_SIZE + 2)
local HEIGHT = ITEM_SIZE + MARGIN * 2 + 2
local HEIGHT_SMALLER = FONT:getStrokedHeight() + MARGIN * 2 + 6
if PortSettings.IS_MOBILE then
    HEIGHT = HEIGHT + 4
    HEIGHT_SMALLER = HEIGHT_SMALLER + 4
    drawCommand.position = Vector:new(MARGIN + 3, MARGIN + 3)
    strokeCommand.position = Vector:new(MARGIN + 2, MARGIN + 2)
end

local TEXT_Y = (HEIGHT - FONT:getStrokedHeight()) / 2
local TEXT_X = MARGIN * 2 + ITEM_SIZE + TEXT_Y + 2
local TEXT_X_NO_ICON = TEXT_Y - 2
function ListSlot:initialize(width, isSmaller)
    ListSlot:super(self, "initialize")
    self.isActivated = false
    if isSmaller then
        self.rect = Rect:new(0, 0, width, HEIGHT_SMALLER)
    else
        self.rect = Rect:new(0, 0, width, HEIGHT)
    end

    self.icon = false
    self.label = false
    self.roundBottom = false
    self.roundTop = false
    self.textXNoIcon = TEXT_X_NO_ICON
    self.labelColor = COLORS.NORMAL
    self:createInput()
end

function ListSlot:evaluateIsActivated()
    return Utils.evaluate(self.isActivated, self, self.parent)
end

function ListSlot:getIcon()
    return self.icon
end

function ListSlot:getIconStroke()
    return false
end

function ListSlot:getLabel()
    return self.label
end

function ListSlot:getLabelColor()
    return self.labelColor
end

function ListSlot:draw(serviceViewport, timePassed)
    local isActivated = self:evaluateIsActivated()
    local borderColor = COLORS.WINDOW_BORDER
    local highlightOpacity = 0
    highlightOpacity = self.input:getOpacity(false, true)
    if isActivated then
        borderColor = COLORS.LIST_SLOT_SELECTED
        highlightOpacity = 0.9
    end

    if highlightOpacity > 0 then
        graphics.wSetColor(borderColor:expandValues(highlightOpacity / 4))
        graphics.wRectangle(self.rect)
    end

    graphics.wSetFont(FONT)
    local icon = self:getIcon()
    if icon then
        drawCommand:setCell(icon)
        drawCommand:draw()
        local iconStrokeColor = self:getIconStroke()
        if iconStrokeColor then
            strokeCommand:setCell(icon)
            strokeCommand.color = iconStrokeColor
            strokeCommand:draw()
        end

    end

    graphics.wSetColor(self:getLabelColor())
    local textY = (self.rect.height - FONT:getStrokedHeight()) / 2
    if icon then
        DrawText.drawStroked(self:getLabel(), TEXT_X, textY)
    else
        DrawText.drawStroked(self:getLabel(), self.textXNoIcon, textY)
    end

    if highlightOpacity > 0 then
        graphics.wSetColor(borderColor:expandValues(highlightOpacity * 2 / 3))
        DrawMethods.lineRect(self.rect:sizeAdjusted(-1))
        graphics.wSetColor(borderColor:expandValues(highlightOpacity / 3))
        DrawMethods.lineRect(self.rect:sizeAdjusted(-2))
    end

    graphics.wSetColor(borderColor)
    if self.roundBottom or self.roundTop then
        DrawMethods.lineClippedRect(self.rect, 1, self.roundBottom, self.roundTop)
    else
        DrawMethods.lineRect(self.rect)
    end

    if icon then
        graphics.wRectangle(self.rect.height - 1, 0, 1, self.rect.height - 1)
    end

end

return ListSlot

