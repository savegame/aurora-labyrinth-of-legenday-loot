local Vector = require("utils.classes.vector")
local Hash = require("utils.classes.hash")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ACTION_CONSTANTS = require("actions.constants")
local ACTIONS_FRAGMENT = require("actions.fragment")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local Common = require("common")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Scourge Hat")
local ABILITY = require("structures.ability_def"):new("Contagion")
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ABILITY:addTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(1, 13)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 12, [Tags.STAT_MAX_MANA] = 28, [Tags.STAT_ABILITY_POWER] = 5.6, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 9, [Tags.STAT_POISON_DAMAGE_BASE] = 4.68, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_3X3, [Tags.STAT_ABILITY_RANGE] = 3 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
local FORMAT = "{C:KEYWORD}Range %s - {C:KEYWORD}Poison target enemy, making it lose %s health " .. "over %s. Whenever the target loses health from {C:KEYWORD}Poison, this effect spreads to " .. "enemies around it."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_POISON_DAMAGE_TOTAL, Tags.STAT_ABILITY_DEBUFF_DURATION)
end
ABILITY.icon = Vector:new(11, 4)
ABILITY.iconColor = COLORS.STANDARD_POISON
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonEnemy
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local entityAt = ActionUtils.indicateEnemyWithinRange(entity, direction, abilityStats, castingGuide)
    if entityAt then
        local area = abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
        local target = entityAt.body:getPosition()
        for position in (ActionUtils.getAreaPositions(entity, target, area, true))() do
            castingGuide:indicateWeak(position)
        end

    end

end
local DEBUFF = BUFFS:define("CONTAGION_SPREAD")
local PLAGUE_EXPLOSION = class("actions.action")
function PLAGUE_EXPLOSION:initialize(entity, direction, abilityStats)
    PLAGUE_EXPLOSION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.explosion:setHueToPoison()
    self.explosion.excludeSelf = true
    self.sourceEntity = false
    self.damage = false
    self.duration = false
    self.area = false
end

local EXPLOSION_DURATION = 0.75
function PLAGUE_EXPLOSION:process(currentEvent)
    self.explosion.source = self.entity.body:getPosition()
    self.explosion:setArea(self.area)
    Common.playSFX("EXPLOSION_POISON", 2)
    return self.explosion:chainFullEvent(currentEvent, EXPLOSION_DURATION, function(anchor, target)
        local entityAt = self.entity.body:getEntityAt(target)
        if ActionUtils.isAliveAgent(entityAt) then
            if not entityAt.buffable:isAffectedBy(DEBUFF) then
                local hit = self.sourceEntity.hitter:createHit()
                hit.sound = false
                hit:addBuff(BUFFS:get("POISON"):new(self.duration, self.sourceEntity, self.damage))
                hit:addBuff(DEBUFF:new(self.duration, self.sourceEntity, self.damage, self.area))
                hit:applyToEntity(anchor, entityAt)
            end

        end

    end)
end

DEBUFF.toDamageTicks = BUFFS:get("POISON").toDamageTicks
function DEBUFF:initialize(duration, sourceEntity, damage, area)
    DEBUFF:super(self, "initialize", duration)
    self.sourceEntity = sourceEntity
    self.area = area
    if type(damage) == "number" then
        self.damageTicks = self:toDamageTicks(duration, damage)
    else
        self.damageTicks = damage
    end

end

function DEBUFF:getDataArgs()
    return self.duration, self.sourceEntity, self.damageTicks, self.area
end

function DEBUFF:onTurnEnd(anchor, entity)
    self.damageTicks:popFirst()
    if not self.damageTicks:isEmpty() then
        local damage = self.damageTicks:sum()
        local duration = self.damageTicks:size()
        local source = entity.body:getPosition()
        for position in (ActionUtils.getAreaPositions(entity, source, self.area, true))() do
            local entityAt = entity.body:getEntityAt(position)
            if ActionUtils.isAliveAgent(entityAt) then
                if not entityAt.buffable:isAffectedBy(DEBUFF) then
                    local explodeAction = entity.actor:create(PLAGUE_EXPLOSION)
                    explodeAction.sourceEntity = self.sourceEntity
                    explodeAction.damage = damage
                    explodeAction.duration = duration
                    explodeAction.area = self.area
                    explodeAction:parallelChainEvent(anchor)
                    return 
                end

            end

        end

    end

end

function DEBUFF:onCombine(oldBuff)
end

local ACTION = class(ACTIONS_FRAGMENT.CAST)
ABILITY.actionClass = ACTION
local TRAVEL_DURATION = 0.18
local TRAVEL_HEIGHT = 1
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self:speedMultiply(ACTION_CONSTANTS.SLOW_CAST_MULTIPLIER)
    self:addComponent("acidspit")
    self.acidspit.travelHeight = TRAVEL_HEIGHT
end

function ACTION:process(currentEvent)
    currentEvent = ACTION:super(self, "process", currentEvent)
    local targetEntity = ActionUtils.getEnemyWithinRange(self.entity, self.direction, self.abilityStats)
    local target = targetEntity.body:getPosition()
    local distance = self.entity.body:getPosition():distanceManhattan(target)
    if distance <= 1 then
        self.acidspit.travelHeight = self.acidspit.travelHeight / 2
    end

    return self.acidspit:chainSpitEvent(currentEvent, distance * TRAVEL_DURATION, target):chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit()
        local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
        local poisonDamage = self.abilityStats:get(Tags.STAT_POISON_DAMAGE_TOTAL)
        local area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
        hit.sound = "POISON_DAMAGE"
        hit:addBuff(BUFFS:get("POISON"):new(duration, self.entity, poisonDamage))
        hit:addBuff(DEBUFF:new(duration, self.entity, poisonDamage, area))
        hit:applyToEntity(anchor, targetEntity)
    end)
end

local LEGENDARY = ITEM:createLegendary("The Mask of the Green Death")
LEGENDARY.modifyItem = function(item)
    local bonusDuration = 18
    local bonusPerLevel = 0
    local currentDuration = item.stats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
    local currentValue = item.stats:get(Tags.STAT_POISON_DAMAGE_TOTAL)
    local targetValue = ceil(currentValue * (bonusDuration + currentDuration) / currentDuration)
    local previousBonus = targetValue - currentValue
    item.stats:add(Tags.STAT_POISON_DAMAGE_TOTAL, previousBonus, 0)
    item.stats:add(Tags.STAT_ABILITY_DEBUFF_DURATION, bonusDuration, 0)
    for i = 1, CONSTANTS.ITEM_UPGRADE_LEVELS do
        bonusDuration = bonusDuration + bonusPerLevel
        local growthForLevel = item:getGrowthForLevel(i)
        local growthDamage = growthForLevel:get(Tags.STAT_POISON_DAMAGE_TOTAL, 0)
        local previousValue = currentValue
        currentValue = currentValue + growthDamage
        currentDuration = currentDuration + growthForLevel:get(Tags.STAT_ABILITY_DEBUFF_DURATION, 0)
        targetValue = ceil(currentValue * (bonusDuration + currentDuration) / currentDuration)
        item.extraGrowth:set(i, Hash:new({ [Tags.STAT_POISON_DAMAGE_TOTAL] = targetValue - currentValue - previousBonus, [Tags.STAT_ABILITY_DEBUFF_DURATION] = bonusPerLevel }))
        previousBonus = targetValue - currentValue
    end

    item:markAltered(Tags.STAT_ABILITY_DEBUFF_DURATION, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_POISON_DAMAGE_TOTAL, Tags.STAT_UPGRADED)
end
return ITEM

