local TANK_DEPENDENT_RATIO = require("utils.classes.hash"):new({ [1] = 1, [2] = 1, [3] = 0.7, [4] = 0.4 })
return function(entity, position, currentFloor, tankIndex)
    require("entities.common_destructible")(entity, position, currentFloor)
    entity.serializable:addArg(tankIndex)
    entity.sprite.frameType = Tags.FRAME_TANK_DEPENDENT
    entity.tank:setRatio(TANK_DEPENDENT_RATIO:get(tankIndex))
end

