local Tackle = class("actions.components.component")
local EASING = require("draw.easing")
local Vector = require("utils.classes.vector")
local MEASURES = require("draw.measures")
local TRAIL_FADE_SPEED = 6
local TRAIL_FADE_REPEAT = 0.025
local TRAIL_OPACITY = 0.6
function Tackle:initialize(action)
    Tackle:super(self, "initialize", action)
    self.braceDistance = 0
    self.forwardDistance = 0
    self.offset = false
    self.isDirectionHorizontal = false
    self.forwardEasing = EASING.IN_OUT_QUAD
    self.backEasing = EASING.IN_OUT_QUAD
    self._currentDistance = 0
end

function Tackle:createOffset()
    self.offset = self.action.entity.offset:createProfile()
end

function Tackle:getDirection()
    if self.isDirectionHorizontal then
        return MEASURES.toHorizontalDirection(self.action.direction)
    else
        return self.action.direction
    end

end

function Tackle:chainBraceEvent(currentEvent, duration)
    local action = self.action
    self._currentDistance = -self.braceDistance
    if duration == 0 then
        return currentEvent:chainEvent(function()
            self.offset.body = -Vector[self:getDirection()] * self.braceDistance
        end)
    else
        return currentEvent:chainProgress(duration, function(progress)
            self.offset.body = -Vector[self:getDirection()] * self.braceDistance * progress
        end, EASING.IN_OUT_QUAD)
    end

end

function Tackle:chainForwardEvent(currentEvent, duration)
    local lastDistance = self._currentDistance
    self._currentDistance = self.forwardDistance
    return currentEvent:chainProgress(duration, function(progress)
        self.offset.body = Vector[self:getDirection()] * ((self.forwardDistance - lastDistance) * progress + lastDistance)
    end, self.forwardEasing)
end

function Tackle:setToForwardOffset()
    self._currentDistance = self.forwardDistance
    self.offset.body = Vector[self:getDirection()] * self.forwardDistance
end

function Tackle:chainBackEvent(currentEvent, duration)
    local lastDistance = self._currentDistance
    self._currentDistance = 0
    return currentEvent:chainProgress(duration, function(progress)
        self.offset.body = Vector[self:getDirection()] * lastDistance * (1 - progress)
    end, self.backEasing)
end

function Tackle:deleteOffset()
    self.action.entity.offset:deleteProfile(self.offset)
end

return Tackle

