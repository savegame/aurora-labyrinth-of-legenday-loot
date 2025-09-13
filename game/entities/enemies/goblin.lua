local Vector = require("utils.classes.vector")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTIONS_FRAGMENT = require("actions.fragment")
local RANGED_ATTACK = class("actions.action")
function RANGED_ATTACK:process(currentEvent)
    local throwAction = self.entity.actor:create(ACTIONS_FRAGMENT.THROW, self.direction)
    return throwAction:parallelChainEvent(currentEvent):chainEvent(function(_, anchor)
        self.entity.projectilespawner:spawn(anchor, self.direction)
    end)
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(21, 8)
    entity:addComponent("melee")
    entity.melee.swingIcon = Vector:new(15, 10)
    entity.melee.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
    entity:addComponent("projectilespawner")
    entity.projectilespawner:setCell(2, 1)
    entity:addComponent("ranged")
    entity.ranged.attackClass = RANGED_ATTACK
    entity.ranged.attackCooldown = math.huge
    entity.ranged.alignBackOff = false
end

