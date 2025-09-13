local Button = class("elements.element")
local COLORS = require("draw.colors")
local DrawMethods = require("draw.methods")
local Rect = require("utils.classes.rect")
local DEFAULT_CLIP = 2
function Button:initialize(width, height)
    Button:super(self, "initialize")
    self.clip = DEFAULT_CLIP
    self.isActivated = false
    self.hideStroke = false
    self.rect = Rect:new(0, 0, width, height)
    self:createInput()
    self.input.triggerSound = "CONFIRM"
end

function Button:evaluateIsActivated()
    return Utils.evaluate(self.isActivated, self, self.parent)
end

function Button:getColorSource()
    if not self.input:evaluateIsEnabled() then
        return COLORS.DISABLED
    else
        return COLORS
    end

end

function Button:draw()
    local colorSource = self:getColorSource()
    graphics.wSetColor(COLORS.NORMAL)
    local isActivated = self:evaluateIsActivated()
    if isActivated then
        graphics.wSetColor(COLORS.STROKE)
        DrawMethods.fillClippedRect(self.rect:sizeAdjusted(1), 3)
        graphics.wSetColor(COLORS.NORMAL)
        DrawMethods.lineClippedRect(self.rect:sizeAdjusted(1), 3)
    else
        if not self.hideStroke then
            graphics.wSetColor(COLORS.STROKE)
            DrawMethods.fillClippedRect(self.rect, self.clip + 1)
        end

    end

    if isActivated then
        graphics.wSetColor(colorSource.NORMAL)
    else
        graphics.wSetColor(colorSource.BUTTON_BORDER)
    end

    if not self.hideStroke then
        DrawMethods.fillClippedRect(self.rect:sizeAdjusted(-1), self.clip)
    else
        graphics.wRectangle(self.rect.x + 1, 2, 1, self.rect.height - 4)
    end

    graphics.wSetColor(colorSource.BUTTON_BACKGROUND:blend(colorSource.BUTTON_BACKGROUND_2, self.input:getOpacity()))
    DrawMethods.fillClippedRect(self.rect:sizeAdjusted(-2), self.clip - 1)
end

return Button

