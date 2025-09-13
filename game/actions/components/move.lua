local Move = class("actions.components.component")
local Array = require("utils.classes.array")
local Range = require("utils.classes.range")
local Vector = require("utils.classes.vector")
local EASING = require("draw.easing")
local Common = require("common")
local TRAIL_FADE_SPEED = 6
local TRAIL_FADE_REPEAT = 0.025
local TRAIL_OPACITY = 0.6
function Move:initialize(action)
    Move:super(self, "initialize", action)
    self:setEasingToIOQuad()
    self:reset()
end

function Move:reset()
    self.direction = false
    self.distance = 1
    self.offset = false
    self.interimSkipTriggers = false
    self.interimSkipProjectiles = false
    self.moveTo = false
    self._moveFrom = false
    self.entity = false
end

function Move:setEasingToLinear()
    self._easing = EASING.LINEAR
    self._easingInverse = EASING.LINEAR
end

function Move:setEasingToIOQuad()
    self._easing = EASING.IN_OUT_QUAD
    self._easingInverse = EASING.IN_OUT_QUAD_INVERSE
end

function Move:_getEntity()
    return self.entity or self.action.entity
end

function Move:prepare(anchor)
    local entity = self:_getEntity()
    self._moveFrom = Common.getPositionComponent(entity):getPosition()
    if not self.direction then
        self.direction = self.action.direction
    end

    if self.moveTo then
        self.distance = self.moveTo:distanceManhattan(self._moveFrom)
    else
        self.moveTo = self._moveFrom + Vector[self.direction] * self.distance
    end

    entity:callIfHasComponent("vision", "scan", self.moveTo)
    Common.getPositionComponent(entity):setPosition(self.moveTo)
    self.offset = entity.offset:createProfile()
    self.offset.bodyScrolling = self._moveFrom - self.moveTo
    if self.action.isParallel then
        for i = 1, self.distance do
            if i == self.distance or not self.interimSkipProjectiles then
                entity.body:freezeProjectilesAt(self._moveFrom + Vector[self.direction] * i)
            end

        end

    end

    entity:callIfHasComponent("triggers", "parallelChainPreMove", anchor, self._moveFrom, self.moveTo)
end

function Move:_postMove(anchor, moveFrom, moveTo)
    local entity = self:_getEntity()
    if entity:hasComponent("body") then
        if self.interimSkipTriggers and moveTo ~= self.moveTo then
            if not self.interimSkipProjectiles then
                entity.body:catchProjectilesAt(anchor, moveTo)
            end

        else
            entity.body:endOfMove(anchor, moveFrom, moveTo)
            if moveTo == self.moveTo and entity:hasComponent("triggers") then
                entity.triggers:parallelChainPostMove(anchor, self._moveFrom, self.moveTo)
            end

        end

    end

    entity:callIfHasComponent("vision", "refreshExplored")
end

function Move:chainMoveEvent(currentEvent, duration, onStep, preStep)
    local entity = self:_getEntity()
    local movementEnd = currentEvent:chainProgress(duration, function(progress)
        local delta = self.moveTo - self._moveFrom
        self.offset.bodyScrolling = delta * (progress - 1)
    end, self._easing):chainEvent(function()
        entity.offset:deleteProfile(self.offset)
    end)
    local moments = Range:new(1, self.distance):toArray():map(function(value)
        return value / self.distance
    end)
    local durations = Common.getInverseDurations(moments, self._easingInverse)
    for i, nextDuration in ipairs(durations) do
        local thisDistance = i
        if preStep then
            currentEvent = currentEvent:chainEvent(function(_, anchor)
                local target = self._moveFrom + Vector[self.direction] * thisDistance
                preStep(anchor, target - Vector[self.direction], target)
            end)
        end

        currentEvent = currentEvent:chainProgress(nextDuration * duration):chainEvent(function(_, anchor)
            local target = self._moveFrom + Vector[self.direction] * thisDistance
            if thisDistance == durations:size() then
                target = self.moveTo
            end

            if onStep then
                onStep(anchor, target - Vector[self.direction], target)
            end

            self:_postMove(anchor, target - Vector[self.direction], target)
        end)
    end

    return movementEnd
end

function Move:getDashSound()
    if self.distance <= 1 then
        return "DASH_SHORT"
    else
        return "DASH"
    end

end

return Move

