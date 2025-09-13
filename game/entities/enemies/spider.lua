local Vector = require("utils.classes.vector")
local Common = require("common")
local ATTACK_UNARMED = require("actions.attack_unarmed")
local WEB_RANGE = 4
local SKILL = require("structures.skill_def"):new()
SKILL:setCooldownToNormal()
SKILL.getCastDirection = function(entity, player)
    local entityPos = entity.body:getPosition()
    local playerPos = player.body:getPosition()
    local distance = entityPos:distanceManhattan(playerPos)
    if distance <= WEB_RANGE and distance > 1 then
        if entity.body:isAlignedTo(playerPos) then
            return Common.getDirectionTowards(entityPos, playerPos)
        end

    end

    return false
end
SKILL.indicateArea = function(entity, direction, indicateGrid)
    local position = entity.body:getPosition()
    for i = 1, WEB_RANGE do
        local target = position + Vector[direction] * i
        indicateGrid:set(target, true)
        if not entity.body:isPassable(target) then
            return 
        end

    end

end
local SKILL_BITE = class(ATTACK_UNARMED.BITE)
local SPEED_MULTIPLIER = 0.8
function SKILL_BITE:initialize(entity, direction, abilityStats)
    SKILL_BITE:super(self, "initialize", entity, direction, abilityStats)
    self.forwardDuration = self.forwardDuration / SPEED_MULTIPLIER
    self.biteStart = self.biteStart / SPEED_MULTIPLIER
    self.sound = "PEST_BITE"
end

function SKILL_BITE:process(anchor)
    return SKILL_BITE:super(self, "process", anchor):chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit()
        hit:setDamage(Tags.DAMAGE_TYPE_MELEE, self.entity.stats:getEnemyAbility())
        hit:increaseBonusState()
        hit:applyToPosition(anchor, self.entity.body:getPosition() + Vector[self.direction])
    end)
end

local SKILL_ACTION = class("actions.action")
SKILL.actionClass = SKILL_ACTION
local WEB_SPEED_EXTEND = 0.08
local WEB_SPEED_RETRACT = 0.12
function SKILL_ACTION:initialize(entity, direction, abilityStats)
    SKILL_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("web")
end

function SKILL_ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    self.entity.sprite.layer = Tags.LAYER_ABOVE_EFFECTS
    local source = self.entity.body:getPosition()
    local vDirection = Vector[self.direction]
    local target = false
    for i = 1, WEB_RANGE do
        target = source + vDirection * i
        if not self.entity.body:isPassable(target) then
            break
        end

    end

    self.web.target = target
    Common.playSFX("THROW")
    local distance = source:distanceManhattan(target)
    currentEvent = self.web:chainExtendEvent(currentEvent, WEB_SPEED_EXTEND * distance):chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit()
        hit.sound = "GENERIC_HIT"
        hit:setKnockback(source:distanceManhattan(target) - 1, reverseDirection(self.direction), WEB_SPEED_RETRACT, false, true)
        hit:applyToPosition(anchor, target)
    end)
    local attackEvent = currentEvent
    if distance > 2 then
        attackEvent = attackEvent:chainProgress(WEB_SPEED_RETRACT * (distance - 2))
    end

    attackEvent:chainEvent(function(_, anchor)
        if not self.entity.body:isPassable(source + vDirection) then
            local attackAction = self.entity.actor:create(SKILL_BITE, self.direction)
            attackAction:parallelChainEvent(anchor)
        end

    end)
    return self.web:chainRetractEvent(currentEvent, WEB_SPEED_RETRACT * distance)
end

local function shouldCancel(entity, direction, playerPosition)
    return not entity.body:isPassable(entity.body:getPosition() + Vector[direction])
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(15, 7)
    entity:addComponent("melee")
    entity.melee.attackClass = ATTACK_UNARMED.PEST_BITE_AND_DAMAGE
    entity:addComponent("caster", SKILL)
    entity.caster.alignDistance = WEB_RANGE - 1
    entity.caster.shouldCancel = shouldCancel
end

