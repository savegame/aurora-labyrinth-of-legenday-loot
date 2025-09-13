local Common = require("common")
local COLORS = require("draw.colors")
local ATTACK_UNARMED = require("actions.attack_unarmed")
local ATTACK = class(ATTACK_UNARMED.CLAW_AND_DAMAGE)
local BUFFS = require("definitions.buffs")
local COLD_DURATION = 2
function ATTACK:decorateAction(action)
    action.claw.color = COLORS.STANDARD_ICE
end

function ATTACK:createHit()
    local hit = ATTACK:super(self, "createHit")
    hit:addBuff(BUFFS:get("COLD"):new(COLD_DURATION))
    Common.playSFX("ICE_DAMAGE", 1, 0.2)
    return hit
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(21, 9)
    entity:addComponent("melee")
    entity.melee.attackClass = ATTACK
end

