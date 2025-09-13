return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.enemies.goblin_rogue")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(6, 10)
end

