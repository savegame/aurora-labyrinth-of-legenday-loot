local Chooser = class("widgets.widget")
local Vector = require("utils.classes.vector")
local FONTS = require("draw.fonts")
local COLORS = require("draw.colors")
local FONT_CONTROL = FONTS.SMALL
if PortSettings.IS_MOBILE then
    FONT_CONTROL = FONTS.LARGE
end

local function defaultColorForIndex(index)
    return COLORS.NORMAL
end

function Chooser:initialize(width, height, options, initialIndex)
    Chooser:super(self, "initialize")
    self.isEnabled = true
    self.disabledText = "Disabled"
    self.optionToText = returnSelf
    self.options = options
    self.colorForIndex = defaultColorForIndex
    self.index = initialIndex or 1
    self._defaultIndex = self.index
    self.onChange = doNothing
    local buttonLeft = self:addElement("button_simple_text", 0, 0, height, height, "<", FONT_CONTROL)
    buttonLeft.input.onRelease = function(buttonLeft)
        self:selectNext(-1)
    end
    buttonLeft.input.isEnabled = function(buttonLeft)
        return Utils.evaluate(self.isEnabled, self)
    end
    buttonLeft.input.shortcut = Tags.KEYCODE_LEFT
    buttonLeft.input.triggerSound = "CURSOR"
    local buttonRight = self:addElement("button_simple_text", width - height, 0, height, height, ">", FONT_CONTROL)
    buttonRight.input.onRelease = function(buttonRight)
        self:selectNext(1)
    end
    buttonRight.input.shortcut = Tags.KEYCODE_RIGHT
    buttonRight.input.triggerSound = "CURSOR"
    buttonRight.input.isEnabled = function(buttonRight)
        return Utils.evaluate(self.isEnabled, self)
    end
    local text = self:addElement("text", width / 2, height / 2, function(element)
        if not Utils.evaluate(self.isEnabled, self) then
            return Utils.evaluate(self.disabledText, self)
        else
            return self.optionToText(self.options[self.index])
        end

    end, FONTS.MEDIUM, function()
        return self.colorForIndex(self.index)
    end)
    text.alignment = CENTER
    text.isStroked = true
end

function Chooser:refresh()
    self.onChange(self, self:getSelectedOption())
end

function Chooser:selectNext(offset)
    if Utils.evaluate(self.isEnabled, self) then
        self.index = modAdd(self.index, offset or 1, self.options:size())
        self:refresh()
    end

end

function Chooser:selectByValue(value)
    local index = self.options:indexOf(value)
    if index then
        self.index = index
        self:refresh()
    end

end

function Chooser:selectLast()
    self.index = self.options:size()
    self:refresh()
end

function Chooser:getSelectedOption()
    return self.options[self.index]
end

function Chooser:setIndex(index)
    self.index = (index - 1) % self.options:size() + 1
    self:refresh()
end

function Chooser:resetToDefault()
    if self.index ~= self._defaultIndex then
        self.index = self._defaultIndex
        self.onChange(self, self:getSelectedOption())
    end

end

return Chooser

