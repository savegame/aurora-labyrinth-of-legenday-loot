local Slider = class("elements.element")
local Rect = require("utils.classes.rect")
local STEP_DIVISIONS = 10
local BAR_HEIGHT = 8
local KNOB_HEIGHT = 12
local KNOB_WIDTH = 7
if PortSettings.IS_MOBILE then
    BAR_HEIGHT = BAR_HEIGHT + 6
    KNOB_HEIGHT = KNOB_HEIGHT + 8
    KNOB_WIDTH = KNOB_WIDTH + 6
end

local BAR_CLIP = 2
local COLORS = require("draw.colors")
local DrawMethods = require("draw.methods")
function Slider:initialize(width)
    Slider:super(self, "initialize")
    self.rect = Rect:new(0, 0, width, KNOB_HEIGHT)
    self.value = 0.5
    self:createInput(self.rect)
    self.onChange = doNothing
    self.input.onDrag = function(self, widget, mouseTriggerLast, mousePosition)
        local barWidth = mousePosition.x - 2 - (KNOB_WIDTH - 4) / 2
        self.value = bound(barWidth / self:barMaxWidth(), 0, 1)
        self.onChange(self.value)
    end
    self.input.onTrigger = function(self)
        return self.input.onDrag(self, self.parent, false, self.input.mouseTriggerLast)
    end
end

function Slider:barMaxWidth()
    return self.rect.width - 4 - (KNOB_WIDTH - 4)
end

function Slider:createValueGetter(minValue, maxValue, roundDigits)
    roundDigits = roundDigits or 0
    return function()
        return round(self.value * (maxValue - minValue) + minValue, roundDigits)
    end
end

function Slider:draw()
    local barWidth = self:barMaxWidth() * self.value
    local knobRect = Rect:new(barWidth, 0, KNOB_WIDTH, KNOB_HEIGHT)
    local barRect = Rect:new(0, (KNOB_HEIGHT - BAR_HEIGHT) / 2, self.rect.width, BAR_HEIGHT)
    graphics.wSetColor(COLORS.STROKE)
    DrawMethods.fillClippedRect(barRect:sizeAdjusted(1), BAR_CLIP + 1)
    graphics.wSetColor(COLORS.BUTTON_BORDER)
    DrawMethods.fillClippedRect(barRect, BAR_CLIP)
    graphics.wSetColor(COLORS.BAR_BASE)
    DrawMethods.fillClippedRect(barRect:sizeAdjusted(-1), BAR_CLIP - 1)
    barRect = barRect:sizeAdjusted(-2)
    barRect.width = barWidth
    graphics.wSetColor(COLORS.BUTTON_BORDER)
    graphics.wRectangle(barRect)
    graphics.wSetColor(COLORS.STROKE)
    DrawMethods.fillClippedRect(knobRect:sizeAdjusted(1), 2)
    graphics.wSetColor(COLORS.BUTTON_BORDER)
    DrawMethods.lineClippedRect(knobRect, 1)
    local bgColor = COLORS.BUTTON_BACKGROUND
    graphics.wSetColor(bgColor:blend(COLORS.BUTTON_BORDER, self.input:getOpacity(), true))
    graphics.wRectangle(knobRect:sizeAdjusted(-2))
end

function Slider:selectNext(offset)
    self.value = bound((round(self.value * STEP_DIVISIONS) + offset) / STEP_DIVISIONS, 0, 1)
    self.onChange(self.value)
end

function Slider:setValue(value)
    self.value = bound(value, 0, 1)
    self.onChange(self.value)
end

return Slider

