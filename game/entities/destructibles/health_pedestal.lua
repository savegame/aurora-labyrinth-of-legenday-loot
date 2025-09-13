return function(entity, position, currentFloor)
    require("entities.common_destructible")(entity, position, currentFloor)
    entity.sprite.frameType = Tags.FRAME_STATIC
    entity.sprite:setCell(5, 9)
    entity.stats:set(Tags.STAT_MAX_HEALTH, 1)
    entity.tank.orbChance = 1
    entity.tank.orbSize = 2
    entity.tank:restoreToFull()
    entity.body.cantBeMoved = true
end

