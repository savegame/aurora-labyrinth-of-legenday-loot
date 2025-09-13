local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local BUFFS = require("definitions.buffs")
local CONSTANTS = require("logic.constants")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ACTION_CONSTANTS = require("actions.constants")
local ACTIONS_FRAGMENT = require("actions.fragment")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Dream Cloak")
local ABILITY = require("structures.ability_def"):new("Sleep")
ABILITY:addTag(Tags.ABILITY_TAG_DEBUFF_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_SURROUNDING_DISABLE)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(9, 12)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 4, [Tags.STAT_MAX_MANA] = 56, [Tags.STAT_ABILITY_POWER] = 3.15, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_ROUND_5X5, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 5 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_AREA_ROUND] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
local FORMAT = "Put all enemies in %s around you to sleep, disabling action. " .. "They wake up when they lose health. Lasts %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_AREA_ROUND, Tags.STAT_ABILITY_DEBUFF_DURATION)
end
ABILITY.icon = Vector:new(12, 7)
ABILITY.iconColor = COLORS.STANDARD_PSYCHIC
ABILITY.directions = false
ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local origin = entity.body:getPosition()
    local area = abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    for position in (ActionUtils.getAreaPositions(entity, origin, area, true))() do
        local entityAt = entity.body:getEntityAt(position)
        if ActionUtils.isAliveAgent(entityAt) then
            return false
        end

    end

    return TERMS.INVALID_DIRECTION_NO_ENEMY
end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local source = entity.body:getPosition()
    local area = abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    for position in (ActionUtils.getAreaPositions(entity, source, area, true))() do
        local entityAt = entity.body:getEntityAt(position)
        if ActionUtils.isAliveAgent(entityAt) then
            castingGuide:indicate(position)
        else
            castingGuide:indicateWeak(position)
        end

    end

end
local DEBUFF = BUFFS:define("SLEEP")
function DEBUFF:initialize(duration, sourceEntity, minDamage, maxDamage)
    DEBUFF:super(self, "initialize", duration)
    self.disablesAction = true
    self.colorTint = ABILITY.iconColor
    self.sourceEntity = sourceEntity or false
    self.minDamage = minDamage or false
    self.maxDamage = maxDamage or false
end

function DEBUFF:getDataArgs()
    if self.minDamage then
        return self.duration, self.sourceEntity, self.minDamage, self.maxDamage
    else
        return self.duration
    end

end

function DEBUFF:decorateIncomingHit(hit)
    if hit:isDamagePositive() and hit.damageType ~= Tags.DAMAGE_TYPE_NIGHTMARE then
        self.duration = 0
        hit.targetEntity.buffable:delete(false, DEBUFF)
    end

end

function DEBUFF:onTurnEnd(anchor, entity)
    if self.minDamage then
        local hit = self.sourceEntity.hitter:createHit(entity.body:getPosition())
        hit:setDamage(Tags.DAMAGE_TYPE_NIGHTMARE, self.minDamage, self.maxDamage)
        hit:applyToEntity(anchor, entity, entity.body:getPosition())
    end

end

function DEBUFF:getColorTint(timePassed)
    return self.colorTint:withAlpha(Common.getPulseOpacity(timePassed, 0.325, 0.725))
end

local ACTION = class(ACTIONS_FRAGMENT.CAST)
ABILITY.actionClass = ACTION
local FLASH_OPACITY = 1
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self:speedMultiply(ACTION_CONSTANTS.SLOW_CAST_MULTIPLIER)
end

function ACTION:process(currentEvent)
    currentEvent = ACTION:super(self, "process", currentEvent)
    local source = self.entity.body:getPosition()
    local area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    currentEvent = currentEvent:chainEvent(function(_, anchor)
        Common.playSFX("AFFLICT")
        local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
        for position in (ActionUtils.getAreaPositions(self.entity, source, area, true))() do
            local entityAt = self.entity.body:getEntityAt(position)
            if ActionUtils.isAliveAgent(entityAt) then
                entityAt.charactereffects:flash(ACTION_CONSTANTS.STANDARD_FLASH_DURATION, ABILITY.iconColor:withAlpha(FLASH_OPACITY))
                local hit = self.entity.hitter:createHit()
                hit.sound = false
                local buff
                if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
                    buff = DEBUFF:new(duration, self.entity, self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN), self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX))
                else
                    buff = DEBUFF:new(duration)
                end

                hit:addBuff(buff)
                hit:applyToEntity(anchor, entityAt)
            end

        end

    end)
    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Shroud of Nightmares")
local LEGENDARY_ABILITY_LINE = "Sleeping enemies lose %s health every turn. This does " .. "not wake them up."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 4.8, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.2) })
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_ABILITY_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
return ITEM

