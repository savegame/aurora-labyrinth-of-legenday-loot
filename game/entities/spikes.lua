local CONSTANTS = require("logic.constants")
local Common = require("common")
local LogicMethods = require("logic.methods")
local SPIKE_DAMAGE = 16
local SPIKE_VARIANCE = Common.getVarianceForRatio(0.4)
return function(entity, position, currentFloor)
    entity:addComponent("serializable", currentFloor)
    entity:addComponent("hitter")
    entity:addComponent("stats")
    local minDamage, maxDamage = LogicMethods.getFloorDependentValues(currentFloor, SPIKE_DAMAGE, SPIKE_VARIANCE)
    entity.stats:set(Tags.STAT_ABILITY_DAMAGE_MIN, minDamage)
    entity.stats:set(Tags.STAT_ABILITY_DAMAGE_MAX, maxDamage)
    entity:addComponent("steppable", position, Tags.STEP_EXCLUSIVE_TRAP)
    entity.steppable.onStep = function(anchor, entity, stepper)
        local hit = entity.hitter:createHit()
        hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_MELEE_UNAVOIDABLE, entity.stats)
        hit:applyToEntity(anchor, stepper)
    end
    entity.steppable.stepCost = CONSTANTS.AVOID_COST_VERY_HIGH
    entity:addComponent("sprite")
    entity.sprite:setCell(1, 5)
    entity.sprite.frameType = Tags.FRAME_STATIC
    entity.sprite.shadowType = false
    entity.sprite.layer = Tags.LAYER_STEPPABLE
    entity.sprite.alwaysVisible = true
    entity:addComponent("label", "Spikes")
    entity.label.properNoun = true
end

