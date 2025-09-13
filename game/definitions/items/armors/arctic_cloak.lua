local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Arctic Cloak")
local ABILITY = require("structures.ability_def"):new("Frost Nova")
ABILITY:addTag(Tags.ABILITY_TAG_DEBUFF_COLD)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(14, 12)
ITEM:setToStatsBase({ [Tags.STAT_MAX_MANA] = 60, [Tags.STAT_ABILITY_POWER] = 2.75, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 3, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_OCTAGON_7X7 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Apply {C:KEYWORD}Cold for %s to all enemies in a " .. "%s around you."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DEBUFF_DURATION, Tags.STAT_ABILITY_AREA_ROUND)
end
ABILITY.icon = Vector:new(7, 6)
ABILITY.iconColor = COLORS.STANDARD_ICE
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

    return TERMS.INVALID_DIRECTION_NO_ENEMY
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
local EXPLOSION_EXPAND_DURATION_LARGE = 0.14
local EXPLOSION_DISPERSE_DURATION = 0.85
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
    self:addComponent("explosion")
    self.explosion.excludeSelf = true
    self.explosion:setHueToIce()
end

function ACTION:process(currentEvent)
    local source = self.entity.body:getPosition()
    self.explosion.source = source
    local area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    self.explosion:setArea(area)
    Common.playSFX("CAST_CHARGE")
    currentEvent = self.outline:chainFullEvent(currentEvent, ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION)
    local expandDuration = EXPLOSION_EXPAND_DURATION
    if area > Tags.ABILITY_AREA_ROUND_5X5 then
        expandDuration = EXPLOSION_EXPAND_DURATION_LARGE
    end

    local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
    currentEvent:chainEvent(function()
        Common.playSFX("EXPLOSION_ICE", 0.5)
    end)
    currentEvent = self.explosion:chainExpandEvent(currentEvent, expandDuration, function(anchor, position)
        local hit = self.entity.hitter:createHit()
        hit.sound = false
        hit:addBuff(BUFFS:get("COLD"):new(duration))
        hit:applyToPosition(anchor, position)
    end)
    self.explosion:chainDisperseEvent(currentEvent, EXPLOSION_DISPERSE_DURATION)
    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Cloak of the Coldest Night")
local LEGENDARY_STAT_LINE = "Whenever a {C:KEYWORD}Cold enemy hits you, prevent it and reduce their {C:KEYWORD}Cold duration by %s."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_VALUE)
end
LEGENDARY.decorateIncomingHit = function(entity, hit, abilityStats)
    if hit:isDamageOrDebuff() then
        if hit.sourceEntity and hit.sourceEntity:hasComponent("buffable") then
            if hit.sourceEntity.buffable:isAffectedBy(BUFFS:get("COLD")) then
                hit:clear()
                hit.sound = "HIT_BLOCKED"
                hit.forceFlash = true
                local value = abilityStats:get(Tags.STAT_MODIFIER_VALUE)
                hit.sourceEntity.buffable:extend(BUFFS:get("COLD"), -value)
            end

        end

    end

end
return ITEM

