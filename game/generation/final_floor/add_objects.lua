local Vector = require("utils.classes.vector")
return function(command)
    local level = command.level
    for position, value in level.objectPositions() do
                                                                                        if value == "a" then
            level:setObject(position, "destructibles.throne", command.currentFloor)
        elseif value == "b" then
            level:setObject(position, "destructibles.pot", command.currentFloor, 1)
        elseif value == "d" then
            level:setObject(position, "destructibles.pot", command.currentFloor, 1, 4)
        elseif value == "h" then
            level:setObject(position, "destructibles.health_pedestal", command.currentFloor)
        elseif value == "m" then
            level:setObject(position, "mana_fountain", command.currentFloor)
        elseif value == "r" then
            level:setObject(position, "destructibles.red_barrel", command.currentFloor)
        elseif value == "i" then
            level:setObject(position, "destructibles.blue_barrel", command.currentFloor)
        elseif value == "f" then
            level:setObject(position, "destructibles.red_cauldron", command.currentFloor)
        elseif value == "g" then
            level:setObject(position, "destructibles.green_cauldron", command.currentFloor)
        elseif value == "c" then
            level:setObject(position, "spikes", command.currentFloor)
        elseif value == "p" then
            level:setObject(position, "acid_pool_permanent", command.currentFloor)
        end

    end

end

