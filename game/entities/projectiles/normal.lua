local CONSTANTS = require("logic.constants")
local Vector = require("utils.classes.vector")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ON_HIT = class("actions.hit")
function ON_HIT:parallelResolve(anchor)
    ON_HIT:super(self, "parallelResolve", anchor)
    if self.abilityStats then
        self.hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_RANGED, self.abilityStats)
    else
        self.hit:setDamage(Tags.DAMAGE_TYPE_RANGED, self.entity.stats:getAttack())
    end

end

local ON_HIT_MAGIC = class(ACTIONS_FRAGMENT.EXPLOSIVE_HIT)
function ON_HIT_MAGIC:parallelResolve(anchor)
    ON_HIT_MAGIC:super(self, "parallelResolve", anchor)
    if self.abilityStats then
        self.hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_RANGED, self.abilityStats)
        if self.hit.sourceEntity:hasComponent("agent") then
            self.hit:increaseBonusState()
        end

    else
        self.hit:setDamage(Tags.DAMAGE_TYPE_RANGED, self.entity.stats:getAttack())
    end

end

return function(entity, position, sourceEntity, direction, abilityStats, cell, isMagical)
    entity:addComponent("serializable", sourceEntity, direction, abilityStats, cell, isMagical)
    require("entities.projectiles.common")(entity, position, direction, cell, isMagical)
    local projectile = entity.projectile
    if abilityStats then
        projectile.speed = abilityStats:get(Tags.STAT_ABILITY_PROJECTILE_SPEED)
    else
        projectile.speed = CONSTANTS.ENEMY_PROJECTILE_SPEED
    end

    if isMagical then
        projectile.onHitAction = sourceEntity.actor:create(ON_HIT_MAGIC, direction, abilityStats)
                                        if cell == Vector.UNIT_XY then
            projectile.onHitAction.explosion:setHueToIce()
        elseif cell == Vector:new(2, 1) then
        elseif cell == Vector:new(3, 1) then
            projectile.onHitAction.explosion:setHueToDeath()
        elseif cell == Vector:new(1, 2) then
            projectile.onHitAction.explosion:setHueToArcane()
        elseif cell == Vector:new(2, 2) then
            projectile.onHitAction.explosion:setHueToPoison()
        end

    else
        projectile.onHitAction = sourceEntity.actor:create(ON_HIT, direction, abilityStats)
    end

end

