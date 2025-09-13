local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local ActionUtils = require("actions.utils")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Volt Gloves")
local ABILITY = require("structures.ability_def"):new("Lightning Bolt")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ABILITY:addTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(4, 12)
ITEM:setToStatsBase({ [Tags.STAT_MAX_MANA] = 40, [Tags.STAT_ABILITY_POWER] = 2.65, [Tags.STAT_ABILITY_DAMAGE_BASE] = 24.5, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.99), [Tags.STAT_ABILITY_RANGE] = 3, [Tags.STAT_ABILITY_RANGE_MIN] = 1, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:setGrowthMultiplier({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 1.5 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
local FORMAT = "{C:KEYWORD}Range %s - Deal %s damage to an " .. "enemy and {C:KEYWORD}Stun it for %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_DEBUFF_DURATION)
end
ABILITY.icon = Vector:new(10, 6)
ABILITY.iconColor = COLORS.STANDARD_LIGHTNING
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonEnemy
ABILITY.indicate = ActionUtils.indicateEnemyWithinRange
local ACTION = class(ACTIONS_FRAGMENT.CAST)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("lightningspawner")
    self.color = ABILITY.iconColor
end

function ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    currentEvent = ACTION:super(self, "process", currentEvent):chainEvent(function()
        Common.playSFX("LIGHTNING")
    end)
    local targetEntity = ActionUtils.getEnemyWithinRange(self.entity, self.direction, self.abilityStats)
    local stunDuration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
    currentEvent = self.lightningspawner:spawn(currentEvent, targetEntity.body:getPosition()):chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit()
        hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        hit:addBuff(BUFFS:get("STUN"):new(stunDuration))
        hit:applyToEntity(anchor, targetEntity)
    end)
    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("The Conduit")
local LEGENDARY_EXTRA_LINE = "Whenever a {C:KEYWORD}Stun you applied to an enemy expires, deal " .. "%s damage to that enemy."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 9, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(1) })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
local AFTERSHOCK = BUFFS:define("AFTERSHOCK", "STUN")
function AFTERSHOCK:initialize(duration, sourceEntity, abilityStats)
    AFTERSHOCK:super(self, "initialize", duration)
    self.sourceEntity = sourceEntity
    self.abilityStats = abilityStats
end

function AFTERSHOCK:getDataArgs()
    return self.duration, self.sourceEntity, self.abilityStats
end

function AFTERSHOCK:onExpire(anchor, entity)
    AFTERSHOCK:super(self, "onExpire", anchor, entity)
    local hit = self.sourceEntity.hitter:createHit()
    hit:setDamageFromModifierStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
    hit:applyToEntity(anchor, entity, entity.body:getPosition())
end

LEGENDARY.decorateOutgoingHit = function(entity, hit, abilityStats)
    hit.buffs:mapSelf(function(buff)
        if BUFFS:get("STUN"):isInstance(buff) then
            return AFTERSHOCK:new(buff.duration, entity, abilityStats)
        else
            return buff
        end

    end)
end
return ITEM

