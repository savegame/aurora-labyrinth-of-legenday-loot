local ON_HIT = class("actions.hit")
local Vector = require("utils.classes.vector")
function ON_HIT:parallelResolve(anchor)
    ON_HIT:super(self, "parallelResolve", anchor)
    self.hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_RANGED, self.abilityStats)
    if self.abilityStats:get(Tags.STAT_ABILITY_FLAG, 0) > 0 then
        self.hit:increaseBonusState()
    end

end

function ON_HIT:process(currentEvent)
    currentEvent = ON_HIT:super(self, "process", currentEvent)
    if self.entity.body:canBePassable(self.targetPosition) then
        local newStats = self.abilityStats:clone()
        newStats:add(Tags.STAT_ABILITY_DAMAGE_MIN, newStats:get(Tags.STAT_SECONDARY_DAMAGE_MIN))
        newStats:add(Tags.STAT_ABILITY_DAMAGE_MAX, newStats:get(Tags.STAT_SECONDARY_DAMAGE_MAX))
        newStats:set(Tags.STAT_ABILITY_FLAG, 1)
        self.entity.projectilespawner:spawnChild(currentEvent, "sharp_spear", self.targetPosition, self.direction, newStats)
    end

    return currentEvent
end

return function(entity, position, sourceEntity, direction, abilityStats)
    entity:addComponent("serializable", sourceEntity, direction, abilityStats)
    require("entities.projectiles.common")(entity, position, direction, Vector:new(1, 2), false)
    entity.projectile.speed = abilityStats:get(Tags.STAT_ABILITY_PROJECTILE_SPEED)
    entity.projectile.onHitAction = sourceEntity.actor:create(ON_HIT, direction, abilityStats)
end

