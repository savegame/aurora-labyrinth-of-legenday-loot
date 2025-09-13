local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local BUFFS = require("definitions.buffs")
local CONSTANTS = require("logic.constants")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ACTION_CONSTANTS = require("actions.constants")
local ACTIONS_FRAGMENT = require("actions.fragment")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Vermilion Helm")
local ABILITY = require("structures.ability_def"):new("Mass Drain")
ABILITY:addTag(Tags.ABILITY_TAG_RESTORES_HEALTH)
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(6, 13)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 28, [Tags.STAT_MAX_MANA] = 12, [Tags.STAT_ABILITY_POWER] = 6.2, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_ROUND_5X5, [Tags.STAT_ABILITY_DAMAGE_BASE] = 22.3, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.5), [Tags.STAT_SECONDARY_DAMAGE_BASE] = 8.2, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.5) })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_AREA_ROUND] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Deal %s damage to all enemies in a %s around you. " .. "Restore %s health for every enemy damaged."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_AREA_ROUND, Tags.STAT_SECONDARY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(11, 6)
ABILITY.iconColor = COLORS.STANDARD_RAGE
ABILITY.directions = false
local function isCastingEntity(entity)
    return entity and entity:hasComponent("caster") and entity.caster.preparedAction
end

ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local origin = entity.body:getPosition()
    local area = abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    for position in (ActionUtils.getAreaPositions(entity, origin, area, true))() do
        local entityAt = entity.body:getEntityAt(position)
                if ActionUtils.isAliveAgent(entityAt) then
            return false
        elseif abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 and isCastingEntity(entityAt) then
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
        elseif abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 and isCastingEntity(entityAt) then
            castingGuide:indicate(position)
        else
            castingGuide:indicateWeak(position)
        end

    end

end
local ACTION = class(ACTIONS_FRAGMENT.ENCHANT)
ABILITY.actionClass = ACTION
local WAIT_BEFORE_STOP = 0.6
local WAIT_BEFORE_HEAL = 0.35
local WAIT_BEFORE_MANA_HEAL = 0.23
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("drain")
    self.drain.speedMin = 3
    self.drain.speedMax = 3
    self.color = ABILITY.iconColor
    self.manualFadeOut = true
    self:speedMultiply(ACTION_CONSTANTS.SLOW_CAST_MULTIPLIER)
    self.sound = "WEAPON_CHARGE"
end

function ACTION:process(currentEvent)
    local drainSound = false
    currentEvent = ACTION:super(self, "process", currentEvent):chainEvent(function()
        drainSound = Common.playSFX("DRAIN")
    end)
    local source = self.entity.body:getPosition()
    local area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    local isLegendary = self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0
    local countDrained = 0
    local countManaDrained = 0
    currentEvent = currentEvent:chainEvent(function(_, anchor)
        for position in (ActionUtils.getAreaPositions(self.entity, source, area, true))() do
            local entityAt = self.entity.body:getEntityAt(position)
            if isLegendary and isCastingEntity(entityAt) then
                if entityAt.tank.hasDiedOnce then
                    entityAt.tank:kill(anchor)
                end

                countManaDrained = countManaDrained + 1
            end

            if entityAt and ((isLegendary and entityAt:hasComponent("agent")) or ActionUtils.isAliveAgent(entityAt)) then
                local hit = self.entity.hitter:createHit()
                self.drain:start(self.entity, entityAt)
                if ActionUtils.isAliveAgent(entityAt) then
                    hit:setDamageFromAbilityStats(Tags.STAT_ABILITY_DAMAGE_MIN, self.abilityStats)
                    countDrained = countDrained + 1
                end

                if isLegendary then
                    hit.buffs:push(BUFFS:get("CAST_CANCEL"):new())
                end

                hit:applyToEntity(anchor, entityAt)
            end

        end

    end):chainProgress(WAIT_BEFORE_STOP):chainEvent(function()
        self.drain:stop()
    end):chainProgress(WAIT_BEFORE_HEAL):chainEvent(function(_, anchor)
        drainSound:stop()
        local hit = self.entity.hitter:createHit()
        local minDamage = countDrained * self.abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MIN)
        local maxDamage = countDrained * self.abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MAX)
        hit:setHealing(minDamage, maxDamage, self.abilityStats)
        hit:applyToEntity(anchor, self.entity)
        if countManaDrained > 0 then
            if countDrained > 0 then
                anchor = anchor:chainProgress(WAIT_BEFORE_MANA_HEAL)
            end

            anchor = anchor:chainEvent(function()
                local hit = self.entity.hitter:createHit()
                local minDamage = countManaDrained * self.abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MIN)
                local maxDamage = countManaDrained * self.abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MAX)
                hit:setHealing(minDamage, maxDamage, self.abilityStats)
                hit.affectsMana = true
                hit:applyToEntity(anchor, self.entity)
            end)
        end

    end)
    self:fadeOut(currentEvent)
    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Helm of the God Eater")
local LEGENDARY_EXTRA_LINE = "{C:KEYWORD}Focusing enemies in the area cancel their {C:KEYWORD}Focus. Restore %s mana for every canceled {C:KEYWORD}Focus."
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_SECONDARY_DAMAGE_MIN)
end
return ITEM

