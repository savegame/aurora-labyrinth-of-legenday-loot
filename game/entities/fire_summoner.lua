local CONSTANTS = require("logic.constants")
local LogicMethods = require("logic.methods")
local Common = require("common")
local FIRE_DAMAGE = 10
local FIRE_VARIANCE = Common.getVarianceForRatio(0.6)
local TIMER = 1
return function(entity, position, currentFloor, cooldown, duration, delay)
    entity:addComponent("serializable", currentFloor, cooldown, duration, delay)
    entity:addComponent("steppable", position)
    entity.steppable.stepCost = CONSTANTS.AVOID_COST_MEDIUM_LOW
    entity:addComponent("turntimer")
    entity.turntimer:setCooldown(TIMER, cooldown)
    entity.turntimer:setOnCooldown(TIMER, delay)
    entity.turntimer.onReady:set(TIMER, function(entity, anchor)
        local hit = entity.hitter:createHit()
        local minDamage, maxDamage = LogicMethods.getFloorDependentValues(currentFloor, FIRE_DAMAGE, FIRE_VARIANCE)
        hit:setDamage(Tags.DAMAGE_TYPE_BURN, minDamage, maxDamage)
        hit:setSpawnFire(duration, minDamage, maxDamage)
        hit.spawnFire.noVision = true
        hit:applyToPosition(anchor, entity.steppable:getPosition())
        entity.turntimer:setOnCooldown(TIMER)
    end)
    entity:addComponent("hitter")
    entity:addComponent("sprite")
    entity.sprite:setCell(3, 10)
    entity.sprite.frameType = Tags.FRAME_STATIC
    entity.sprite.shadowType = false
    entity.sprite.layer = Tags.LAYER_STEPPABLE
    entity.sprite.alwaysVisible = true
    entity:addComponent("label", "Fire River")
end

