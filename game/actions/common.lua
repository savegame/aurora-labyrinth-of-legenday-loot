local ACTIONS = {  }
local Vector = require("utils.classes.vector")
local ActionUtils = require("actions.utils")
local ACTION_CONSTANTS = require("actions.constants")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTIONS_BASIC = require("actions.basic")
local CONSTANTS = require("logic.constants")
local CLAW_FORWARD_DURATION = 0.14
local CLAW_FORWARD_DISTANCE = 0.25
local CLAW_START = 0.05
local CLAW_WAIT = 0.15
local Common = require("common")
ACTIONS.AREA_CLAW = class("actions.action")
function ACTIONS.AREA_CLAW:initialize(entity, direction, abilityStats)
    ACTIONS.AREA_CLAW:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("cleaveorder")
    self:addComponent("tackle")
    self.tackle.forwardDistance = CLAW_FORWARD_DISTANCE
    self:addComponent("claw")
    self.claw:setTrailToLingering()
    self.duration = false
    self.area = false
end

function ACTIONS.AREA_CLAW:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    self.tackle:createOffset()
    self.tackle:chainForwardEvent(currentEvent, CLAW_FORWARD_DURATION)
    self.cleaveorder.area = self.area
    self.claw:setAngles(self.cleaveorder:getAngles())
    self.claw:createImage()
    self.claw.image.flipRight = true
    currentEvent = currentEvent:chainProgress(CLAW_START):chainEvent(function()
        Common.playSFX("WHOOSH", 0.8 * sqrt(3) / sqrt(self.area))
    end)
    self.cleaveorder:chainHitEvent(currentEvent, self.duration, function(anchor, position)
        local hit = self.entity.hitter:createHit()
        hit:setDamage(Tags.DAMAGE_TYPE_SPELL, self.entity.stats:getEnemyAbility())
        hit:increaseBonusState()
        hit:applyToPosition(anchor, position)
    end)
    currentEvent = self.claw:chainSlashEvent(currentEvent, self.duration):chainProgress(CLAW_WAIT):chainEvent(function()
        self.claw:deleteImage()
    end)
    return self.tackle:chainBackEvent(currentEvent, CLAW_FORWARD_DURATION):chainEvent(function()
        self.tackle:deleteOffset()
    end)
end

ACTIONS.RANGED_ATTACK_HIT = class("actions.hit")
function ACTIONS.RANGED_ATTACK_HIT:parallelResolve(anchor)
    ACTIONS.RANGED_ATTACK_HIT:super(self, "parallelResolve", anchor)
    self.hit:setDamage(Tags.DAMAGE_TYPE_RANGED, self.entity.stats:getAttack())
end

ACTIONS.ARROW_SHOOT = class("actions.action")
function ACTIONS.ARROW_SHOOT:checkParallel()
    if self.entity.sprite:isVisible() then
        return false
    end

    local source = self.entity.body:getPosition()
    for i = 1, CONSTANTS.ENEMY_PROJECTILE_SPEED do
        if self.entity.sprite:isPositionVisible(source + Vector[self.direction] * i) then
            return false
        end

    end

    return true
end

