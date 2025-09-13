local Controls = class("services.service")
local AXIS_PRESS = 0.75
local AXIS_RELEASE = 0.65
local Hash = require("utils.classes.hash")
local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
Tags.add("INPUT_NONE", 1)
Tags.add("INPUT_HOVERED", 2)
Tags.add("INPUT_RELEASED", 3)
Tags.add("INPUT_PRESSED", 4)
Tags.add("INPUT_TRIGGERED", 5)
Tags.add("TEXT_INPUT_BACKSPACE", 10)
function Controls:initialize()
    Controls:super(self, "initialize")
    self:setDependencies("profile")
    self.keyState = Hash:new()
    self.buttonState = Hash:new()
    self.rawKeyTriggered = false
    self.rawKeyReleased = false
    self.rawButtonTriggered = false
    self.rawButtonReleased = false
end

function Controls:keyPressed(rawKey)
    self.keyState:set(rawKey, Tags.INPUT_TRIGGERED)
    self.rawKeyTriggered = rawKey
    self.services.profile.controlModeGamepad = false
end

function Controls:keyReleased(rawKey)
    self.keyState:set(rawKey, Tags.INPUT_RELEASED)
    self.rawKeyReleased = rawKey
end

function Controls:buttonPressed(rawButton)
    self.buttonState:set(rawButton, Tags.INPUT_TRIGGERED)
    self.rawButtonTriggered = rawButton
    self.services.profile.controlModeGamepad = true
end

function Controls:buttonReleased(rawButton)
    self.buttonState:set(rawButton, Tags.INPUT_RELEASED)
    self.rawButtonReleased = rawButton
end

function Controls:axisConvert(axis, value)
    self:axisToButton(axis .. "+", bound(value, 0, 1))
    self:axisToButton(axis .. "-", bound(-value, 0, 1))
end

function Controls:axisToButton(axis, value)
        if value > AXIS_PRESS then
        self:buttonPressed(axis)
    elseif value < AXIS_RELEASE then
        if self.buttonState:get(axis, Tags.INPUT_NONE) > Tags.INPUT_RELEASED then
            self:buttonReleased(axis)
        end

    end

end

local function removeFrameStateHash(stateHash)
    local keys = stateHash:keys()
    for key in keys() do
                if stateHash:get(key) == Tags.INPUT_TRIGGERED then
            stateHash:set(key, Tags.INPUT_PRESSED)
        elseif stateHash:get(key) == Tags.INPUT_RELEASED then
            stateHash:deleteKey(key)
        end

    end

end

function Controls:removeFrameStates()
    removeFrameStateHash(self.keyState)
    removeFrameStateHash(self.buttonState)
    self.rawKeyTriggered = false
    self.rawKeyReleased = false
    self.rawButtonTriggered = false
    self.rawButtonReleased = false
end

function Controls:getState(code)
    local profile = self.services.profile
    local state = self.keyState:get(profile.codeToKey:get(code), Tags.INPUT_NONE)
    return max(self.buttonState:get(profile.codeToButton:get(code), state))
end

function Controls:isTriggered(code)
    return self:getState(code) >= Tags.INPUT_TRIGGERED
end

function Controls:isPressed(code)
    return self:getState(code) >= Tags.INPUT_PRESSED
end

function Controls:isReleased(code)
    return self:getState(code) == Tags.INPUT_RELEASED
end

function Controls:getLeftMouseState()
    return self.keyState:get("mouse_1", Tags.INPUT_HOVERED)
end

function Controls:getRightMouseState()
    return self.keyState:get("mouse_2", Tags.INPUT_HOVERED)
end

return Controls

