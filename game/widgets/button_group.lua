local ButtonGroup = class("widgets.widget")
local Array = require("utils.classes.array")
local MEASURES = require("draw.measures")
local Common = require("common")
function ButtonGroup:initialize()
    ButtonGroup:super(self, "initialize")
    self.buttons = Array:new()
    self.skipDisabled = false
end

local function isButtonActivated(button)
    if PortSettings.IS_MOBILE then
        return false
    end

    return button.input.shortcut == Tags.KEYCODE_CONFIRM
end

function ButtonGroup:createButtonElement(x, y, width, text)
    return self:addElement("button_text", x, y, width, MEASURES.HEIGHT_BUTTON, text)
end

function ButtonGroup:add(text, x, y, width, onRelease)
    local button = self:createButtonElement(x, y, width, text)
    button.isActivated = isButtonActivated
    if onRelease then
        button.input.onRelease = onRelease
    end

    self.buttons:push(button)
    if self.buttons:size() == 1 then
        button.input.shortcut = Tags.KEYCODE_CONFIRM
        button.wasLastHovered = true
    end

    if not PortSettings.IS_MOBILE then
        button.input.hoverOnDisabled = true
    end

    return button
end

function ButtonGroup:addControl(shortcut, value)
    local control = self:addElement("hidden_control")
    control.input.shortcut = shortcut
    if value ~= 0 then
        control.input.onTrigger = function(control, widget)
            widget:selectNext(value)
        end
    end

end

function ButtonGroup:selectNext(offset)
    local offset = offset or 1
    local index = self.buttons:indexIf(isButtonActivated)
    Common.playSFX("CURSOR")
    if index then
        self.buttons[index].input.shortcut = false
        index = modAdd(index, offset, self.buttons:size())
        self.buttons[index].input.shortcut = Tags.KEYCODE_CONFIRM
    end

    if self.skipDisabled and not self.buttons[index].input:evaluateIsEnabled() then
        self:selectNext(offset)
    end

end

function ButtonGroup:selectIndex(index)
    self:deselect()
    self.buttons[index].input.shortcut = Tags.KEYCODE_CONFIRM
end

function ButtonGroup:selectButton(button)
    local index = self.buttons:indexOf(button)
    if index > 0 then
        self:selectIndex(index)
    end

end

function ButtonGroup:triggerIndex(index)
    self.buttons[index].input:trigger()
end

function ButtonGroup:deselect()
    local selected = self.buttons:findOne(isButtonActivated)
    if selected then
        selected.input.shortcut = false
    end

end

function ButtonGroup:dehover()
    for button in self.buttons() do
        button.wasLastHovered = false
    end

end

return ButtonGroup

