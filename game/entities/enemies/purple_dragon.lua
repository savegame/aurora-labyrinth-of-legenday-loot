local Vector = require("utils.classes.vector")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ATTACK_UNARMED = require("actions.attack_unarmed")
local ACTIONS_COMMON = require("actions.common")
local COLORS = require("draw.colors")
local SKILL = require("structures.skill_def"):new()
SKILL:setCooldownToNormal()
SKILL.getCastDirection = function(entity, player)
    local entityPos = entity.body:getPosition()
    local playerPos = player.body:getPosition()
    local direction = Common.getDirectionTowards(entityPos, playerPos)
    local front = entityPos + Vector[direction]
    if playerPos == front then
        return direction
    end

    if not entity.body:isPassable(front) then
        return false
    end

    for target in (ActionUtils.getTriangleBreathPositions(entityPos, direction))() do
        if playerPos == target then
            return direction
        end

    end

    return false
end
SKILL.indicateArea = function(entity, direction, indicateGrid)
    local position = entity.body:getPosition()
    local targets = ActionUtils.getTriangleBreathPositions(entity.body:getPosition(), direction)
    for target in targets() do
        indicateGrid:set(target, true)
    end

end
local SKILL_ACTION = class(ACTIONS_COMMON.TRIANGLE_BREATH)
SKILL.actionClass = SKILL_ACTION
function SKILL_ACTION:initialize(entity, direction, abilityStats)
    SKILL_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = COLORS.STANDARD_PSYCHIC
    self.acidspit:setToArcane()
end

function SKILL_ACTION:affectPosition(anchor, target)
    Common.playSFX("EXPLOSION_SMALL")
    local hit = self.entity.hitter:createHit()
    hit:setDamage(Tags.DAMAGE_TYPE_SPELL, self.entity.stats:getEnemyAbility())
    hit:increaseBonusState()
    hit:applyToPosition(anchor, target)
end

local function shouldCancel(entity, direction, playerPosition)
    local minTarget = entity.body:getPosition() + Vector[direction]
    return not entity.body:canBePassable(minTarget)
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(3, 6)
    entity:addComponent("melee")
    entity.melee.attackClass = ATTACK_UNARMED.BITE_AND_DAMAGE
    entity:addComponent("caster", SKILL)
    entity.caster.alignDistance = 2
    entity.caster.shouldCancel = shouldCancel
end

