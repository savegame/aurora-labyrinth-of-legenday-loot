local Vector = require("utils.classes.vector")
local BUFFS = require("definitions.buffs")
local ACTIONS_BASIC = require("actions.basic")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local ATTACK_UNARMED = require("actions.attack_unarmed")
local Common = require("common")
local EASING = require("draw.easing")
local ROCK_HEALTH_RATIO = 1 / 3
local SPEED_MULTIPLIER = 0.6
local ATTACK = class(ATTACK_UNARMED.TACKLE_AND_DAMAGE)
function ATTACK:initialize(entity, direction, abilityStats)
    ATTACK:super(self, "initialize", entity, direction, abilityStats)
    self:speedMultiply(SPEED_MULTIPLIER)
end

function ATTACK:process(currentEvent)
    return ATTACK:super(self, "process", currentEvent):chainEvent(function()
        self.entity.buffable:apply(BUFFS:get("STUN_HIDDEN"):new(1))
    end)
end

local SKILL = require("structures.skill_def"):new()
local THROW_RANGE = 3
SKILL:setCooldownToRare()
SKILL.getCastDirection = function(entity, player)
    local entityPos = entity.body:getPosition()
    local playerPos = player.body:getPosition()
    local distance = entityPos:distanceManhattan(playerPos)
    if distance <= THROW_RANGE and distance > 1 then
        if entity.body:isAlignedTo(playerPos) then
            return Common.getDirectionTowards(entityPos, playerPos)
        end

    end

    return false
end
SKILL.indicateArea = function(entity, direction, indicateGrid)
    local position = entity.body:getPosition()
    for i = 1, THROW_RANGE do
        local target = position + Vector[direction] * i
        indicateGrid:set(target, true)
        if not entity.body:isPassable(target) then
            return 
        end

    end

end
local ROCK_FLY = class("actions.action")
local THROW_DURATION = 0.18
local THROW_HEIGHT = 0.4
function ROCK_FLY:initialize(entity, direction, abilityStats)
    ROCK_FLY:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("move")
    self.move:setEasingToLinear()
    self:addComponent("tackle")
    self.tackle.forwardDistance = 0.5
    self.tackle.forwardEasing = EASING.LINEAR
    self.tackle.backEasing = EASING.LINEAR
    self:addComponent("jump")
    self.jump.height = THROW_HEIGHT
    self.minDamage = false
    self.maxDamage = false
    self.sourceEntity = false
end

function ROCK_FLY:process(currentEvent)
    local done = currentEvent:createWaitGroup(1)
    local moveFrom = self.entity.position:getPosition()
    local hitTarget
    for i = 1, THROW_RANGE do
        hitTarget = moveFrom + Vector[self.direction] * i
        if not self.sourceEntity.body:isPassable(hitTarget) then
            break
        end

    end

    self.move.distance = moveFrom:distanceManhattan(hitTarget) - 1
    self.move:prepare(currentEvent)
    self.tackle:createOffset()
    self.tackle.offset.disableModY = true
    self.jump:chainFullEvent(currentEvent, THROW_DURATION * (self.move.distance + 1))
    self.tackle:chainForwardEvent(currentEvent, THROW_DURATION * (self.move.distance + 0.5))
    self.move:chainMoveEvent(currentEvent, THROW_DURATION * (self.move.distance + 0.5)):chainEvent(function(_, anchor)
        local hit = self.sourceEntity.hitter:createHit(moveFrom)
        hit:setDamage(Tags.DAMAGE_TYPE_RANGED, self.minDamage, self.maxDamage)
        hit:increaseBonusState()
        hit:setKnockback(1, self.direction, THROW_DURATION)
        hit:applyToPosition(anchor, hitTarget)
        if (hit.knockback and hit.knockback.distance == 1) or self.sourceEntity.body:isPassable(hitTarget) then
            self.tackle.forwardDistance = 1
            anchor = self.tackle:chainForwardEvent(anchor, THROW_DURATION / 2)
        else
            anchor = self.tackle:chainBackEvent(anchor, THROW_DURATION / 2)
            hitTarget = hitTarget - Vector[self.direction]
        end

        anchor:chainEvent(function(_, anchor)
            self.tackle:deleteOffset()
            self.sourceEntity.entityspawner:spawn("rock", hitTarget, round(self.sourceEntity.stats:get(Tags.STAT_MAX_HEALTH) * ROCK_HEALTH_RATIO))
            Common.playSFX("ROCK_SHAKE")
            self:shakeScreen(anchor, 1.5)
            self.entity:delete()
        end):chainWaitGroupDone(done)
    end)
    return done
end

local SKILL_ACTION = class("actions.action")
SKILL.actionClass = SKILL_ACTION
function SKILL_ACTION:process(currentEvent)
    local throwAction = self.entity.actor:create(ACTIONS_FRAGMENT.THROW, self.direction)
    throwAction.sound = "WHOOSH_BIG"
    return throwAction:parallelChainEvent(currentEvent):chainEvent(function(_, anchor)
        self.entity.buffable:apply(BUFFS:get("STUN_HIDDEN"):new(1))
        local rock = self.entity.sprite:createCharacterCopy()
        rock.sprite.frameType = Tags.FRAME_TANK_DEPENDENT
        rock.sprite.shadowType = false
        rock.sprite:turnToDirection(RIGHT)
        rock.sprite.cell = Vector:new(2, 3)
        rock.sprite.layer = Tags.LAYER_FLYING
        local flyAction = rock.actor:create(ROCK_FLY, self.direction)
        flyAction.sourceEntity = self.entity
        flyAction.minDamage, flyAction.maxDamage = self.entity.stats:getEnemyAbility()
        flyAction:parallelChainEvent(anchor)
    end)
end

local function shouldCancel(entity, direction, playerPosition)
    return not entity.body:isPassable(entity.body:getPosition() + Vector[direction])
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.agent.avoidsReserved = false
    entity.sprite:setCell(7, 5)
    entity.stats:set(Tags.STAT_MOVEMENT_SLOW, 1)
    entity:callIfHasComponent("elite", "fixMovementSlow")
    entity:addComponent("melee")
    entity.melee.swingIcon = Vector:new(8, 15)
    entity.melee.attackClass = ATTACK
    entity:addComponent("caster", SKILL)
    entity.caster.alignDistance = THROW_RANGE
    entity.caster.alignBackOff = false
    entity.caster.shouldCancel = shouldCancel
    entity:addComponent("entityspawner")
end

