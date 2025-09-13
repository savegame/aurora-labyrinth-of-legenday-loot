local Explosion = class("actions.components.component")
local Hash = require("utils.classes.hash")
local Array = require("utils.classes.array")
local ActionUtils = require("actions.utils")
local EASING = require("draw.easing")
local EXPLOSION_PROGRESS_BEFORE_FADE = 0.66
local DISTANCE_RESPONSIBILITY = 0.63
local EXPAND_DURATION_RATIO = 0.2
local SHAKE_DELAY = 0.15
local SIZES = Hash:new({ [Tags.ABILITY_AREA_SINGLE] = 15, [Tags.ABILITY_AREA_CROSS] = 30, [Tags.ABILITY_AREA_3X3] = 37.5, [Tags.ABILITY_AREA_ROUND_5X5] = 55, [Tags.ABILITY_AREA_OCTAGON_7X7] = 75, [Tags.ABILITY_AREA_BOSS_EXPLOSION] = 200 })
function Explosion:initialize(action)
    Explosion:super(self, "initialize", action)
    self.source = false
    self.effect = false
    self.excludeSelf = true
    self.extraExclude = false
    self.hue = 0
    self._area = Tags.ABILITY_AREA_3X3
    self._positions = Hash:new()
    self.expandRatio = EXPAND_DURATION_RATIO
    self.desaturate = false
    self.layer = false
    self.colorMultiplier = 1
    self.shakeIntensity = 0
end

function Explosion:setHueToFire()
    self.hue = 0
end

function Explosion:setHueToEarth()
    self.hue = 30
    self.colorMultiplier = 0.6
end

function Explosion:setHueToPoison()
    self.hue = 120
end

function Explosion:setHueToIce()
    self.hue = 195
end

function Explosion:setHueToArcane()
    self.hue = 285
end

function Explosion:setHueToDeath()
    self.hue = 225
end

function Explosion:setHueToLightning()
    self.hue = 45
end

function Explosion:_create()
    local effect = self:createEffect("explosion")
    effect.size = SIZES:get(self._area)
    if self.layer then
        effect.layer = self.layer
    end

    effect.position = self.source
    if self.hue ~= 0 then
        effect:setHue(self.hue)
    end

    if self.desaturate then
        effect:desaturate(self.desaturate)
    end

    if self.colorMultiplier < 1 then
        effect:multiplyColor(self.colorMultiplier)
    end

    effect.extraExclude = self.extraExclude
    self.effect = effect
end

function Explosion:setArea(area)
    self._area = area
    if self.effect then
        self.effect.size = SIZES:get(area)
    end

end

function Explosion:getSizeAdjustedPitch()
    return SIZES:get(Tags.ABILITY_AREA_3X3) / SIZES:get(self._area)
end

function Explosion:chainExpandEvent(currentEvent, duration, onHit)
    if self.shakeIntensity > 0 then
        currentEvent:chainProgress(duration * SHAKE_DELAY / self.expandRatio):chainEvent(function(_, anchor)
            self.action:shakeScreen(anchor, self.shakeIntensity)
        end)
    end

    currentEvent = currentEvent:chainEvent(function()
        self:_create()
    end)
    if onHit then
        local positions = ActionUtils.getAreaPositions(self.action.entity, self.source, self._area, self.excludeSelf)
        local maxDistance = 0
        for position in positions() do
            local distance = self.source:distance(position)
            if distance > maxDistance then
                maxDistance = distance
            end

            if not self._positions:hasKey(distance) then
                self._positions:set(distance, Array:new())
            end

            self._positions:get(distance):push(position)
        end

        for distance, positionSet in self._positions() do
            local thisPositions = positionSet
            local thisDuration = duration * (1 - DISTANCE_RESPONSIBILITY) + duration * DISTANCE_RESPONSIBILITY * (distance / maxDistance)
            currentEvent:chainProgress(thisDuration):chainEvent(function(_, anchor)
                for position in thisPositions() do
                    onHit(anchor, position)
                end

            end)
        end

    end

    return currentEvent:chainProgress(duration, function(progress)
        self.effect.progress = progress * EXPLOSION_PROGRESS_BEFORE_FADE
    end)
end

function Explosion:chainDisperseEvent(currentEvent, duration)
    return currentEvent:chainProgress(duration, function(progress)
        self.effect.opacity = 1 - progress
        self.effect.eraserProgress = progress
        self.effect.progress = progress * (1 - EXPLOSION_PROGRESS_BEFORE_FADE) + EXPLOSION_PROGRESS_BEFORE_FADE
    end, EASING.OUT_CUBIC):chainEvent(function()
        self:_delete()
    end)
end

function Explosion:chainFullEvent(currentEvent, duration, onHit)
    currentEvent = self:chainExpandEvent(currentEvent, duration * self.expandRatio, onHit)
    self:chainDisperseEvent(currentEvent, duration * (1 - self.expandRatio))
    return currentEvent
end

function Explosion:_delete()
    self.effect:delete()
end

return Explosion

