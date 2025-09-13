local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Common = require("common")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local EASING = require("draw.easing")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Earth Treads")
local ABILITY = require("structures.ability_def"):new("Rocky Escape")
ABILITY:addTag(Tags.ABILITY_TAG_DISENGAGE_MELEE)
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(22, 14)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 20, [Tags.STAT_MAX_MANA] = 20, [Tags.STAT_ABILITY_POWER] = 1.75, [Tags.STAT_ABILITY_RANGE] = 1, [Tags.STAT_ABILITY_AREA_OTHER] = 3, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 5, [Tags.STAT_SECONDARY_DAMAGE_BASE] = 15, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = 0 })
ITEM:setGrowthMultiplier({ [Tags.STAT_SECONDARY_DAMAGE_BASE] = 2.65 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
local FORMAT = "Move %s, then create a wall of obstacles %s spaces wide "
local FORMAT_LEGENDARY = "{B:STAT_LINE}and %s thick {B:NORMAL}"
local FORMAT_END = "behind you. Lasts for %s and has %s health each."
ABILITY.getDescription = function(item)
    local description = textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE, Tags.STAT_ABILITY_AREA_OTHER)
    return description .. textStatFormat(FORMAT_END, item, Tags.STAT_ABILITY_DEBUFF_DURATION, Tags.STAT_SECONDARY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(10, 10)
ABILITY.iconColor = COLORS.STANDARD_EARTH
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonFrontIsNotPassable
local function getFromStarting(entity, starting, direction, abilityStats)
    local result = Array:new()
    local area = (abilityStats:get(Tags.STAT_ABILITY_AREA_OTHER) - 1) / 2
    result:push(starting)
    local sideDirections = Array:new(cwDirection(direction), ccwDirection(direction))
    for sideDirection in sideDirections() do
        for i = 1, area do
            local target = starting + Vector[sideDirection] * i
            if entity.body:isPassable(target) then
                result:push(target)
            end

        end

    end

    return result
end

local function getWallArea(entity, direction, abilityStats)
    local starting = entity.body:getPosition()
    local result = getFromStarting(entity, starting, direction, abilityStats)
    if abilityStats:get(Tags.STAT_ABILITY_RANGE, 1) > 1 then
        if entity.body:isPassable(starting + Vector[direction] * 2) then
            result:concat(getFromStarting(entity, starting + Vector[direction], direction, abilityStats))
        end

    end

    return result
end

ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local wallArea = getWallArea(entity, direction, abilityStats)
    if ABILITY.getInvalidReason(entity, direction, abilityStats) then
        for target in wallArea() do
            castingGuide:indicateWeak(target)
        end

    else
        local moveTo = ActionUtils.getDashMoveTo(entity, direction, abilityStats)
        castingGuide:indicateMoveTo(moveTo)
        for target in wallArea() do
            castingGuide:indicate(target)
        end

    end

end
local STEP_DURATION = ACTION_CONSTANTS.WALK_DURATION
local ACTION = class(ACTIONS_FRAGMENT.TRAIL_MOVE)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.stepDuration = STEP_DURATION
    self.wallArea = false
    self.source = false
end

local ROCK_HEIGHT = 1.4
local FALL_DURATION = 0.2
function ACTION:parallelResolve(currentEvent)
    self.source = self.entity.body:getPosition()
    self.wallArea = getWallArea(self.entity, self.direction, self.abilityStats)
    self.entity.sprite:turnToDirection(self.direction)
    local moveTo = ActionUtils.getDashMoveTo(self.entity, self.direction, self.abilityStats)
    self.distance = self.entity.body:getPosition():distanceManhattan(moveTo)
    return ACTION:super(self, "parallelResolve", currentEvent)
end

function ACTION:chainRockFall(anchor, positions)
    local rocks = Array:new()
    for target in positions() do
        local rock = self.entity.entityspawner:spawn("rock", target, self.abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MIN), true)
        rock.charactereffects:flash(ACTION_CONSTANTS.NEGATIVE_FADE_DURATION, ABILITY.iconColor)
        rock.sprite.layer = Tags.LAYER_FLYING
        rock.perishable.duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
        local offset = rock.offset:createProfile()
        offset.jump = ROCK_HEIGHT
        rocks:push(rock)
    end

    anchor:chainProgress(FALL_DURATION, function(progress)
        for rock in rocks() do
            rock.offset:getLastProfile().jump = ROCK_HEIGHT * (1 - progress)
        end

    end, EASING.QUAD):chainEvent(function(_, anchor)
        for rock in rocks() do
            rock.offset:deleteLastProfile()
            rock.sprite:resetLayer()
        end

        if not rocks:isEmpty() then
            Common.playSFX("ROCK_SHAKE")
            self:shakeScreen(anchor, 1.0)
        end

    end)
end

function ACTION:process(currentEvent)
    local function isAtFirstStep(position)
        if self.direction == LEFT or self.direction == RIGHT then
            return self.source.x == position.x
        else
            return self.source.y == position.y
        end

    end

    local initialWall = self.wallArea:accept(isAtFirstStep)
    local endWall = self.wallArea:reject(isAtFirstStep)
    currentEvent:chainProgress(STEP_DURATION / 2):chainEvent(function(_, anchor)
        self:chainRockFall(anchor, initialWall)
    end)
    if endWall then
        currentEvent:chainProgress(STEP_DURATION * 1.0):chainEvent(function(_, anchor)
            self:chainRockFall(anchor, endWall)
        end)
    end

    return ACTION:super(self, "process", currentEvent)
end

local LEGENDARY = ITEM:createLegendary("Dwarven Stompers")
local LEGENDARY_STAT_LINE = "Deal %s bonus damage to objects. Whenever you destroy an object, deal %s damage to all spaces around it (except yours)."
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_SECONDARY_DAMAGE_MIN, Tags.STAT_ABILITY_DAMAGE_MIN)
end
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 12.6, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.34), [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_3X3 })
local function isObject(entity)
    return entity and entity:hasComponent("tank") and (not entity:hasComponent("agent")) and (not entity:hasComponent("player"))
