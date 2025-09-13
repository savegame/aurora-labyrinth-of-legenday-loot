local Vector = require("utils.classes.vector")
local Common = require("common")
local ATTACK_UNARMED = require("actions.attack_unarmed")
local POUNCE_RANGE = 3
local SKILL = require("structures.skill_def"):new()
SKILL:setCooldownToNormal()
SKILL.getCastDirection = function(entity, player)
    local entityPos = entity.body:getPosition()
    local playerPos = player.body:getPosition()
    local distance = entityPos:distanceManhattan(playerPos)
    if distance <= POUNCE_RANGE and distance > 1 then
        if entity.body:isAlignedTo(playerPos) then
            return Common.getDirectionTowards(entityPos, playerPos)
        end

    end

    return false
end
SKILL.indicateArea = function(entity, direction, indicateGrid)
    local position = entity.body:getPosition()
    for i = 1, POUNCE_RANGE do
        local target = position + Vector[direction] * i
        indicateGrid:set(target, true)
        if not entity.body:isPassable(target) then
            return 
        end

    end

end
local STEP_DURATION = 0.14
local JUMP_HEIGHT = 0.3
local BITE_DISTANCE = 0.55
local BITE_START = 0.09
local SKILL_ACTION = class("actions.action")
SKILL.actionClass = SKILL_ACTION
function SKILL_ACTION:initialize(entity, direction, abilityStats)
    SKILL_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("tackle")
    self.tackle.forwardDistance = BITE_DISTANCE
    self:addComponent("jump")
    self.jump.height = JUMP_HEIGHT
    self:addComponent("move")
    self.move:setEasingToLinear()
    self.move.interimSkipTriggers = true
    self:addComponent("charactertrail")
end

function SKILL_ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    local moveFrom = self.entity.body:getPosition()
    local moveTo = moveFrom
    local vDirection = Vector[self.direction]
    for i = 1, (POUNCE_RANGE - 1) + 1 do
        moveTo = moveTo + vDirection
        if not self.entity.body:isPassable(moveTo) then
            break
        end

    end

    moveTo = moveTo - vDirection
    self.move.distance = moveFrom:distanceManhattan(moveTo)
    self.charactertrail:start(currentEvent)
    local totalDuration = STEP_DURATION * self.move.distance
    self.tackle:createOffset()
    self.move:prepare(currentEvent)
    Common.playSFX(self.move:getDashSound())
    self.move:chainMoveEvent(currentEvent, totalDuration)
    self.jump:chainFullEvent(currentEvent, totalDuration):chainEvent(function()
        self.charactertrail:stop()
    end)
    local tackleEvent = self.tackle:chainForwardEvent(currentEvent, totalDuration)
    self.tackle:chainBackEvent(tackleEvent, STEP_DURATION):chainEvent(function()
        self.tackle:deleteOffset()
    end)
    local biteStart = totalDuration - STEP_DURATION + BITE_START
    if biteStart > 0 then
        currentEvent = currentEvent:chainProgress(biteStart)
    end

    local biteAction = self.entity.actor:create(ATTACK_UNARMED.BITE_TEETH, self.direction)
    biteAction.target = moveTo + vDirection
    currentEvent:chainEvent(function()
        Common.playSFX("BITE")
    end)
    return biteAction:parallelChainEvent(currentEvent):chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit(moveTo)
        hit:setDamage(Tags.DAMAGE_TYPE_MELEE, self.entity.stats:getEnemyAbility())
        hit:increaseBonusState()
        hit:applyToPosition(anchor, moveTo + vDirection)
    end)
end

local function shouldCancel(entity, direction)
    return not entity.body:isPassable(entity.body:getPosition() + Vector[direction])
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(8, 7)
    entity:addComponent("melee")
    entity.melee.attackClass = ATTACK_UNARMED.BITE_AND_DAMAGE
    entity:addComponent("caster", SKILL)
    entity.caster.alignDistance = POUNCE_RANGE
    entity.caster.disabledWithImmobilize = true
    entity.caster.shouldCancel = shouldCancel
end

