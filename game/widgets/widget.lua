local Widget = class()
local Array = require("utils.classes.array")
local UniqueList = require("utils.classes.unique_list")
local Vector = require("utils.classes.vector")
local MEASURES = require("draw.measures")
require("services.controls")
function Widget:initialize()
    self._elements = UniqueList:new()
    self.position = Vector.ORIGIN
    self.isVisible = true
    self.isHidden = false
    self.alignment = UP_LEFT
    self.alignWidth = 0
    self.alignHeight = 0
    self.alwaysCenteredOnPosition = false
    self.toDelete = false
    self.config = false
    self._children = Array:new()
    self.parent = false
end

function Widget:delete()
    self.toDelete = true
end

function Widget:evaluateIsVisible()
    return Utils.evaluate(self.isVisible, self)
end

function Widget:receiveMessage(message,...)
end

function Widget:setPosition(x, y)
    if Vector:isInstance(x) then
        self.position = x
    else
        self.position = Vector:new(x, y)
    end

end

function Widget:formatElementArgs(x, y,...)
    if not x or Vector:isInstance(x) then
        return x, Array:new(y, ...)
    else
        return Vector:new(x, y), Array:new(...)
    end

end

function Widget:addElementInstance(element)
    element.parent = self
    self._elements:push(element)
end

function Widget:addElement(elementName, x, y,...)
    local position, args = self:formatElementArgs(x, y, ...)
    local elementClass = require("elements." .. elementName)
    local element = elementClass:new(args:expand())
    if position then
        element.position = position
    end

    self:addElementInstance(element)
    return element
end

function Widget:addChildWidget(config, x, y,...)
    local position, args = self:formatElementArgs(x, y, ...)
    local widgetClass = require("widgets." .. config)
    local widget = widgetClass:new(args:expand())
    widget.config = config
    widget.parent = self
    if position then
        widget.position = position
    end

    self._children:push(widget)
    self._elements:push(widget)
    return widget
end

function Widget:addHiddenControl(shortcut, onActivate, movementValue, isRelease)
    local hiddenControl = self:addElement("hidden_control")
    hiddenControl.movementValue = movementValue or 0
    hiddenControl.input.shortcut = shortcut
    if isRelease then
        hiddenControl.input.onRelease = onActivate
    else
        hiddenControl.input.onTrigger = onActivate
    end

    return hiddenControl
end

function Widget:moveElementToTop(element)
    if self._elements:contains(element) then
        self._elements:delete(element)
        self._elements:push(element)
    end

end

function Widget:deleteElement(element)
    self._elements:delete(element)
end

function Widget:resetInput()
    for element in self._elements() do
                if Widget:isInstance(element) then
            element:resetInput()
        elseif element:hasInput() then
            element.input.state = Tags.INPUT_NONE
        end

    end

end

function Widget:alignedPosition(serviceViewport)
    local position = self.position
    local alignVector
    if Vector:isInstance(self.alignment) then
        alignVector = self.alignment
    else
        alignVector = MEASURES.ALIGNMENT[self.alignment]
    end

    local scD = Vector:new(serviceViewport:getScreenDimensions())
    position = position * (Vector.UNIT_XY - alignVector * 2) + scD * alignVector
    if self.alwaysCenteredOnPosition then
        position = position - Vector:new(self.alignWidth, self.alignHeight) / 2
    else
        position = position - Vector:new(self.alignWidth, self.alignHeight) * alignVector
    end

    return position
end

function Widget:interactWithElement(serviceViewport, element, state, mousePosition)
    local position = self:alignedPosition(serviceViewport)
    local relativeMouse = mousePosition - position - element.position
    if self.parent then
        relativeMouse = relativeMouse - self.parent:alignedPosition(serviceViewport)
    end

    element.input:interact(state, relativeMouse)
end

function Widget:checkMouseReception(serviceViewport, mouseState, mousePosition)
    local position = self:alignedPosition(serviceViewport)
    if self:evaluateIsVisible() and not self.isHidden then
        for element in self._elements:reverseIterator() do
            if element:evaluateIsVisible() and not element.isHidden then
                                if Widget:isInstance(element) then
                    local interacting = element:checkMouseReception(serviceViewport, mouseState, mousePosition - position)
                    if interacting then
                        return interacting
                    end

                elseif element:hasInput() then
                    local rect = element.rect:clone()
                    rect:setPosition(position + element.position + rect:getPosition())
                    if rect:contains(mousePosition) then
                        local relativeMouse = mousePosition - position - element.position
                        element.input:interact(mouseState, relativeMouse)
                        return element
                    end

                end

            end

        end

    end

    return false
end

function Widget:checkShortcutReception(controls)
    if self:evaluateIsVisible() then
        for element in self._elements:reverseIterator() do
            if element:evaluateIsVisible() then
                                if Widget:isInstance(element) then
                    local interacting, state = element:checkShortcutReception(controls)
                    if interacting then
                        return interacting, state
                    end

                elseif element:hasInput() then
                    local shortcut = element.input.shortcut
                    if shortcut then
                        local state = controls:getState(shortcut)
                        if state > Tags.INPUT_HOVERED then
                            element.input:interact(state)
                            return element, state
                        end

                    end

                end

            end

        end

    end

    return false, false
end

function Widget:update(dt, serviceViewport)
    for element in self._elements() do
        element:update(dt, serviceViewport)
    end

end

function Widget:draw(serviceViewport, timePassed)
    local position = self:alignedPosition(serviceViewport)
    if self:evaluateIsVisible() and not self.isHidden then
        Debugger.startBenchmark(self.config)
        for element in self._elements() do
            if element:evaluateIsVisible() and not element.isHidden then
                graphics.push()
                if Widget:isInstance(element) then
                    graphics.translate(serviceViewport:toNearestScale(position):expand())
                    element:draw(serviceViewport, timePassed)
                else
                    graphics.wSetColor(WHITE)
                    local elementPosition = position + element.position
                    graphics.translate(serviceViewport:toNearestScale(elementPosition):expand())
                    element:draw(serviceViewport, timePassed)
                end

                graphics.pop()
            end

        end

        Debugger.stopBenchmark(self.config)
    end

end

function Widget:onWindowModeChange()
    for element in self._elements() do
        element:onWindowModeChange()
    end

end

return Widget

