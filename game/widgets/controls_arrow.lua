local ControlsArrow = class("widgets.widget")
local Global = require("global")
local Vector = require("utils.classes.vector")
local MEASURES = require("draw.measures")
function ControlsArrow:initialize()
    ControlsArrow:super(self, "initialize")
    self.buttons = {  }
    local controlSize = Global:get(Tags.GLOBAL_PROFILE).controlSize
    local buttonSize = 64 + controlSize * 4 - 24
    local buttonMargin = 8 + ceil(controlSize / 2) - 3
    local offset = buttonSize + buttonMargin
    self.buttons[LEFT] = self:addElement("button_arrow", 0, offset, buttonSize, LEFT)
    self.buttons[UP] = self:addElement("button_arrow", offset, 0, buttonSize, UP)
    self.buttons[DOWN] = self:addElement("button_arrow", offset, offset * 2, buttonSize, DOWN)
    self.buttons[RIGHT] = self:addElement("button_arrow", offset * 2, offset, buttonSize, RIGHT)
    self.buttons[LEFT].input.shortcut = Tags.KEYCODE_LEFT
    self.buttons[UP].input.shortcut = Tags.KEYCODE_UP
    self.buttons[DOWN].input.shortcut = Tags.KEYCODE_DOWN
    self.buttons[RIGHT].input.shortcut = Tags.KEYCODE_RIGHT
    self:setPosition(MEASURES.MARGIN_SCREEN, MEASURES.MARGIN_SCREEN)
    self.alignment = DOWN_LEFT
    self.alignWidth = buttonSize * 3 + buttonMargin * 2
    self.alignHeight = buttonSize * 3 + buttonMargin * 2
end

return ControlsArrow

