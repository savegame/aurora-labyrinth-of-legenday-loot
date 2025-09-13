local WindowLogItem = class("widgets.window_item")
local Vector = require("utils.classes.vector")
local MEASURES = require("draw.measures")
local COLORS = require("draw.colors")
local SHADERS = require("draw.shaders")
local FONT = require("draw.fonts").MEDIUM
local function onButtonClose(button, widget)
    widget.director:publish(Tags.UI_CLEAR)
    widget.director:publish(Tags.UI_TITLE_BACK)
end

function WindowLogItem:initialize(director, item, parentWindow, discoverState)
    self.discoverState = discoverState
    WindowLogItem:super(self, "initialize", director, item, false, true)
    self.buttonClose.input.onRelease = onButtonClose
    self.parentWindow = parentWindow
    self.window.rect.height = 185
    self.alignment = CENTER
    self.alignHeight = parentWindow.window.rect.height
    self.position = Vector:new(MEASURES.MARGIN_SCREEN, MEASURES.MARGIN_SCREEN)
    self.isVisible = function(self)
        return self.parentWindow:evaluateIsVisible()
    end
end

function WindowLogItem:update(dt, serviceViewport)
    WindowLogItem:super(self, "update", dt, serviceViewport)
    self.alignWidth = self.window.rect.width * 2 - self.parentWindow.alignWidth
end

function WindowLogItem:getWindowTitle()
    if self.discoverState == -1 then
        return "???"
    else
        return WindowLogItem:super(self, "getWindowTitle")
    end

end

function WindowLogItem:addPassiveDescription(currentY,...)
    if self.discoverState == -1 then
        return currentY
    else
        return WindowLogItem:super(self, "addPassiveDescription", currentY, ...)
    end

end

function WindowLogItem:addStatLines(currentY,...)
    if self.discoverState == -1 then
        return currentY
    else
        return WindowLogItem:super(self, "addStatLines", currentY, ...)
    end

end

function WindowLogItem:addAbilityElements(currentY,...)
    if self.discoverState == -1 then
        return currentY
    else
        return WindowLogItem:super(self, "addAbilityElements", currentY, ...)
    end

end

function WindowLogItem:addExtraDescription(currentY, startingX, textX)
    if self.discoverState == -1 then
        currentY = currentY + MEASURES.MARGIN_INTERNAL + 2
        local descElement = self:addElement("text_wrapped", textX, currentY, MEASURES.WIDTH_ITEM_WINDOW - textX * 2, "???", FONT)
        return currentY + descElement.rect.height + MEASURES.MARGIN_INTERNAL + 1
    else
        return currentY
    end

end

function WindowLogItem:decorateTitleIcon(itemIcon)
    if self.discoverState == -1 then
        itemIcon:setShader(SHADERS.SILHOUETTE)
        itemIcon:setColor(COLORS.UNDISCOVERED_ITEM)
    end

end

function WindowLogItem:receiveMessage(message)
    if message == Tags.UI_CLEAR then
    end

end

return WindowLogItem

