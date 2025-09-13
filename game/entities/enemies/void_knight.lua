local Vector = require("utils.classes.vector")
local Common = require("common")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTION_CONSTANTS = require("actions.constants")
local SKILL = require("structures.skill_def"):new()
local MEASURES = require("draw.measures")
local TELEPORT_DISTANCE = 3
SKILL:setCooldownToNormal()
SKILL.getCastDirection = function(entity, player)
    local entityPos = entity.body:getPosition()
    local playerPos = player.body:getPosition()
    if playerPos.x == entityPos.x or playerPos.y == entityPos.y then
        local distance = entityPos:distanceManhattan(playerPos)
        if distance <= TELEPORT_DISTANCE + 1 and distance > 1 then
            local direction = Common.getDirectionTowards(entityPos, playerPos)
            if entity.body:isPassable(playerPos - Vector[direction]) then
                return direction
            end

        end

    end

    return false
end
local function getMoveTo(entity, direction, playerPosition)
    local moveFrom = entity.body:getPosition()
    local maxDistance = 0
    local body = entity.body
    for i = 1, TELEPORT_DISTANCE do
        if not body:canBePassable(moveFrom + Vector[direction] * i) then
            break
        end

        maxDistance = i
    end

    for i = 1, maxDistance + 1 do
        if moveFrom + Vector[direction] * i == playerPosition then
            local target = playerPosition - Vector[direction]
            if body:isPassable(target) then
                return target
            end

        end

    end

    for i = maxDistance, 1, -1 do
        local target = moveFrom + Vector[direction] * i
        if body:isPassable(target) then
            return target
        end

    end

    return false
end

SKILL.indicateArea = function(entity, direction, indicateGrid)
    local position = entity.body:getPosition()
    for i = 1, TELEPORT_DISTANCE + 1 do
        local target = position + Vector[direction] * i
        indicateGrid:set(target, true)
        if not entity.body:canBePassable(target) then
            return 
        end

    end

end
local SKILL_ACTION = class("actions.action")
SKILL.actionClass = SKILL_ACTION
local FADE_HALF_TIME = 0.15
local SWING_MOVE_DISTANCE = 0.35
local SWING_DURATION = 0.14
local SWING_HOLD_DURATION = 0.24
local SWING_BACK_DURATION = 0.12
function SKILL_ACTION:initialize(entity, direction, abilityStats)
    SKILL_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("tackle")
    self.tackle.braceDistance = ACTION_CONSTANTS.DEFAULT_BRACE_DISTANCE
    self.tackle.forwardDistance = SWING_MOVE_DISTANCE
    self:addComponent("charactereffects")
    self:addComponent("weaponswing")
    self.weaponswing:setSilhouetteColor(BLACK)
    self.charactereffects.fillColor = BLACK
end

function SKILL_ACTION:process(currentEvent)
    local entity = self.entity
    Common.playSFX("DOOM")
    entity.sprite:turnToDirection(self.direction)
    if (self.direction == LEFT or self.direction == RIGHT) then
        entity.sprite.layer = Tags.LAYER_ABOVE_EFFECTS
    end

    local moveFrom = entity.body:getPosition()
    local moveTo = getMoveTo(entity, self.direction, entity.agent:getPlayer().body:getPosition())
    entity.triggers:parallelChainPreMove(currentEvent, moveFrom, moveTo)
    currentEvent = self.charactereffects:chainFillIn(currentEvent, FADE_HALF_TIME):chainEvent(function()
        entity.sprite.opacity = 0
    end)
    currentEvent = self.charactereffects:chainFillOut(currentEvent, FADE_HALF_TIME):chainEvent(function(_, anchor)
        entity.body:setPosition(moveTo)
        self.tackle:createOffset()
        self.weaponswing:createSwingItem()
        self.weaponswing.swingItem.opacity = 0
        self.weaponswing.swingItem.fillOpacity = 0
    end)
    currentEvent = self.tackle:chainBraceEvent(currentEvent, 0):chainEvent(function()
        Common.playSFX("WHOOSH")
    end)
    currentEvent:chainProgress(SWING_DURATION, function(progress)
        self.weaponswing.swingItem.fillOpacity = progress
    end)
    self.charactereffects:chainFillIn(currentEvent, SWING_DURATION):chainEvent(function()
        entity.sprite.opacity = 1
        self.weaponswing.swingItem.opacity = 1
    end)
    self.tackle:chainForwardEvent(currentEvent, SWING_DURATION)
    currentEvent = self.weaponswing:chainSwingEvent(currentEvent, SWING_DURATION):chainEvent(function(_, anchor)
        local hit = entity.hitter:createHit(moveTo)
        hit:setDamage(Tags.DAMAGE_TYPE_MELEE, self.entity.stats:getEnemyAbility())
        hit:increaseBonusState()
        hit:applyToPosition(anchor, moveTo + Vector[self.direction])
    end)
    self.charactereffects:chainFillOut(currentEvent, SWING_HOLD_DURATION + SWING_BACK_DURATION)
    currentEvent:chainProgress(SWING_HOLD_DURATION + SWING_BACK_DURATION, function(progress)
        self.weaponswing.swingItem.fillOpacity = 1 - progress
    end)
    local holdEvent = currentEvent:chainProgress(SWING_HOLD_DURATION):chainEvent(function()
        self.weaponswing:deleteSwingItem()
    end)
    self.tackle:chainBackEvent(holdEvent, SWING_BACK_DURATION):chainEvent(function(_, anchor)
        self.tackle:deleteOffset()
        entity.body:endOfMove(anchor, moveFrom, moveTo)
    end)
    return currentEvent
end

local function shouldCancel(entity, direction, playerPosition)
    if playerPosition:distanceManhattan(entity.body:getPosition()) <= 1 then
        if Common.getDirectionTowards(entity.body:getPosition(), playerPosition) == direction then
            return true
        end

    end

    return not getMoveTo(entity, direction, playerPosition)
end

return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity.sprite:setCell(7, 8)
    entity:addComponent("melee")
    entity.melee.swingIcon = Vector:new(11, 10)
    entity.melee.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
    entity:addComponent("caster", SKILL)
    entity.caster.alignDistance = TELEPORT_DISTANCE
    entity.caster.alignBackOff = false
    entity.caster.shouldCancel = shouldCancel
    entity.caster.disabledWithImmobilize = true
end

