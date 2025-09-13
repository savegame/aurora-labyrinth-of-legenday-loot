local Vector = require("utils.classes.vector")
local ATTACK_UNARMED = require("actions.attack_unarmed")
return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(14, 7)
    entity:addComponent("melee")
    entity.melee.attackClass = ATTACK_UNARMED.PEST_BITE_AND_DAMAGE
end

