local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Common = require("common")
local ACTION_CONSTANTS = require("actions.constants")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ActionUtils = require("actions.utils")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Energized Hat")
local ABILITY = require("structures.ability_def"):new("Lightning Wave")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ABILITY:addTag(Tags.ABILITY_TAG_SURROUNDING_DISABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(11, 19)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 12, [Tags.STAT_MAX_MANA] = 28, [Tags.STAT_ABILITY_POWER] = 5.5, [Tags.STAT_ABILITY_AREA_CLEAVE] = 3, [Tags.STAT_ABILITY_COUNT] = 5, [Tags.STAT_ABILITY_DAMAGE_BASE] = 14.44, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.93), [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1, [Tags.STAT_ABILITY_AREA_OTHER] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Deal %s damage to an area {C:NUMBER}3 spaces wide and %s spaces long in front of you. {C:KEYWORD}Stun all targets for %s. Every turn for %s turns, " .. "repeat this effect one space forward."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_AREA_OTHER, Tags.STAT_ABILITY_DEBUFF_DURATION, Tags.STAT_ABILITY_COUNT)
end
ABILITY.icon = Vector:new(2, 11)
ABILITY.iconColor = COLORS.STANDARD_LIGHTNING
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonFrontCantBePassable
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local source = entity.body:getPosition()
    local area = abilityStats:get(Tags.STAT_ABILITY_AREA_CLEAVE)
    local positions = ActionUtils.getCleavePositions(source, area, direction)
    local distance = 0
    local vDirection = Vector[direction]
    local mainIndicateDistance = abilityStats:get(Tags.STAT_ABILITY_AREA_OTHER)
    local maxDistance = abilityStats:get(Tags.STAT_ABILITY_COUNT) + mainIndicateDistance
    for distance = 1, maxDistance do
        if positions:isEmpty() then
            break
        end

        for i = 1, positions:size() do
            if entity.body:canBePassable(positions[i]) and entity.vision:isVisible(positions[i]) then
                if distance <= mainIndicateDistance then
                    castingGuide:indicate(positions[i])
                else
                    castingGuide:indicateWeak(positions[i])
                end

                positions[i] = positions[i] + vDirection
            else
                positions[i] = false
            end

        end

        positions:acceptSelf(returnSelf)
    end

end
local STRIKE = class("actions.action")
function STRIKE:initialize(entity, direction, abilityStats)
    STRIKE:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("lightningspawner")
    self.positions = false
end

function STRIKE:process(currentEvent)
    local lastEvent = currentEvent
    Common.playSFX("LIGHTNING")
    for position in self.positions() do
        local thisPosition = position
        if self.entity == self.entity.body:getEntityAt(thisPosition) then
            lastEvent = currentEvent
        else
            lastEvent = self.lightningspawner:spawn(currentEvent, thisPosition):chainEvent(function(_, anchor)
                self.entity.entityspawner:spawn("temporary_vision", thisPosition)
                local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
                local hit = self.entity.hitter:createHit()
                hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
                hit:addBuff(BUFFS:get("STUN"):new(duration))
                hit:applyToPosition(anchor, thisPosition)
            end)
        end

    end

    return lastEvent
end

local BUFF = BUFFS:define("LIGHTNING_WAVE_CONTROLLER")
function BUFF:initialize(duration, direction, abilityStats,...)
    BUFF:super(self, "initialize", duration)
    self.direction = direction
    self.abilityStats = abilityStats
    self.positions = Array:new(...)
end

function BUFF:getDataArgs()
    return self.duration, self.direction, self.abilityStats, self.positions:expand()
end

function BUFF:onTurnStart(anchor, entity)
    self:applyToNextRow(anchor, entity)
    if self.positions:isEmpty() then
        self.duration = 0
    end

end

function BUFF:applyToNextRow(anchor, entity)
    local lastEvent = anchor
    self.positions:acceptSelf(function(position)
        return entity.body:canBePassable(position)
    end)
    if not self.positions:isEmpty() then
        local action = entity.actor:create(STRIKE, self.direction, self.abilityStats)
        action.positions = self.positions
        self.positions = self.positions:map(function(position)
            return position + Vector[self.direction]
        end)
        return action:parallelChainEvent(anchor)
    end

    return anchor
end

function BUFF:shouldCombine(oldBuff)
    return false
end

local ACTION = class(ACTIONS_FRAGMENT.CAST)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self:speedMultiply(ACTION_CONSTANTS.SLOW_CAST_MULTIPLIER)
end

function ACTION:createBuffAt(currentEvent, sourcePosition)
    local area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_CLEAVE)
    local positions = ActionUtils.getCleavePositions(sourcePosition, area, self.direction)
    local buff = BUFF:new(self.abilityStats:get(Tags.STAT_ABILITY_COUNT), self.direction, self.abilityStats, positions:expand())
    self.entity.buffable:apply(buff)
    return buff:applyToNextRow(currentEvent, self.entity)
end

function ACTION:process(currentEvent)
    currentEvent = ACTION:super(self, "process", currentEvent)
    local lastEvent = currentEvent
    for i = 1, self.abilityStats:get(Tags.STAT_ABILITY_AREA_OTHER) do
        local lastEvent = self:createBuffAt(currentEvent, self.entity.body:getPosition() + Vector[self.direction] * (i - 1))
    end

    return lastEvent
end

local LEGENDARY = ITEM:createLegendary("Tempest Visage")
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_AREA_OTHER] = 1 })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_AREA_OTHER, Tags.STAT_UPGRADED)
end
return ITEM

