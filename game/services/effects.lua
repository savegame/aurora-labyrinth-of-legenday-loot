local Effects = class("services.service")
local Common = require("common")
local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local HIT_SPEED_MULTIPLIER = 0.5
function Effects:initialize()
    Effects:super(self, "initialize")
    self:setDependencies("timing", "viewport", "coordinates", "parallelscheduler")
    self.screenFlash = 1
    self.speedMultiplier = 1
    self.currentHits = 0
    self.timeStopped = 0
    self.screenFlashSpeed = 1
    self.screenFlashColor = WHITE
    self.screenFlashOpacity = 0
    self.screenOffset = Vector.ORIGIN
    self.effects = Array:new()
end

function Effects:getSpeedMultiplier()
    if self.currentHits > 0 then
        return self.speedMultiplier * HIT_SPEED_MULTIPLIER
    else
        return self.speedMultiplier
    end

end

function Effects:multiplySpeed(factor)
    self.speedMultiplier = self.speedMultiplier * factor
end

function Effects:divideSpeed(divisor)
    self.speedMultiplier = self.speedMultiplier / divisor
    if abs(self.speedMultiplier - 1) < 0.001 then
        self.speedMultiplier = 1
    end

end

function Effects:createParallelEvent()
    return self.services.parallelscheduler:createEvent()
end

function Effects:addTimeStop(value)
    self.timeStopped = self.timeStopped + value
end

function Effects:getTimePassed()
    if self.timeStopped > 0 then
        return 0
    else
        return self.services.timing.timePassed
    end

end

function Effects:create(effectName,...)
    local effect = require("effects." .. effectName):new(...)
    self.effects:push(effect)
    return effect
end

function Effects:clone(effect)
    local result = effect:clone()
    self.effects:push(result)
    return result
end

function Effects:flashScreen(flashDuration, flashColor, initialOpacity)
    initialOpacity = initialOpacity or 1
    self.screenFlashSpeed = initialOpacity / flashDuration
    self.screenFlashOpacity = initialOpacity
    self.screenFlashColor = flashColor
end

function Effects:shakeScreen(currentEvent, shakeIntensity, shakeDecay)
    shakeDecay = shakeDecay or 0.1
    local rng = Common.getMinorRNG()
    local angle = rng:random() * math.tau
    while shakeIntensity > 0.1 do
        local thisIntensity = shakeIntensity
        local thisAngle = angle
        currentEvent = currentEvent:chainEvent(function()
            self.screenOffset = Vector:createFromAngle(thisAngle) * thisIntensity
        end):chainProgress(0.02)
        shakeIntensity = shakeIntensity * (1 - shakeDecay)
        angle = (angle + math.tau / 2 + (rng:random() * 2 - 1) * math.tau / 6) % math.tau
    end

    currentEvent:chainEvent(function()
        self.screenOffset = Vector.ORIGIN
    end)
    return currentEvent
end

function Effects:shakeContinuous(currentEvent, shakeIntensity)
    local rng = Common.getMinorRNG()
    local angle = rng:random() * math.tau
    return currentEvent:chainEvent(function()
        self.screenOffset = Vector:createFromAngle(angle) * shakeIntensity
        angle = (angle + math.tau / 2 + (rng:random() * 2 - 1) * math.tau / 6) % math.tau
    end, 0.02)
end

function Effects:update(dt)
    for effect in self.effects() do
        effect:update(dt)
    end

    if self.screenFlashOpacity > 0 then
        self.screenFlashOpacity = max(0, self.screenFlashOpacity - dt * self.screenFlashSpeed)
    end

end

function Effects:drawScreenFlash()
    if self.screenFlashOpacity > 0 then
        graphics.wSetColor(self.screenFlashColor:withAlphaMultiplied(self.screenFlashOpacity))
        local scW, scH = self.services.viewport:getScreenDimensions()
        graphics.wRectangle(-1, -1, scW + 2, scH + 2)
    end

end

function Effects:draw(layer)
    self.effects:rejectSelf(function(effect)
        return effect.layer == layer and effect.toDelete
    end)
    for effect in self.effects() do
        if effect:isVisible() and effect.layer == layer then
            graphics.wSetColor(WHITE)
            effect:draw(self.services.coordinates, self.services.timing.timePassed)
        end

    end

    self.effects:rejectSelf(function(effect)
        return effect.layer == layer and effect.toDelete
    end)
end

return Effects

