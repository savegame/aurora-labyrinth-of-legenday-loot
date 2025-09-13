local Vector = require("utils.classes.vector")
local ACTION_CONSTANTS = require("actions.constants")
local COLORS = require("draw.colors")
local Common = require("common")
local ITEM = Vector:new(15, 4)
return function(entity, position, scrapReward)
    entity:addComponent("serializable", scrapReward)
    entity:addComponent("steppable", position)
    entity.steppable.canStep = function(stepper)
        return stepper:hasComponent("player")
    end
    entity:addComponent("item", ITEM)
    entity:addComponent("indicator", "ITEM")
    entity.steppable.onStep = function(anchor, entity, stepper)
        Common.playSFX("SALVAGE")
        stepper.wallet:add(scrapReward)
        stepper.charactereffects:flash(ACTION_CONSTANTS.STANDARD_FLASH_DURATION, COLORS.STANDARD_STEEL)
        entity:delete()
    end
end

