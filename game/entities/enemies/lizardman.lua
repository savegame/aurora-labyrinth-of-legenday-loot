local Vector = require("utils.classes.vector")
local ATTACK_WEAPON = require("actions.attack_weapon")
return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(17, 5)
    entity:addComponent("melee")
    entity.melee.swingIcon = Vector:new(5, 15)
    entity.melee.attackClass = ATTACK_WEAPON.STAB_AND_DAMAGE
    entity:addComponent("ranged")
    entity.ranged.attackClass = ATTACK_WEAPON.STAB_EXTENDED_AND_DAMAGE
    entity.ranged.attackCooldown = 1
    entity.ranged.alignBackOff = false
    entity.ranged.range = 2
end

