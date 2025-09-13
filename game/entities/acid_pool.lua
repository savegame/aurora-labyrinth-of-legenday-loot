local OPACITY = 0.65
local BUFFS = require("definitions.buffs")
local CONSTANTS = require("logic.constants")
local POISON_HIT = class("actions.hit")
local POISON_POOL_PERISH = 12
return function(entity, position, poisonDuration, poisonDamage, isPermanent)
    entity:addComponent("serializable", poisonDuration, poisonDamage, isPermanent)
    entity:addComponent("hitter")
    entity:addComponent("steppable", position, Tags.STEP_EXCLUSIVE_LIQUID)
    entity.steppable.canStep = function(stepper)
                if stepper:hasComponent("acidspit") then
            return false
        elseif stepper:hasComponent("stats") and stepper.stats:has(Tags.STAT_POISON_POOL_IMMUNE) then
            return false
        end

        return true
    end
    entity.steppable.onStep = function(anchor, entity, stepper)
        local hit = entity.hitter:createHit()
        hit.sound = "POISON_DAMAGE"
        hit:addBuff(BUFFS:get("POISON"):new(poisonDuration, entity, poisonDamage))
        hit:applyToEntity(anchor, stepper)
        if not isPermanent then
            anchor:chainEvent(function()
                entity.steppable:removeFromGrid()
                entity.sprite.isRemoved = true
                entity.perishable.perishing = false
                entity.perishable.duration = math.huge
            end)
        end

    end
    entity.steppable.stepCost = CONSTANTS.AVOID_COST_MEDIUM
    entity:addComponent("sprite")
    entity.sprite:setCell(3, 10)
    entity.sprite.opacity = OPACITY
    entity.sprite.shadowType = false
    entity.sprite.layer = Tags.LAYER_STEPPABLE
    if isPermanent then
        entity.sprite.alwaysVisible = true
    else
        entity:addComponent("perishable", POISON_POOL_PERISH)
    end

    entity:addComponent("label", "Poison Pool")
end