end

LEGENDARY.decorateOutgoingHit = function(entity, hit, abilityStats)
    local targetEntity = hit.targetEntity
    if isObject(targetEntity) and hit:isDamagePositiveDirect() then
        hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MIN)
        hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MAX)
        hit:increaseBonusState()
    end

end
local EXPLOSION = class("actions.action")
local EXPLOSION_DURATION = 0.5
local EXPLOSION_SHAKE_INTENSITY = 1.0
function EXPLOSION:initialize(entity, direction, abilityStats)
    EXPLOSION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.explosion.excludeSelf = false
    self.explosion.shakeIntensity = EXPLOSION_SHAKE_INTENSITY
    self.explosion:setHueToEarth()
    self.position = false
end

function EXPLOSION:process(currentEvent)
    self.explosion:setArea(self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND))
    self.explosion.source = self.position
    currentEvent:chainEvent(function()
        Common.playSFX("ROCK_SHAKE")
    end)
    return self.explosion:chainFullEvent(currentEvent, EXPLOSION_DURATION, function(anchor, position)
        if position ~= self.entity.body:getPosition() then
            local hit = self.entity.hitter:createHit(self.explosion.source)
            local damageType = Tags.DAMAGE_TYPE_SPELL
            hit:setDamageFromAbilityStats(damageType, self.abilityStats)
            hit:applyToPosition(anchor, position)
        end

    end)
end

local LEGENDARY_TRIGGER = class(TRIGGERS.ON_KILL)
function LEGENDARY_TRIGGER:process(currentEvent)
    local action = self.entity.actor:create(EXPLOSION, self.direction, self.abilityStats)
    action.position = self.position
    return action:parallelChainEvent(currentEvent)
end

function LEGENDARY_TRIGGER:isEnabled()
    return isObject(self.killed)
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

