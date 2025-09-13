local Vector = require("utils.classes.vector")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local RANGED_ATTACK = class("actions.action")
local JUMP_HEIGHT = 0.1
local STEP_DURATION = ACTION_CONSTANTS.WALK_DURATION
function RANGED_ATTACK:initialize(entity, direction, abilityStats)
    RANGED_ATTACK:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("move")
    self.move.distance = 1
end

function RANGED_ATTACK:parallelResolve(anchor)
    self.entity.sprite:turnToDirection(self.direction)
    if self.entity.body:isPassableDirection(self.direction) then
        self.move:prepare(anchor)
    else
        self.move.distance = 0
    end

end

function RANGED_ATTACK:process(currentEvent)
    if self.move.distance > 0 then
        self.move:chainMoveEvent(currentEvent, STEP_DURATION)
    end

    local attackAction = self.entity.actor:create(ATTACK_WEAPON.STAB_AND_DAMAGE, self.direction)
    return attackAction:parallelChainEvent(currentEvent)
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(15, 8)
    entity:addComponent("melee")
    entity.melee.swingIcon = Vector:new(15, 10)
    entity.melee.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
    entity:addComponent("ranged")
    entity.ranged.attackClass = RANGED_ATTACK
    entity.ranged.attackCooldown = 1
    entity.ranged.alignBackOff = false
    entity.ranged.range = 2
end

