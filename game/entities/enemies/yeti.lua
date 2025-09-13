local BUFFS = require("definitions.buffs")
local ATTACK_UNARMED = require("actions.attack_unarmed")
local ATTACK = class(ATTACK_UNARMED.CLAW_AND_DAMAGE)
local SPEED_MULTIPLIER = 0.6
function ATTACK:initialize(entity, direction, abilityStats)
    ATTACK:super(self, "initialize", entity, direction, abilityStats)
    self:speedMultiply(SPEED_MULTIPLIER)
end

function ATTACK:decorateAction(action)
    action.jump.height = 0
end

function ATTACK:process(currentEvent)
    return ATTACK:super(self, "process", currentEvent):chainEvent(function()
        self.entity.buffable:delayedApply(BUFFS:get("STUN_HIDDEN"):new(1))
    end)
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.agent.avoidsReserved = false
    entity.sprite:setCell(20, 10)
    entity:addComponent("melee")
    entity.melee.attackClass = ATTACK
end

