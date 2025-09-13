local Vector = require("utils.classes.vector")
local BUFFS = require("definitions.buffs")
local ON_HIT = class("actions.hit")
function ON_HIT:parallelResolve(anchor)
    ON_HIT:super(self, "parallelResolve", anchor)
    local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
    local poisonDamage = self.abilityStats:get(Tags.STAT_POISON_DAMAGE_TOTAL)
    self.hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_RANGED, self.abilityStats)
    self.hit:addBuff(BUFFS:get("POISON"):new(duration, self.entity, poisonDamage))
end

return function(entity, position, sourceEntity, direction, abilityStats)
    entity:addComponent("serializable", sourceEntity, direction, abilityStats)
    require("entities.projectiles.common")(entity, position, direction, Vector:new(2, 2), false)
    entity.projectile.speed = abilityStats:get(Tags.STAT_ABILITY_PROJECTILE_SPEED)
    entity.projectile.onHitAction = sourceEntity.actor:create(ON_HIT, direction, abilityStats)
end

