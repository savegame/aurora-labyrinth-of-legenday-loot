local InputState = class()
local Common = require("common")
local DRAG_DEADZONE = 3
function InputState:initialize(parent)
    Utils.assert(parent.rect, "InputState requires rect")
    self.state = Tags.INPUT_NONE
    self.parent = parent
    self.isEnabled = true
    self.shortcut = false
    self.triggerSound = false
    self.hoverOnDisabled = false
    self.onTrigger = doNothing
    self.onPress = doNothing
    self.onRelease = doNothing
    self.onHover = doNothing
    self.onDrag = doNothing
    self.onDragRelease = doNothing
    self.onRightMouseTrigger = doNothing
    self.mouseTriggerLast = false
    self.mouseWasDragged = false
    self.cursor = "pointer"
end

function InputState:evaluateIsEnabled()
    return Utils.evaluate(self.isEnabled, self.parent, self.parent.parent)
end

function InputState:interact(state, mousePosition)
        if self:evaluateIsEnabled() then
        self.state = state
                if state >= Tags.INPUT_PRESSED then
                        if state >= Tags.INPUT_TRIGGERED then
                if mousePosition then
                    self.mouseTriggerLast = mousePosition
                end

                self.onTrigger(self.parent, self.parent.parent)
                if self.triggerSound then
                    Common.playSFX(self.triggerSound)
                end

            elseif mousePosition and self.mouseTriggerLast then
                if self.mouseWasDragged or mousePosition:distanceEuclidean(self.mouseTriggerLast) > DRAG_DEADZONE then
                    self.onDrag(self.parent, self.parent.parent, self.mouseTriggerLast, mousePosition)
                    self.mouseWasDragged = true
                end

            end

            self.onPress(self.parent, self.parent.parent)
        elseif state == Tags.INPUT_RELEASED then
            if mousePosition and self.mouseWasDragged then
                self.onDragRelease(self.parent, self.parent.parent, self.mouseTriggerLast, mousePosition)
            end

            self.onRelease(self.parent, self.parent.parent)
            self.mouseTriggerLast = false
            self.mouseWasDragged = false
        end

        self.onHover(self.parent, self.parent.parent, state == Tags.INPUT_HOVERED)
    elseif self.hoverOnDisabled and state == Tags.INPUT_HOVERED then
        self.state = state
        self.onHover(self.parent, self.parent.parent, state == Tags.INPUT_HOVERED)
    else
        self.state = Tags.INPUT_NONE
    end

end

function InputState:rightMouseTrigger()
    self.onRightMouseTrigger(self.parent, self.parent.parent)
end

function InputState:trigger(...)
    self.onTrigger(self.parent, self.parent.parent, ...)
    self.onRelease(self.parent, self.parent.parent, ...)
end

function InputState:press(...)
    self.onPress(self.parent, self.parent.parent, ...)
end

function InputState:triggerIfEnabled(...)
    if self:evaluateIsEnabled() then
        self:trigger(...)
    end

end

function InputState:getOpacity(inverted, disableSquare)
    if self.state >= Tags.INPUT_HOVERED then
                if self.state >= Tags.INPUT_PRESSED then
            return 1
        elseif disableSquare then
            return 0.5
        else
            return 0.25
        end

    else
        return 0
    end

end

return InputState

