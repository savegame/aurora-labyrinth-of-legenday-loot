local OPACITY = 0.65
local LogicMethods = require("logic.methods")
local DURATION = 5
local DAMAGE = 20
return function(entity, position, currentFloor)
    require("entities.acid_pool")(entity, position, DURATION, LogicMethods.getFloorDependentValue(currentFloor, DAMAGE), true)
end

