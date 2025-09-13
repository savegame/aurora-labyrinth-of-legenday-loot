local Claw = class("actions.components.component")
local Vector = require("utils.classes.vector")
local EASING = require("draw.easing")
local CLAW_FADE_SPEED = 7
local CLAW_FADE_REPEAT = 0.02
local CLAW_FADE_SPEED_LINGERING = 5
local CLAW_FADE_REPEAT_LINGERING = 0.0075
local CLAW_ANGLE = math.tau * 0.07
function Claw:initialize(action)
    Claw:super(self, "initialize", action)
    self.angleStart = CLAW_ANGLE
    self.angleEnd = -CLAW_ANGLE
    self._fadeRepeat = CLAW_FADE_REPEAT
    self._fadeSpeed = CLAW_FADE_SPEED
    self.image = false
    self.fadeTrail = false
    self.color = false
end

function Claw:setTrailToLingering()
    self._fadeRepeat = CLAW_FADE_REPEAT_LINGERING
    self._fadeSpeed = CLAW_FADE_SPEED_LINGERING
end

function Claw:setAngles(angleStart, angleEnd)
    self.angleStart = angleStart
    self.angleEnd = angleEnd
end

function Claw:createImage()
    local entity = self.action.entity
    local image = self:createEffect("image", "claw_single")
    image.position = entity.body:getPosition()
    if self.color then
        image.color = self.color
    end

    if entity:hasComponent("offset") then
        image.position = image.position + entity.offset:getJump()
    end

    image.direction = self.action.direction
    image.angle = -self.angleStart
    image.originOffset = Vector:new(-1, 0)
    self.image = image
end

function Claw:_createFadeTrail(currentEvent)
    local fadeTrail = self:createEffect("fade_trail")
    fadeTrail.effect = self.image
    fadeTrail.fadeSpeed = self._fadeSpeed
    if self.color then
        fadeTrail.color = self.color
    end

    self.fadeTrail = fadeTrail
    return fadeTrail:chainTrailEvent(currentEvent, self._fadeRepeat)
end

function Claw:chainSlashEvent(currentEvent, duration)
    return currentEvent:chainEvent(function(_, currentEvent)
        self:_createFadeTrail(currentEvent)
    end):chainProgress(duration, function(progress)
        self.image.angle = (self.angleStart - self.angleEnd) * progress - self.angleStart
    end, EASING.IN_OUT_QUAD):chainEvent(function(currentTime)
        self.fadeTrail:stopTrailEvent(currentTime)
    end)
end

function Claw:_stopFadeTrail(currentTime)
end

function Claw:deleteImage()
    self.image:delete()
end

return Claw

