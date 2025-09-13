local Vector = require("utils.classes.vector")
return function(command)
    local level = command.level
    for position, value in level.objectPositions() do
        if value == "%" then
            level:setObject(position, "wall_torch", DOWN)
        end

    end

end

