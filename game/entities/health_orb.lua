local Vector = require("utils.classes.vector")
local Common = require("common")
local ActionUtils = require("actions.utils")
local CONSTANTS = require("logic.constants")
local HEALTH_ORB_PERISH = 40
local SCRAP_ORB_PERISH = 80
local FAT_ORB_PERISH = 80
return function(entity, position, scrapReward, orbSize)
    entity:addComponent("serializable", scrapReward, orbSize)
    entity:addComponent("hitter")
    entity:addComponent("steppable", position)
    entity.steppable.canStep = function(stepper)
        return stepper:hasComponent("player")
    end
    local perishTime = HEALTH_ORB_PERISH
    local item = Vector:new(7, 15)
        if scrapReward > 0 then
        item = Vector:new(8, 15)
        perishTime = SCRAP_ORB_PERISH
    elseif orbSize > 1 then
        item = Vector:new(9, 15)
        perishTime = FAT_ORB_PERISH
    end

    entity:addComponent("item", item)
    entity:addComponent("offset")
    entity:addComponent("perishable", perishTime)
    entity.steppable.onStep = function(anchor, entity, stepper)
        local hit = entity.hitter:createHit()
        local value = stepper.tank:getMax() * CONSTANTS.HEALTH_ORB_RESTORE * orbSize
        hit:setDamage(Tags.DAMAGE_TYPE_HEALTH_ORB, -value, -value)
        hit:applyToEntity(anchor, stepper)
        if scrapReward and scrapReward > 0 then
            Common.playSFX("SALVAGE")
            stepper.wallet:add(scrapReward)
        end

        stepper.publisher:publish(Tags.UI_HEALTH_ORB_PICKUP, scrapReward and scrapReward > 0)
        entity:delete()
    end
end

