local AcidSpit = class("actions.components.component")
local Vector = require("utils.classes.vector")
local Common = require("common")
local ACTIONS_FRAGMENT = require("actions.fragment")
local EASING = require("draw.easing")
local ACID_HIT = class("actions.action")
local HIT_DURATION = 0.55
local TRAVEL_HEIGHT = 0.35
local LOWER_OFFSET = 0.05
function ACID_HIT:initialize(entity, direction, abilityStats)
    ACID_HIT:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.target = false
    self.explosion:setArea(Tags.ABILITY_AREA_SINGLE)
end

function ACID_HIT:process(currentEvent)
    self.explosion.source = self.target
    self.explosion:chainFullEvent(self:createParallelEvent(), HIT_DURATION)
    return currentEvent
end

function AcidSpit:initialize(action)
    AcidSpit:super(self, "initialize", action)
    self.source = false
    self.direction = false
    self.imageFile = "acid_spit"
    self.explosionHue = 120
    self.travelHeight = TRAVEL_HEIGHT
end

function AcidSpit:_createImage(source, direction)
    local image = self:createEffect("image", self.imageFile)
    image.position = source
    image.direction = direction
    image.orientOffset = false
    image.offset = Vector:new(0, LOWER_OFFSET)
    return image
end

function AcidSpit:setToArcane()
    self.explosionHue = 270
    self.imageFile = "acid_spit_arcane"
end

function AcidSpit:setToFire()
    self.explosionHue = 0
    self.imageFile = "acid_spit_fire"
end

function AcidSpit:_getSource()
    return self.source or self.action.entity.body:getPosition()
end

function AcidSpit:chainSpitEvent(currentEvent, duration, target)
    local direction = self.direction or self.action.direction
    local image
    return currentEvent:chainEvent(function()
        image = self:_createImage(self:_getSource(), direction)
    end):chainProgress(duration, function(progress)
        image.offset = Vector:new(0, -EASING.PARABOLIC_HEIGHT(progress) * self.travelHeight + LOWER_OFFSET)
        local source = self:_getSource()
        local target = Utils.evaluate(target)
        image.direction = Common.getDirectionTowards(source, target)
        image.position = (target - source) * progress + source
        if direction == LEFT or direction == RIGHT then
            local angle = math.atan2(self.travelHeight * 2, target:distanceManhattan(source))
            image.angle = -angle + progress * angle * 2
        end

    end):chainEvent(function(_, anchor)
        image:delete()
        local hitAction = self.action.entity.actor:create(ACID_HIT, self.action.direction)
        hitAction.explosion.hue = self.explosionHue
        hitAction.target = Utils.evaluate(target)
        return hitAction:parallelChainEvent(anchor)
    end)
end

return AcidSpit

