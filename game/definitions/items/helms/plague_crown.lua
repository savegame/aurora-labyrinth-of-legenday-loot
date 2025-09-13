local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Plague Crown")
local ABILITY = require("structures.ability_def"):new("Poison Nova")
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(5, 16)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 4, [Tags.STAT_MAX_MANA] = 36, [Tags.STAT_ABILITY_POWER] = 6.5, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 8, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_ROUND_5X5, [Tags.STAT_POISON_DAMAGE_BASE] = 6.6 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_AREA_ROUND] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
local FORMAT = "{C:KEYWORD}Poison all enemies in a %s around you, making them lose %s health " .. "over %s. This {C:KEYWORD}Poison takes more health towards the end."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_AREA_ROUND, Tags.STAT_POISON_DAMAGE_TOTAL, Tags.STAT_ABILITY_DEBUFF_DURATION)
end
ABILITY.icon = Vector:new(9, 3)
ABILITY.iconColor = COLORS.STANDARD_POISON
ABILITY.directions = false
ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local origin = entity.body:getPosition()
    local area = abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    for position in (ActionUtils.getAreaPositions(entity, origin, area, true))() do
        local entityAt = entity.body:getEntityAt(position)
        if entityAt and entityAt:hasComponent("buffable") then
            return false
        end

    end

    return false
end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local source = entity.body:getPosition()
    local area = abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    for position in (ActionUtils.getAreaPositions(entity, source, area, true))() do
        local entityAt = entity.body:getEntityAt(position)
        if entityAt and entityAt:hasComponent("buffable") then
            castingGuide:indicate(position)
        else
            castingGuide:indicateWeak(position)
        end

    end

end
local EXPLOSION_EXPAND_DURATION = 0.12
local EXPLOSION_EXPAND_DURATION_LARGE = 0.15
local EXPLOSION_DISPERSE_DURATION = 0.85
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
    self:addComponent("explosion")
    self.outline.color = ABILITY.iconColor
    self.explosion.excludeSelf = true
    self.explosion:setHueToPoison()
end

function ACTION:process(currentEvent)
    self.explosion.source = self.entity.body:getPosition()
    local area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    self.explosion:setArea(area)
    Common.playSFX("CAST_CHARGE")
    currentEvent = self.outline:chainFullEvent(currentEvent, ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION)
    local expandDuration = EXPLOSION_EXPAND_DURATION
    if area > Tags.ABILITY_AREA_ROUND_5X5 then
        expandDuration = EXPLOSION_EXPAND_DURATION_LARGE
    end

    local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
    local halfDuration = (duration / 2)
    local poisonDamage = self.abilityStats:get(Tags.STAT_POISON_DAMAGE_TOTAL)
    local printed = false
    currentEvent:chainEvent(function()
        Common.playSFX("EXPLOSION_POISON", EXPLOSION_EXPAND_DURATION / expandDuration)
    end)
    currentEvent = self.explosion:chainExpandEvent(currentEvent, expandDuration, function(anchor, position)
        local hit = self.entity.hitter:createHit()
        hit.sound = false
        local buff = BUFFS:get("POISON"):new(duration, self.entity, poisonDamage)
        local lowestRatio = 0.5
        buff.damageTicks = buff.damageTicks:reversed()
        for i = 1, ceil(halfDuration) do
            local ratio = 1 - (1 - lowestRatio) * (halfDuration - i + 0.5) / (halfDuration - 1 + 0.5)
            if ratio < 1 then
                local newTick = floor(buff.damageTicks[i] * ratio)
                buff.damageTicks[duration - i + 1] = buff.damageTicks[duration - i + 1] + (buff.damageTicks[i] - newTick)
                buff.damageTicks[i] = newTick
            end

        end

        if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
            buff.damageTicks:push(self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN))
            buff.duration = buff.duration + 1
        end

        hit:addBuff(buff)
        hit:applyToPosition(anchor, position)
    end)
    self.explosion:chainDisperseEvent(currentEvent, EXPLOSION_DISPERSE_DURATION)
    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Blighted Dominion")
local LEGENDARY_EXTRA_LINE = "Add a final {C:KEYWORD}Poison tick that will take %s health."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 75 / 2.5, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = 0, [Tags.STAT_MODIFIER_AREA_ROUND] = Tags.ABILITY_AREA_3X3 })
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
return ITEM

