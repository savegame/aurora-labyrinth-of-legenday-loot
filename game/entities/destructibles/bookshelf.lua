return function(entity, position, currentFloor, variantIndex)
    require("entities.common_destructible")(entity, position, currentFloor)
    entity.serializable:addArg(variantIndex)
    entity.sprite.frameType = Tags.FRAME_STATIC
    entity.sprite:setCell(2 + variantIndex, 3)
    entity.sprite.shadowType = 2
    entity.body.cantBeMoved = true
end

