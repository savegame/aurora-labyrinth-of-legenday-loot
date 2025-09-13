local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local BUFFS = require("definitions.buffs")
local ACTION_CONSTANTS = require("actions.constants")
local ACTIONS_BASIC = require("actions.basic")
local ATTACK_UNARMED = require("actions.attack_unarmed")
local Common = require("common")
local JUMP_HEIGHT = 0.4
local SLIME_MOVE = class("actions.action")
function SLIME_MOVE:initialize(entity, direction, abilityStats)
    SLIME_MOVE:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("move")
    self.move:setEasingToLinear()
    self:addComponent("jump")
    self.jump.height = JUMP_HEIGHT
end

function SLIME_MOVE:parallelResolve(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    self.move:prepare(currentEvent)
end

function SLIME_MOVE:process(currentEvent)
    self.jump:chainFullEvent(currentEvent, ACTION_CONSTANTS.WALK_DURATION)
    return self.move:chainMoveEvent(currentEvent, ACTION_CONSTANTS.WALK_DURATION, function(anchor, moveTo, moveFrom)
        Common.playSFX("SLIME_LAND")
        self.entity.buffable:delete(anchor, BUFFS:get("IMMUNE_HIDDEN"))
        self.entity.sprite:resetLayer()
    end)
end

local CUBE_DIE = class(ACTIONS_BASIC.DIE)
function CUBE_DIE:spawnSlime(currentEvent, direction)
    local slime = self.entity.entityspawner:spawnEnemy("slime", self.position, direction, 0)
    slime.agent.hasSeenPlayer = true
    slime.buffable:apply(BUFFS:get("IMMUNE_HIDDEN"):new(1))
    slime.tank.orbChance = 0
    local moveAction = slime.actor:create(SLIME_MOVE, direction)
    return moveAction:parallelChainEvent(currentEvent)
end

function CUBE_DIE:process(currentEvent)
    local deathEvent = CUBE_DIE:super(self, "process", currentEvent)
    local rng = self:getLogicRNG()
    local directions = DIRECTIONS_AA:shuffle(rng)
    local killerPosition = Common.getPositionComponent(self.killer):getPosition()
    local directionTo = Common.getDirectionTowards(self.position, killerPosition, rng)
    directions:delete(directionTo)
    directions:delete(reverseDirection(directionTo))
    directions:push(reverseDirection(directionTo))
    directions:push(directionTo)
    local slimeCount = 0
    for direction in directions() do
        if self.entity.body:isPassable(self.position + Vector[direction]) then
            self:spawnSlime(currentEvent, direction)
            slimeCount = slimeCount + 1
            if slimeCount >= 2 then
                break
            end

        end

    end

    return deathEvent
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(2, 8)
    entity:addComponent("melee")
    entity.melee.attackClass = ATTACK_UNARMED.TACKLE_AND_DAMAGE
    entity.tank.deathActionClass = CUBE_DIE
    entity:addComponent("acidspit")
    entity:addComponent("entityspawner")
    entity.entityspawner.enemyDifficulty = difficulty
end

