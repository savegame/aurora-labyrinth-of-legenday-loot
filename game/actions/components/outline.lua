local Outline = class("actions.components.component")
local COLORS = require("draw.colors")
local OPACITY_NORMAL = 0.73
local OPACITY_LIGHT = 0.5
local Common = require("common")
function Outline:initialize(action)
    Outline:super(self, "initialize", action)
    self.color = false
    self.hasModal = false
    self._maxOpacity = OPACITY_NORMAL
    self._characterEffects = false
end

function Outline:setEntity(entity)
    self._characterEffects = entity.charactereffects
end

function Outline:setIsLight()
    self._maxOpacity = OPACITY_LIGHT
end

function Outline:setIsFull()
    self._maxOpacity = 1
end

function Outline:getOpacity(progress)
    local minOpacity = 0
    if self.hasModal then
        minOpacity = ((COLORS.INDICATION_MIN_OPACITY + COLORS.INDICATION_MAX_OPACITY) / 2) * COLORS.MODE_OUTLINE_PULSE_OPACITY
    end

    return minOpacity + (self._maxOpacity - minOpacity) * progress
end

function Outline:setToFilled()
    if not self._characterEffects then
        self._characterEffects = self.action.entity.charactereffects
    end

    self._characterEffects.outlineOpacity = self:getOpacity(1)
    self._characterEffects.outlineColor = self.color
end

function Outline:chainFadeIn(currentEvent, duration)
    if not self._characterEffects then
        self._characterEffects = self.action.entity.charactereffects
    end

    return currentEvent:chainEvent(function()
        Utils.assert(self.color, "Outline: requires #color")
        Utils.assert(self.color.a == 1, "Outline: Use isLight instead of manipulating color's alpha")
        self._characterEffects.outlineOpacity = 0
        self._characterEffects.outlineColor = self.color
    end):chainProgress(duration, function(progress)
        self._characterEffects.outlineOpacity = self:getOpacity(progress)
    end)
end

function Outline:chainFadeOut(currentEvent, duration)
    return currentEvent:chainProgress(duration, function(progress)
        self._characterEffects.outlineOpacity = self:getOpacity(1 - progress)
    end):chainEvent(function()
        self._characterEffects.outlineOpacity = 0
        self._characterEffects.outlineColor = false
    end)
end

function Outline:chainFullEvent(currentEvent, halfDuration)
    currentEvent = self:chainFadeIn(currentEvent, halfDuration)
    self:chainFadeOut(currentEvent, halfDuration)
    return currentEvent
end

return Outline

