local Vector = require("utils.classes.vector")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local BUFFS = require("definitions.buffs")
local ON_HIT = class(ACTIONS_FRAGMENT.EXPLOSIVE_HIT)
function ON_HIT:initialize(entity, direction, abilityStats)
    ON_HIT:super(self, "initialize", entity, direction, abilityStats)
    self.explosion:setHueToIce()
    self.sound = "EXPLOSION_ICE"
end

function ON_HIT:parallelResolve(anchor)
    ON_HIT:super(self, "parallelResolve", anchor)
    local area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    self.explosion:setArea(area)
    local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
    self.hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_RANGED, self.abilityStats)
    self.hit:addBuff(BUFFS:get("COLD"):new(duration))
    local positions = ActionUtils.getAreaPositions(self.entity, self.targetPosition, area, true)
    for position in positions() do
        if position ~= self.entity.body:getPosition() then
            local hit = self.entity.hitter:createHit()
            hit:setDamageFromSecondaryStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
            hit:addBuff(BUFFS:get("COLD"):new(duration))
            hit:applyToPosition(anchor, position)
        end

    end

end

return function(entity, position, sourceEntity, direction, abilityStats)
    entity:addComponent("serializable", sourceEntity, direction, abilityStats)
    require("entities.projectiles.common")(entity, position, direction, Vector:new(1, 1), true)
    entity.projectile.speed = abilityStats:get(Tags.STAT_ABILITY_PROJECTILE_SPEED)
    entity.projectile.onHitAction = sourceEntity.actor:create(ON_HIT, direction, abilityStats)
end

