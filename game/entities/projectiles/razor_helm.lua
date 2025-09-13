local ON_HIT = class("actions.hit")
local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
function ON_HIT:parallelResolve(anchor)
    ON_HIT:super(self, "parallelResolve", anchor)
    self.hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_RANGED, self.abilityStats)
end

function ON_HIT:process(currentEvent)
    currentEvent = ON_HIT:super(self, "process", currentEvent)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        if self.entity.body:canBePassable(self.targetPosition) then
            local newStats = self.abilityStats:clone()
            for direction in Array:new(cwDirection(self.direction), ccwDirection(self.direction))() do
                self.entity.projectilespawner:spawnChild(currentEvent, "normal", self.targetPosition, direction, self.abilityStats, Vector:new(2, 1), false)
            end

        end

    end

    return currentEvent
end

return function(entity, position, sourceEntity, direction, abilityStats)
    entity:addComponent("serializable", sourceEntity, direction, abilityStats)
    require("entities.projectiles.common")(entity, position, direction, Vector:new(2, 1), false)
    entity.projectile.speed = abilityStats:get(Tags.STAT_ABILITY_PROJECTILE_SPEED)
    entity.projectile.onHitAction = sourceEntity.actor:create(ON_HIT, direction, abilityStats)
end

