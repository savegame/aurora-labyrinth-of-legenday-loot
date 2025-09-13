local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ACTION_CONSTANTS = require("actions.constants")
local ATTACK_WEAPON = require("actions.attack_weapon")
local SKILL = require("structures.skill_def"):new()
local CHARGE_SPEED = 2
local MOVES_BEFORE_CHARGING = 2
local SELF_DAMAGE_RATIO = 1 / 6
SKILL:setCooldownToNormal()
SKILL.getCastDirection = function(entity, player)
    local entityPos = entity.body:getPosition()
    local playerPos = player.body:getPosition()
    if entityPos:distanceManhattan(playerPos) <= CHARGE_SPEED * MOVES_BEFORE_CHARGING then
        if entity.body:isAlignedTo(playerPos) then
            return Common.getDirectionTowards(entityPos, playerPos)
        end

    end

    return false
end
SKILL.indicateArea = function(entity, direction, indicateGrid)
    local position = entity.body:getPosition()
    for i = 1, CHARGE_SPEED do
        local target = position + Vector[direction] * i
        indicateGrid:set(target, true)
        if not entity.body:isPassable(target) then
            return 
        end

    end

end
SKILL.continuousCast = true
local SKILL_ACTION = class("actions.action")
SKILL.actionClass = SKILL_ACTION
function SKILL_ACTION:initialize(entity, direction, abilityStats)
    SKILL_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("move")
    self.move:setEasingToLinear()
    self:addComponent("charactertrail")
    self.stepDuration = ACTION_CONSTANTS.WALK_DURATION / CHARGE_SPEED
end

function SKILL_ACTION:checkParallel()
    local body = self.entity.body
    local moveFrom = body:getPosition()
    local vDirection = Vector[self.direction]
    if not body:canBePassable(moveFrom + vDirection) then
        return true
    end

    if body:isPassable(moveFrom + vDirection) then
        if not body:canBePassable(moveFrom + vDirection * 2) then
            return true
        end

        return body:isPassable(moveFrom + vDirection * 2)
    end

    return false
end

function SKILL_ACTION:parallelResolve(anchor)
    self.move:reset()
    self.entity.sprite:turnToDirection(self.direction)
    local moveFrom = self.entity.body:getPosition()
    local moveTo = moveFrom
    for i = 1, CHARGE_SPEED + 1 do
        moveTo = moveTo + Vector[self.direction]
        if not self.entity.body:isPassable(moveTo) then
            break
        end

    end

    moveTo = moveTo - Vector[self.direction]
    self.move.distance = moveFrom:distanceManhattan(moveTo)
    self.move:prepare(anchor)
end

function SKILL_ACTION:process(currentEvent)
    self.charactertrail:start(currentEvent)
    Common.playSFX("DASH", 0.9)
    local entity = self.entity
    local vDirection = Vector[self.direction]
    local stepDuration = self.stepDuration
    if not entity.sprite:isVisible() then
        local allHidden = true
        for i = 0, self.move.distance do
            if entity.sprite:isPositionVisible(entity.body:getPosition() - vDirection * i) then
                allHidden = false
                break
            end

        end

        if allHidden then
            stepDuration = 0
        end

    end

    if self.move.distance > 0 then
        currentEvent = self.move:chainMoveEvent(currentEvent, stepDuration * self.move.distance)
    end

    local hitTarget = entity.body:getPosition() + vDirection
    if self.move.distance == CHARGE_SPEED then
        if entity.body:canBePassable(hitTarget) then
            return currentEvent:chainEvent(function()
                self.charactertrail:stop()
            end)
        end

    end

    entity.caster:cancelPreparedAction(true)
    local offset = entity.offset:createProfile()
    local done = currentEvent:createWaitGroup(1, function()
        self.charactertrail:stop()
        entity.offset:deleteProfile(offset)
    end)
    currentEvent:chainProgress(stepDuration / 2, function(progress)
        offset.bodyScrolling = vDirection * progress / 2
    end):chainEvent(function(_, anchor)
        self:shakeScreen(anchor, 1)
        Common.playSFX("ROCK_SHAKE", 1.2)
        local hit = entity.hitter:createHit()
        if self.move.distance < CHARGE_SPEED then
            hit:setKnockback(CHARGE_SPEED - self.move.distance, self.direction, stepDuration)
        end

        hit:setDamage(Tags.DAMAGE_TYPE_SPELL, self.entity.stats:getEnemyAbility())
        hit:increaseBonusState()
        hit:applyToPosition(anchor, hitTarget)
        if not hit.knockback or hit.knockback.distance == 0 then
            anchor:chainProgress(stepDuration / 2, function(progress)
                offset.bodyScrolling = vDirection * (1 - progress) / 2
            end):chainWaitGroupDone(done)
        else
            entity.body:setPosition(hitTarget)
            entity.triggers:parallelChainPreMove(anchor, hitTarget - vDirection, hitTarget)
            offset.bodyScrolling = -vDirection / 2
            anchor:chainProgress(stepDuration / 2, function(progress)
                offset.bodyScrolling = -vDirection * (1 - progress) / 2
            end):chainEvent(function(_, anchor)
                entity.body:endOfMove(anchor, hitTarget - vDirection, hitTarget)
                if hit.knockback.distance > 1 then
                    self.move:reset()
                    self.move.distance = hit.knockback.distance - 1
                    self.move:prepare(anchor)
                    anchor = self.move:chainMoveEvent(anchor, stepDuration * self.move.distance)
                end

                anchor:chainWaitGroupDone(done)
            end)
        end

    end)
    return done
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(10, 5)
    entity:addComponent("melee")
    entity.melee.swingIcon = Vector:new(10, 8)
    entity.melee.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
    entity:addComponent("caster", SKILL)
    entity.caster.alignDistance = CHARGE_SPEED * MOVES_BEFORE_CHARGING
    entity.caster.alignBackOff = false
    entity.caster.disabledWithImmobilize = true
end

