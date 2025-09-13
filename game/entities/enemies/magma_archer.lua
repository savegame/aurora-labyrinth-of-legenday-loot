return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.enemies.drow_archer")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(7, 10)
end

