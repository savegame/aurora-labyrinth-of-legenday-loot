local GET_KNOCKED_BACK = class("actions.action")
local CONSTANTS = require("logic.constants")
local Vector = require("utils.classes.vector")
function GET_KNOCKED_BACK:initialize(entity, direction, abilityStats)
    GET_KNOCKED_BACK:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("move")
    self.move:setEasingToLinear()
    self.distance = 0
    self.resolvedDistance = 0
    self.stepDuration = false
    self.sourceEntity = false
    self.bumpMinDamage = false
    self.bumpMaxDamage = false
    self.bumpDamageBoosted = false
end

function GET_KNOCKED_BACK:parallelResolve(anchor)
    local moveFrom = self.entity.body:getPosition()
    self.resolvedDistance = 0
    for i = 1, self.distance do
        if self.entity.body:isPassable(moveFrom + Vector[self.direction] * i) then
            self.resolvedDistance = i
        else
            break
        end

    end

    if self.resolvedDistance > 0 then
        self.move.distance = self.resolvedDistance
        self.move:prepare(anchor)
    end

end

function GET_KNOCKED_BACK:process(currentEvent)
    local entity = self.entity
    local vDirection = Vector[self.direction]
    if self.resolvedDistance > 0 then
        local duration = self.stepDuration * self.resolvedDistance
        currentEvent = self.move:chainMoveEvent(currentEvent, duration)
    end

    if self.resolvedDistance < self.distance then
        local offset = entity.offset:createProfile()
        return currentEvent:chainProgress(self.stepDuration / 2, function(progress)
            offset.bodyScrolling = vDirection * progress / 2
        end):chainEvent(function(_, anchor)
            if not self.bumpMinDamage then
                self.bumpMinDamage = self.sourceEntity.stats:get(Tags.STAT_ATTACK_DAMAGE_MIN)
                self.bumpMaxDamage = self.sourceEntity.stats:get(Tags.STAT_ATTACK_DAMAGE_MAX)
            end

            local hitBumper = self.sourceEntity.hitter:createHit()
            hitBumper:setDamage(Tags.DAMAGE_TYPE_KNOCKBACK, self.bumpMinDamage, self.bumpMaxDamage)
            if self.bumpDamageBoosted then
                hitBumper:increaseBonusState()
            end

            hitBumper:applyToEntity(anchor, entity)
            local hitBumpee = self.sourceEntity.hitter:createHit()
            hitBumpee:setDamage(Tags.DAMAGE_TYPE_KNOCKBACK, self.bumpMinDamage, self.bumpMaxDamage)
            if self.bumpDamageBoosted then
                hitBumpee:increaseBonusState()
            end

            hitBumpee:applyToPosition(anchor, entity.body:getPosition() + vDirection)
            entity.tank:undelayDeath(anchor)
        end):chainProgress(self.stepDuration / 2, function(progress)
            offset.bodyScrolling = vDirection * (1 - progress) / 2
        end):chainEvent(function()
            entity.offset:deleteProfile(offset)
        end)
    else
        return currentEvent:chainEvent(function(_, anchor)
            entity.tank:undelayDeath(anchor)
        end)
    end

end

return GET_KNOCKED_BACK

