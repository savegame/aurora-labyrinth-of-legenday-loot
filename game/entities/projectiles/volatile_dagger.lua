local Vector = require("utils.classes.vector")
local BUFFS = require("definitions.buffs")
local ON_HIT = class("actions.hit")
function ON_HIT:parallelResolve(anchor)
    ON_HIT:super(self, "parallelResolve", anchor)
    local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
    self.hit:setDamageFromSecondaryStats(Tags.DAMAGE_TYPE_RANGED, self.abilityStats)
    self.hit:addBuff(BUFFS:get("TIMED_EXPLOSION"):new(duration, self.entity, self.abilityStats))
end

return function(entity, position, sourceEntity, direction, abilityStats)
    entity:addComponent("serializable", sourceEntity, direction, abilityStats)
    require("entities.projectiles.common")(entity, position, direction, Vector:new(3, 1), false)
    entity.projectile.speed = abilityStats:get(Tags.STAT_ABILITY_PROJECTILE_SPEED)
    entity.projectile.onHitAction = sourceEntity.actor:create(ON_HIT, direction, abilityStats)
end

