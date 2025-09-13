local Vector = require("utils.classes.vector")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ON_HIT = class(ACTIONS_FRAGMENT.EXPLOSIVE_HIT)
local KNOCKBACK_STEP_DURATION = 0.1
function ON_HIT:initialize(entity, direction, abilityStats)
    ON_HIT:super(self, "initialize", entity, direction, abilityStats)
    self.explosion:setHueToArcane()
end

function ON_HIT:parallelResolve(anchor)
    ON_HIT:super(self, "parallelResolve", anchor)
    self.hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_RANGED, self.abilityStats)
    local range = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
    self.hit:setKnockback(range, self.direction, KNOCKBACK_STEP_DURATION)
    self.hit:setKnockbackDamage(self.abilityStats)
end

return function(entity, position, sourceEntity, direction, abilityStats)
    entity:addComponent("serializable", sourceEntity, direction, abilityStats)
    require("entities.projectiles.common")(entity, position, direction, Vector:new(1, 2), true)
    entity.projectile.speed = abilityStats:get(Tags.STAT_ABILITY_PROJECTILE_SPEED)
    entity.projectile.onHitAction = sourceEntity.actor:create(ON_HIT, direction, abilityStats)
end

