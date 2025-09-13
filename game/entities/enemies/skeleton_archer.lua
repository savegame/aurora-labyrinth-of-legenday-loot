local ACTIONS_COMMON = require("actions.common")
return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(18, 9)
    entity:addComponent("projectilespawner")
    entity.projectilespawner:setCell(1, 1)
    entity.projectilespawner.isMagical = false
    entity:addComponent("ranged")
    entity.ranged.attackClass = ACTIONS_COMMON.ARROW_SHOOT
    entity.ranged.attackCooldown = 2
end

