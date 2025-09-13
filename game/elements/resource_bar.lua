local ResourceBar = class("elements.element")
local Rect = require("utils.classes.rect")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local FONTS = require("draw.fonts")
local FONT = FONTS.SMALL
local DrawMethods = require("draw.methods")
local DrawText = require("draw.text")
ResourceBar.HEIGHT = FONT:getStrokedHeight() + 2 + 4
local BAR_BOTTOM_HEIGHT = 4
if PortSettings.IS_MOBILE then
    FONT = FONTS.MEDIUM
    ResourceBar.HEIGHT = ResourceBar.HEIGHT + 2
    BAR_BOTTOM_HEIGHT = BAR_BOTTOM_HEIGHT + 1
end

local FORMAT = "%d / %d"
local HALF_FORMAT = "/ %d"
function ResourceBar:initialize(width, sourceComponent)
    ResourceBar:super(self, "initialize")
    self.rect = Rect:new(0, 0, width, ResourceBar.HEIGHT)
    self.font = FONT
    self.bottomHeight = BAR_BOTTOM_HEIGHT
    self:createInput()
    self._sourceComponent = sourceComponent
    self._potentialConsume = false
    self.textOverride = false
    self.getStrokeColor = alwaysFalse
    self._needRefresh = true
    self._currentValue = 0
    self._maxValue = 0
    self._canvas = graphics.newCanvas(width, ResourceBar.HEIGHT)
end

function ResourceBar:setPotentialConsume(value)
    if self._potentialConsume ~= value then
        self._potentialConsume = value
        self._needRefresh = true
    end

end

function ResourceBar:update(...)
    ResourceBar:super(self, "update", ...)
    local currentValue = self._sourceComponent:getCurrent()
    local maxValue = self._sourceComponent:getMax()
    if currentValue ~= self._currentValue then
        self._currentValue = currentValue
        self._needRefresh = true
    end

    if maxValue ~= self._maxValue then
        self._maxValue = maxValue
        self._needRefresh = true
    end

end

function ResourceBar:draw()
    if self._needRefresh then
        graphics.push()
        graphics.origin()
        graphics.setCanvas(self._canvas)
        graphics.clear()
        self:_drawCanvas()
        graphics.setCanvas()
        graphics.pop()
        self._needRefresh = false
    end

    local strokeColor = self.getStrokeColor()
    if strokeColor then
        graphics.wSetColor(strokeColor)
        DrawMethods.fillClippedRect(self.rect:sizeAdjusted(1), 2)
        graphics.wSetColor(WHITE)
    end

    graphics.draw(self._canvas)
end

function ResourceBar:_drawCanvas()
    graphics.wSetColor(COLORS.STROKE)
    DrawMethods.fillClippedRect(self.rect, 1)
    graphics.wSetColor(COLORS.BAR_BASE)
    local barRect = self.rect:sizeAdjusted(-1)
    graphics.wRectangle(barRect)
    local currentValue = self._sourceComponent:getCurrent()
    if self._potentialConsume then
        currentValue = currentValue - self._potentialConsume
    end

    local maxValue = self._sourceComponent:getMax()
    local topColor, bottomColor
    if self._sourceComponent:getStat() == Tags.STAT_MAX_HEALTH then
        topColor, bottomColor = COLORS.HEALTH_TOP, COLORS.HEALTH_BOTTOM
    else
        topColor, bottomColor = COLORS.MANA_TOP, COLORS.MANA_BOTTOM
    end

    if self._potentialConsume then
        graphics.wSetColor(topColor:expandValues(0.5))
        DrawMethods.bar(barRect.x, barRect.y, barRect.width, barRect.height - self.bottomHeight, currentValue + self._potentialConsume, maxValue)
        graphics.wSetColor(bottomColor:expandValues(0.5))
        DrawMethods.bar(barRect.x, barRect.y + barRect.height - self.bottomHeight, barRect.width, self.bottomHeight, currentValue + self._potentialConsume, maxValue)
    end

    graphics.wSetColor(topColor)
    DrawMethods.bar(barRect, currentValue, maxValue)
    graphics.wSetColor(bottomColor)
    DrawMethods.bar(barRect.x, barRect.y + barRect.height - self.bottomHeight, barRect.width, self.bottomHeight, currentValue, maxValue)
    graphics.wSetFont(self.font)
    local textY = (self.rect.height - self.font:getStrokedHeight()) / 2
    if self.textOverride then
        graphics.wSetColor(COLORS.NORMAL)
        DrawText.drawStroked(self.textOverride, floor((self.rect.width - self.font:getStrokedWidth(self.textOverride)) / 2), textY)
    else
        local fullText = FORMAT:format(currentValue, maxValue)
        local lengthBasis = self.font:getStrokedWidth(FORMAT:format(maxValue, maxValue))
        if self._potentialConsume then
            graphics.wSetColor(COLORS.TEXT_CONSUMING_MANA)
        else
            graphics.wSetColor(COLORS.NORMAL)
        end

        DrawText.drawStroked(tostring(currentValue), floor((self.rect.width + lengthBasis) / 2 - self.font:getStrokedWidth(fullText)), textY)
        graphics.wSetColor(COLORS.NORMAL)
        local text = HALF_FORMAT:format(maxValue)
        DrawText.drawStroked(text, floor((self.rect.width + lengthBasis) / 2 - self.font:getStrokedWidth(text)), textY)
    end

end

function ResourceBar:onWindowModeChange()
    self._needRefresh = true
end

return ResourceBar

