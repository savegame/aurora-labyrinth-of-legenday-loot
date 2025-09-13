local Vector = require("utils.classes.vector")
local Common = require("common")
local ATTACK_UNARMED = require("actions.attack_unarmed")
local ACTIONS_FRAGMENT = require("actions.fragment")
local SKILL = require("structures.skill_def"):new()
local SKILL_RANGE = 3
local POISON_DURATION = 5
SKILL:setCooldownToNormal()
SKILL.getCastDirection = function(entity, player)
    local entityPos = entity.body:getPosition()
    local playerPos = player.body:getPosition()
    local distance = entityPos:distanceManhattan(playerPos)
    if distance <= SKILL_RANGE then
        if entity.body:isAlignedTo(playerPos) then
            return Common.getDirectionTowards(entityPos, playerPos)
        end

    end

    return false
end
SKILL.indicateArea = function(entity, direction, indicateGrid)
    local position = entity.body:getPosition()
    for i = 1, SKILL_RANGE do
        local target = position + Vector[direction] * i
        indicateGrid:set(target, true)
        if not entity.body:isPassable(target) then
            return 
        end

    end

end
local SKILL_ACTION = class("actions.action")
SKILL.actionClass = SKILL_ACTION
local TRAVEL_DURATION = 0.14
function SKILL_ACTION:initialize(entity, direction, abilityStats)
    SKILL_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("acidspit")
end

function SKILL_ACTION:process(currentEvent)
    if self.direction == LEFT or self.direction == RIGHT then
        self.entity.sprite.layer = Tags.LAYER_ABOVE_EFFECTS
    end

    local source = self.entity.body:getPosition()
    local hitTarget
    local isPassable = true
    local vDirection = Vector[self.direction]
    for i = 1, SKILL_RANGE do
        hitTarget = source + vDirection * i
        if not self.entity.body:isPassable(hitTarget) then
            isPassable = false
            break
        end

    end

    local entityAt = self.entity.body:getEntityAt(hitTarget)
    local distance = source:distanceManhattan(hitTarget)
    local throwAction = self.entity.actor:create(ACTIONS_FRAGMENT.THROW, self.direction)
    throwAction.sound = "VENOM_SPIT"
    currentEvent = throwAction:parallelChainEvent(currentEvent)
    self.acidspit:chainSpitEvent(currentEvent, distance * TRAVEL_DURATION, function()
        return hitTarget
    end)
    return currentEvent:chainProgress((distance - 0.5) * TRAVEL_DURATION):chainEvent(function()
        if not self.entity.body:canBePassable(hitTarget) then
            hitTarget = hitTarget - vDirection
            self.acidspit.source = hitTarget + vDirection * distance
        end

    end):chainProgress(TRAVEL_DURATION * 0.5):chainEvent(function(_, anchor)
        self.entity.acidspit:applyToPosition(anchor, hitTarget)
    end)
end

local function shouldCancel(entity, direction)
    return not entity.body:isPassable(entity.body:getPosition() + Vector[direction])
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(12, 7)
    entity:addComponent("melee")
    entity.melee.swingIcon = Vector:new(5, 15)
    entity.melee.attackClass = ATTACK_UNARMED.PEST_BITE_AND_DAMAGE
    entity:addComponent("caster", SKILL)
    entity.caster.alignDistance = SKILL_RANGE
    entity.caster.shouldCancel = shouldCancel
    entity:addComponent("acidspit")
    entity.acidspit.poisonDuration = POISON_DURATION
end

