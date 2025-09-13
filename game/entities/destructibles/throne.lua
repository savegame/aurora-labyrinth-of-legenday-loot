return function(entity, position, currentFloor)
    require("entities.common_destructible")(entity, position, currentFloor, 2)
    entity.sprite.frameType = Tags.FRAME_STATIC
    entity.sprite:setCell(8, 3)
    entity.body.cantBeMoved = true
end

