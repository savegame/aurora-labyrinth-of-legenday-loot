local ACTIONS_COMMON = require("actions.common")
local LogicMethods = require("logic.methods")
local Common = require("common")
local BASE_DAMAGE = 30
local VARIANCE = Common.getVarianceForRatio(0.75)
return function(entity, position, currentFloor)
    require("entities.common_destructible")(entity, position, currentFloor)
    entity.sprite.frameType = Tags.FRAME_STATIC
    entity.sprite:setCell(1, 4)
    entity.stats:set(Tags.STAT_MAX_HEALTH, 1)
    local minDamage, maxDamage = LogicMethods.getFloorDependentValues(currentFloor, BASE_DAMAGE, VARIANCE)
    entity.stats:set(Tags.STAT_ABILITY_DAMAGE_MIN, round(minDamage))
    entity.stats:set(Tags.STAT_ABILITY_DAMAGE_MAX, round(maxDamage))
    entity.tank.deathActionClass = ACTIONS_COMMON.BARREL_DEATH
    entity.tank:restoreToFull()
    entity:addComponent("hitter")
    entity:addComponent("label", "Explosive Barrel")
end

