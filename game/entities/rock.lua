local Vector = require("utils.classes.vector")
local LogicMethods = require("logic.methods")
local CONSTANTS = require("logic.constants")
local TANK_DEPENDENT_RATIO = require("utils.classes.hash"):new({ [1] = 1, [2] = 1, [3] = 0.7, [4] = 0.4 })
return function(entity, position, health, isEarth, tankIndex)
    entity:addComponent("serializable", health, isEarth, tankIndex)
    entity:addComponent("body", position)
    entity.body.stepCost = function(entity)
        return CONSTANTS.AVOID_COST_MEDIUM + CONSTANTS.AVOID_COST_MEDIUM * entity.tank:getRatio()
    end
    entity:addComponent("sprite")
    entity.sprite.frameType = Tags.FRAME_TANK_DEPENDENT
    entity.sprite.cell = Vector:new(2, 3)
    if isEarth then
        entity.sprite.cell = Vector:new(2, 4)
    end

    entity.sprite.alwaysVisible = true
    entity.sprite.shadowType = false
    entity:addComponent("charactereffects")
    entity:addComponent("offset")
    entity:addComponent("stats")
    entity.stats:set(Tags.STAT_MAX_HEALTH, health)
    entity:addComponent("tank")
    entity.tank:setRatio(TANK_DEPENDENT_RATIO:get(tankIndex or 1))
    entity:addComponent("perishable", math.huge)
    entity:addComponent("actor")
end

