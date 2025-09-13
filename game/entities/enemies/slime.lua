local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local Common = require("common")
local ATTACK_UNARMED = require("actions.attack_unarmed")
local ACTIONS_BASIC = require("actions.basic")
local POISON_DURATION = 3
local SLIME_DIE = class(ACTIONS_BASIC.DIE)
local TRAVEL_DURATION = 0.13
function SLIME_DIE:initialize(entity, direction, abilityStats)
    SLIME_DIE:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("acidspit")
end

function SLIME_DIE:process(currentEvent)
    SLIME_DIE:super(self, "process", currentEvent)
    local killerPosition = Common.getPositionComponent(self.killer):getPosition()
    local directionTo = Common.getDirectionTowards(self.position, killerPosition, self:getLogicRNG())
    local directions = Array:new(cwDirection(directionTo), ccwDirection(directionTo))
    local lastEvent
    for direction in directions() do
        local target = self.position + Vector[direction]
        lastEvent = self.acidspit:chainSpitEvent(currentEvent, TRAVEL_DURATION, target)
        lastEvent = lastEvent:chainEvent(function(_, anchor)
            self.entity.acidspit:applyToPosition(anchor, target)
        end)
    end

    return currentEvent
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(20, 6)
    entity:addComponent("melee")
    entity.melee.attackClass = ATTACK_UNARMED.TACKLE_AND_DAMAGE
    entity.tank.deathActionClass = SLIME_DIE
    entity:addComponent("acidspit")
    entity.acidspit.poisonDuration = POISON_DURATION
end

