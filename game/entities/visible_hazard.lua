local CONSTANTS = require("logic.constants")
return function(entity, position)
    require("entities.hazard")(entity, position)
    entity:addComponent("visionprovider")
end