function ACTIONS.ARROW_SHOOT:parallelResolve(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    if self.isParallel then
        self.entity.projectilespawner:spawn(false, self.direction)
    end

end

function ACTIONS.ARROW_SHOOT:process(currentEvent)
    if not self.isParallel then
        Common.playSFX("BOW_SHOOT")
        currentEvent = self.entity.projectilespawner:spawn(currentEvent, self.direction)
        return currentEvent
    end

    return currentEvent
end

ACTIONS.CASTER_SHOOT = class(ACTIONS_FRAGMENT.CAST)
ACTIONS.CASTER_SHOOT.checkParallel = ACTIONS.ARROW_SHOOT.checkParallel
ACTIONS.CASTER_SHOOT.parallelResolve = ACTIONS.ARROW_SHOOT.parallelResolve
function ACTIONS.CASTER_SHOOT:process(currentEvent)
    if self.isParallel then
        return currentEvent
    else
        if self.entity.sprite:isVisible() then
            currentEvent = ACTIONS.CASTER_SHOOT:super(self, "process", currentEvent)
        end

        currentEvent = self.entity.projectilespawner:spawn(currentEvent, self.direction)
        return currentEvent
    end

end

ACTIONS.TRIANGLE_BREATH = class("actions.action")
local BREATH_TRAVEL_DURATION = 0.15
function ACTIONS.TRIANGLE_BREATH:initialize(entity, direction, abilityStats)
    ACTIONS.TRIANGLE_BREATH:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("image")
    self:addComponent("acidspit")
    self:addComponent("outline")
    self.color = false
end

function ACTIONS.TRIANGLE_BREATH:affectPosition(anchor, target)
end

function ACTIONS.TRIANGLE_BREATH:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    self.outline.color = self.color
    Common.playSFX("VENOM_SPIT", 0.5)
    currentEvent = self.outline:chainFullEvent(currentEvent, ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION)
    local lastEvent
    local source = self.entity.body:getPosition()
    for target in (ActionUtils.getTriangleBreathPositions(source, self.direction))() do
        local distance = source:distanceEuclidean(target)
        lastEvent = self.acidspit:chainSpitEvent(currentEvent, distance * BREATH_TRAVEL_DURATION, target)
        lastEvent = lastEvent:chainEvent(function(_, anchor)
            return self:affectPosition(anchor, target)
        end)
    end

    return lastEvent
end

ACTIONS.CAULDRON_DEATH = class(ACTIONS_BASIC.DIE)
local CAULDRON_TRAVEL_INITIAL = 0.1
local CAULDRON_TRAVEL_PER_DISTANCE = 0.16
local CAULDRON_DISTANCE = 4
local CAULDRON_DISTANCE_DIAGONAL = 3
local Common = require("common")
function ACTIONS.CAULDRON_DEATH:initialize(entity, direction, abilityStats)
    ACTIONS.CAULDRON_DEATH:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("acidspit")
end

function ACTIONS.CAULDRON_DEATH:parallelResolve(currentEvent)
    ACTIONS.CAULDRON_DEATH:super(self, "parallelResolve", currentEvent)
    if (not self.killingHit) or (self.killingHit.sourcePosition == self.position) then
        if self.killer then
            self.direction = self.killer.sprite.direction
        else
            self.direction = DIRECTIONS_AA:randomValue(self:getLogicRNG())
        end

    else
        self.direction = Common.getDirectionTowards(self.killingHit.sourcePosition, self.position, self:getLogicRNG(), true)
    end

end

function ACTIONS.CAULDRON_DEATH:affectPosition(anchor, target)
end

function ACTIONS.CAULDRON_DEATH:process(currentEvent)
    ACTIONS.CAULDRON_DEATH:super(self, "process", currentEvent)
    local distance = CAULDRON_DISTANCE
    if isDiagonal(self.direction) then
        distance = CAULDRON_DISTANCE_DIAGONAL
    end

    local lastEvent = currentEvent
    for i = 1, distance do
        local duration = CAULDRON_TRAVEL_INITIAL + i * CAULDRON_TRAVEL_PER_DISTANCE
        if isDiagonal(self.direction) then
            duration = duration * math.sqrtOf2
        end

        local target = self.position + Vector[self.direction] * i
        lastEvent = self.acidspit:chainSpitEvent(currentEvent, duration, target)
        lastEvent = lastEvent:chainEvent(function(_, anchor)
            self:affectPosition(anchor, target)
        end)
        if not self.entity.body:canBePassable(target) then
            break
        end

    end

    return lastEvent
end

local BARREL_EXPLOSION_AREA = Tags.ABILITY_AREA_3X3
local BARREL_EXPLOSION_DURATION = 0.6
local BARREL_EXPLOSION_SHAKE_INTENSITY = 3
ACTIONS.BARREL_DEATH = class(ACTIONS_BASIC.DIE)
function ACTIONS.BARREL_DEATH:initialize(entity, direction, abilityStats)
    ACTIONS.BARREL_DEATH:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.explosion:setArea(BARREL_EXPLOSION_AREA)
    self.explosion.excludeSelf = true
    self.explosion.shakeIntensity = BARREL_EXPLOSION_SHAKE_INTENSITY
    self.sound = "EXPLOSION_MEDIUM"
end

function ACTIONS.BARREL_DEATH:createHit()
    local hit = self.entity.hitter:createHit(self.explosion.source)
    hit:setDamage(Tags.DAMAGE_TYPE_SPELL, self.entity.stats:getEnemyAbility())
    return hit
end

function ACTIONS.BARREL_DEATH:process(currentEvent)
    ACTIONS.BARREL_DEATH:super(self, "process", currentEvent)
    self.explosion.source = self.position
    Common.playSFX(self.sound)
    return self.explosion:chainFullEvent(currentEvent, BARREL_EXPLOSION_DURATION, function(anchor, position)
        local hit = self:createHit()
        if hit then
            hit:applyToPosition(anchor, position)
        end

    end)
end

return ACTIONS

