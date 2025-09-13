local Vector = require("utils.classes.vector")
local ATTACK_UNARMED = require("actions.attack_unarmed")
local ACTIONS_COMMON = require("actions.common")
local ActionUtils = require("actions.utils")
local Common = require("common")
local SKILL_AREA = 5
local SKILL = require("structures.skill_def"):new()
SKILL:setCooldownToNormal()
SKILL.getCastDirection = function(entity, player, rng)
    local entityPos = entity.body:getPosition()
    local playerPos = player.body:getPosition()
    if entityPos:distanceManhattan(playerPos) > 2 then
        return false
    end

    if entityPos:distanceManhattan(playerPos) == 2 then
        if entityPos.x == playerPos.x or entityPos.y == playerPos.y then
            return 
        end

    end

    return Common.getDirectionTowards(entityPos, playerPos, rng)
end
SKILL.indicateArea = function(entity, direction, indicateGrid)
    local source = entity.body:getPosition()
    for position in (ActionUtils.getCleavePositions(source, SKILL_AREA, direction))() do
        indicateGrid:set(position, true)
    end

end
local CLAW_DURATION = 0.33
local SKILL_ACTION = class(ACTIONS_COMMON.AREA_CLAW)
SKILL.actionClass = SKILL_ACTION
function SKILL_ACTION:initialize(entity, direction, abilityStats)
    SKILL_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.duration = CLAW_DURATION
    self.area = SKILL_AREA
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(13, 5)
    entity:addComponent("melee")
    entity.melee.attackClass = ATTACK_UNARMED.BITE_AND_DAMAGE
    entity:addComponent("caster", SKILL)
end

