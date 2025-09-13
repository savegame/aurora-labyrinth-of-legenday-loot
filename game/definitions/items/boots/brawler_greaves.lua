local Vector = require("utils.classes.vector")
local Common = require("common")
local COLORS = require("draw.colors")
local PLAYER_COMMON = require("actions.player_common")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Brawler Greaves")
local ABILITY = require("structures.ability_def"):new("Toss")
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(16, 14)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 40, [Tags.STAT_ABILITY_POWER] = 1.88, [Tags.STAT_ABILITY_DAMAGE_BASE] = 13.5, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.9) })
ITEM:setGrowthMultiplier({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 1.5 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Throw an adjacent enemy behind you. It takes %s damage and skips its turn."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(4, 9)
ABILITY.iconColor = COLORS.STANDARD_EARTH
ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local source = entity.body:getPosition()
    local entityAt = entity.body:getEntityAt(source + Vector[direction])
    if entityAt and entityAt:hasComponent("agent") then
        if not entity.body:isPassable(source - Vector[direction]) then
            return "The space behind you is blocked"
        else
            return false
        end

    else
        return TERMS.INVALID_DIRECTION_NO_ENEMY
    end

end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local target = entity.body:getPosition() + Vector[direction]
    if ABILITY.getInvalidReason(entity, direction, abilityStats) then
        castingGuide:indicateWeak(target)
    else
        castingGuide:indicate(target)
    end

end
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local FORWARD_DISTANCE = 0.5
local FORWARD_DURATION = 0.12
local PLAYER_JUMP_HEIGHT = 0.3
local TARGET_JUMP_HEIGHT = 1.2
local THROW_DURATION = 0.5
local GRAB_HOLD_DURATION = 0.18
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("tackle")
    self.tackle.forwardDistance = FORWARD_DISTANCE
    self:addComponent("jump")
    self.jump.height = PLAYER_JUMP_HEIGHT
    self:addComponent("move")
    self.move.interimSkipTriggers = true
    self.move.interimSkipProjectiles = true
    self.move.distance = 2
    self.move:setEasingToLinear()
    self:addComponentAs("jump", "targetjump")
    self.targetjump.height = TARGET_JUMP_HEIGHT
end

function ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    local moveFrom = self.entity.body:getPosition() + Vector[self.direction]
    local targetEntity = self.entity.body:getEntityAt(moveFrom)
    self.targetjump.entity = targetEntity
    targetEntity.sprite.layer = Tags.LAYER_FLYING
    self.move.entity = targetEntity
    self.move.direction = reverseDirection(self.direction)
    self.move:prepare(currentEvent)
    self.tackle:createOffset()
    self.tackle.offset.disableModY = true
    currentEvent = self.tackle:chainForwardEvent(currentEvent, FORWARD_DURATION):chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit()
        hit.forceFlash = true
        hit.turnSkip = true
        hit:applyToEntity(anchor, targetEntity)
    end)
    currentEvent = currentEvent:chainProgress(GRAB_HOLD_DURATION):chainEvent(function()
        Common.playSFX("WHOOSH", 0.75)
    end)
    self.targetjump:chainFullEvent(currentEvent, THROW_DURATION)
    self.tackle:chainBackEvent(currentEvent, THROW_DURATION)
    currentEvent:chainProgress(THROW_DURATION / 2):chainEvent(function()
        self.entity.sprite:turnToDirection(reverseDirection(self.direction))
    end)
    currentEvent = self.move:chainMoveEvent(currentEvent, THROW_DURATION):chainEvent(function(_, anchor)
        Common.playSFX("ROCK_SHAKE", 1.2)
        local hit = self.entity.hitter:createHit()
        hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        hit:applyToEntity(anchor, targetEntity)
        targetEntity.sprite:resetLayer()
    end)
    self:shakeScreen(currentEvent, 2)
    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Goliath Greaves")
LEGENDARY.statLine = "{C:KEYWORD}Chance on {C:KEYWORD}Attack to reset this " .. "ability's cooldown."
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 13.5 * 0.17, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.9) })
local LEGENDARY_TRIGGER = class(TRIGGERS.ON_ATTACK)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function LEGENDARY_TRIGGER:process(currentEvent)
    local equipment = self.entity.equipment
    equipment:resetCooldown(self.abilityStats:get(Tags.STAT_SLOT))
    return currentEvent
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MAX, Tags.STAT_UPGRADED)
end
return ITEM

