local Vector = require("utils.classes.vector")
local BUFFS = require("definitions.buffs")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ATTACK = class(ATTACK_WEAPON.SWING_AND_DAMAGE)
local SPEED_MULTIPLIER = 0.45
function ATTACK:initialize(entity, direction, abilityStats)
    ATTACK:super(self, "initialize", entity, direction, abilityStats)
    self:speedMultiply(SPEED_MULTIPLIER)
end

function ATTACK:process(currentEvent)
    return ATTACK:super(self, "process", currentEvent):chainEvent(function()
        self.entity.buffable:apply(BUFFS:get("STUN_HIDDEN"):new(1))
    end)
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.agent.avoidsReserved = false
    entity.sprite:setCell(10, 8)
    entity.stats:set(Tags.STAT_MOVEMENT_SLOW, 1)
    entity:callIfHasComponent("elite", "fixMovementSlow")
    entity:addComponent("melee")
    entity.melee.swingIcon = Vector:new(4, 15)
    entity.melee.attackClass = ATTACK
end

