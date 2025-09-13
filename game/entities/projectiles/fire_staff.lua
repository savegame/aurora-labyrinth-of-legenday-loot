local Vector = require("utils.classes.vector")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ON_HIT = class(ACTIONS_FRAGMENT.EXPLOSIVE_HIT)
function ON_HIT:parallelResolve(anchor)
    ON_HIT:super(self, "parallelResolve", anchor)
    self.hit = false
    self.sound = "EXPLOSION_MEDIUM"
end

function ON_HIT:process(currentEvent)
    currentEvent = ON_HIT:super(self, "process", currentEvent)
    local area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    local positions = ActionUtils.getAreaPositions(self.entity, self.targetPosition, area)
    for position in positions() do
        if position ~= self.entity.body:getPosition() then
            local hit = self.entity.hitter:createHit()
            hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_RANGED, self.abilityStats)
            hit:setSpawnFireFromSecondary(self.abilityStats)
            hit:applyToPosition(currentEvent, position)
        end

    end

    return currentEvent
end

return function(entity, position, sourceEntity, direction, abilityStats)
    entity:addComponent("serializable", sourceEntity, direction, abilityStats)
    require("entities.projectiles.common")(entity, position, direction, Vector:new(2, 1), true)
    entity.projectile.speed = abilityStats:get(Tags.STAT_ABILITY_PROJECTILE_SPEED)
    entity.projectile.onHitAction = sourceEntity.actor:create(ON_HIT, direction, abilityStats)
end

