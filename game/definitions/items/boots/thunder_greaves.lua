local Vector = require("utils.classes.vector")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local Common = require("common")
local ACTION_CONSTANTS = require("actions.constants")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local TERMS = require("text.terms")
local ITEM = require("structures.item_def"):new("Thunder Greaves")
local ABILITY = require("structures.ability_def"):new("Thunder Stomp")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ABILITY:addTag(Tags.ABILITY_TAG_SURROUNDING_DISABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(18, 15)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 34, [Tags.STAT_MAX_MANA] = 6, [Tags.STAT_ABILITY_POWER] = 2.73, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_CROSS, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1, [Tags.STAT_ABILITY_DAMAGE_BASE] = 16.4, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.93) })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Deal %s damage and {C:KEYWORD}Stun "
local FORMAT_LEGENDARY = "{C:STAT_LINE}all {C:STAT_LINE}visible {C:STAT_LINE}enemies for %s."
local FORMAT_NORMAL = "all adjacent targets for %s."
ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    if abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        local hasAgent = entity.agentvisitor:visit(function(agent)
            local position = agent.body:getPosition()
            if entity.vision:isVisible(position) then
                return true
            end

        end)
        if not hasAgent then
            return TERMS.INVALID_DIRECTION_NO_ENEMY
        end

    else
        return false
    end

end
ABILITY.getDescription = function(item)
    if item.stats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        return textStatFormat(FORMAT .. FORMAT_LEGENDARY, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_DEBUFF_DURATION)
    else
        return textStatFormat(FORMAT .. FORMAT_NORMAL, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_DEBUFF_DURATION)
    end

end
ABILITY.icon = Vector:new(2, 4)
ABILITY.iconColor = COLORS.STANDARD_LIGHTNING
ABILITY.directions = false
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    if abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        entity.agentvisitor:visit(function(agent)
            local position = agent.body:getPosition()
            if entity.vision:isVisible(position) then
                castingGuide:indicate(position)
            end

        end)
    else
        local position = entity.body:getPosition()
        ActionUtils.indicateArea(entity, position, abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND), castingGuide, true)
    end

end
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local JUMP_HEIGHT = 0.7
local JUMP_DURATION = 0.2
local JUMP_HOLD_DURATION = 0.1
local FALL_DURATION = 0.12
local FALL_HOLD_DURATION = 0.25
local LIGHTNING_WAIT = 0.2
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("jump")
    self.jump.height = JUMP_HEIGHT
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
    self:addComponent("charactertrail")
    self:addComponent("lightningspawner")
    self.lightningspawner.lightningCount = 2
end

function ACTION:affectTarget(anchor, target)
    return self.lightningspawner:spawn(anchor, target):chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit()
        local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
        hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        hit:addBuff(BUFFS:get("STUN"):new(duration))
        hit:applyToPosition(anchor, target)
    end)
end

function ACTION:process(currentEvent)
    local source = self.entity.body:getPosition()
    Common.playSFX("CAST_CHARGE")
    self.charactertrail:start(currentEvent)
    self.outline:chainFadeIn(currentEvent, JUMP_DURATION + JUMP_HOLD_DURATION)
    currentEvent = self.jump:chainRiseEvent(currentEvent, JUMP_DURATION)
    currentEvent = currentEvent:chainProgress(JUMP_HOLD_DURATION)
    currentEvent = self.jump:chainFallEvent(currentEvent, FALL_DURATION):chainEvent(function(_, anchor)
        Common.playSFX("ROCK_SHAKE")
        self.charactertrail:stop()
        self:shakeScreen(anchor, 3)
    end):chainProgress(LIGHTNING_WAIT):chainEvent(function()
        Common.playSFX("LIGHTNING")
    end)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        self.entity.agentvisitor:visit(function(agent)
            local target = agent.body:getPosition()
            if self.entity.vision:isVisible(target) then
                self:affectTarget(currentEvent, target)
            end

        end, false, false)
    else
        local area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
        for target in (ActionUtils.getAreaPositions(self.entity, source, area, true))() do
            self:affectTarget(currentEvent, target)
        end

    end

    self.outline:chainFadeOut(currentEvent, FALL_HOLD_DURATION)
    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Olympian Greaves")
return ITEM

