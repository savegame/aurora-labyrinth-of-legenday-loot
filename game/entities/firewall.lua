local CONSTANTS = require("logic.constants")
local FIREWALL_HIT = class("actions.hit")
return function(entity, position, duration, minDamage, maxDamage, sourceEntity, noVision)
    entity:addComponent("serializable", duration, minDamage, maxDamage, sourceEntity, noVision)
    entity:addComponent("steppable", position, Tags.STEP_EXCLUSIVE_ENGULF)
    entity.steppable.onStep = function(anchor, entity, stepper)
        local hit = sourceEntity.hitter:createHit()
        hit:setDamage(Tags.DAMAGE_TYPE_BURN, minDamage, maxDamage)
        hit:applyToEntity(anchor, stepper)
    end
    if sourceEntity:hasComponent("player") then
        entity.steppable.stepCost = CONSTANTS.AVOID_COST_LOW
    else
        entity.steppable.stepCost = CONSTANTS.AVOID_COST_MEDIUM
    end

    entity:addComponent("sprite")
    entity.sprite:setCell(11, 6)
    entity.sprite.layer = Tags.LAYER_ENGULF
    entity:addComponent("charactereffects")
    entity:addComponent("perishable", duration)
    if not noVision then
        entity:addComponent("visionprovider")
    end

    entity:addComponent("ambience", "AMBIENT_FIRE")
    entity:addComponent("label", "Burn")
    entity.label.properNoun = true
end

