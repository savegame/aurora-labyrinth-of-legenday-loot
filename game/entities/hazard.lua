local CONSTANTS = require("logic.constants")
return function(entity, position)
    entity:addComponent("serializable")
    entity:addComponent("steppable", position, false)
    entity.steppable.stepCost = CONSTANTS.AVOID_COST_MEDIUM
    entity:addComponent("perishable", 2)
end

