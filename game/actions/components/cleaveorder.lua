local CleaveOrder = class("actions.components.component")
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local Common = require("common")
local ActionUtils = require("actions.utils")
local EASING = require("draw.easing")
function CleaveOrder:initialize(action)
    CleaveOrder:super(self, "initialize", action)
    self._easingInverse = EASING.IN_OUT_QUAD_INVERSE
    self.area = 3
    self.direction = false
    self.position = false
end

function CleaveOrder:setEasingToLinear()
    self._easingInverse = EASING.LINEAR
end

function CleaveOrder:getDirection()
    return self.direction or self.action.direction
end

function CleaveOrder:getAngles(isInverted)
    local angleStart, angleEnd
    local direction = self:getDirection()
        if self.area == 8 then
        angleStart, angleEnd = math.tau * 7 / 16, -math.tau * 9 / 16
        if direction == RIGHT then
            angleStart, angleEnd = math.tau * 9 / 16, -math.tau * 7 / 16
        end

    elseif self.area == 4 then
        angleStart, angleEnd = math.tau * 3 / 8, -math.tau * 5 / 8
        if direction == RIGHT then
            angleStart, angleEnd = angleEnd, angleStart
        end

    else
        angleStart, angleEnd = math.tau * self.area / 16, -math.tau * self.area / 16
    end

    if direction == RIGHT then
        angleEnd, angleStart = angleStart, angleEnd
    end

    if isInverted then
        return -angleStart, -angleEnd
    else
        return angleStart, angleEnd
    end

end

function CleaveOrder:getHitDurations()
    local moments = Array:new()
    for i = 1, self.area do
        moments:push((i * 2 - 1) / (self.area * 2))
    end

    return Common.getInverseDurations(moments, self._easingInverse)
end

function CleaveOrder:chainHitEvent(currentEvent, duration, onHit)
    local direction = self:getDirection()
    local position = self.position
    if not position then
        position = Common.getPositionComponent(self.action.entity):getPosition()
    end

    local damageOrder = ActionUtils.getCleavePositions(position, self.area, direction)
    local hitDurations = self:getHitDurations()
    for i, nextDuration in ipairs(hitDurations) do
        local thisPosition = damageOrder[i]
        currentEvent = currentEvent:chainProgress(nextDuration * duration):chainEvent(function(_, anchor)
            local afterDuration = false
            if i < hitDurations:size() then
                afterDuration = hitDurations[i + 1] * duration
            end

            onHit(anchor, thisPosition, afterDuration)
        end)
    end

    return currentEvent
end

return CleaveOrder

