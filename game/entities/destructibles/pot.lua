return function(entity, position, currentFloor, tankIndex, variantIndex)
    require("entities.destructibles.common_tank_dependent")(entity, position, currentFloor, tankIndex)
    entity.serializable:addArg(variantIndex)
    if not variantIndex then
                                                        if currentFloor <= 4 then
            variantIndex = 3
        elseif currentFloor <= 8 then
            variantIndex = 1
        elseif currentFloor <= 12 then
            variantIndex = 4
        elseif currentFloor <= 16 then
            variantIndex = 3
        elseif currentFloor <= 20 then
            variantIndex = 4
        elseif currentFloor <= 24 then
            variantIndex = 3
        elseif currentFloor == 25 then
            variantIndex = 5
        end

    end

    entity.sprite:setCell(1, variantIndex)
end

