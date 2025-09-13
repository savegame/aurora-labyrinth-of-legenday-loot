local Vector = require("utils.classes.vector")
local CONSTANTS = require("logic.constants")
local Common = require("common")
local ACTIONS_BASIC = require("actions.basic")
local ACTION_CONSTANTS = require("actions.constants")
local ActionUtils = require("actions.utils")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Psychic Hat")
local ABILITY = require("structures.ability_def"):new("Telekinetic Force")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ABILITY:addTag(Tags.ABILITY_TAG_DISENGAGE_MELEE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(2, 16)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 10, [Tags.STAT_MAX_MANA] = 30, [Tags.STAT_ABILITY_POWER] = 3.9, [Tags.STAT_ABILITY_DAMAGE_BASE] = 27.6, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.09), [Tags.STAT_ABILITY_RANGE] = 2, [Tags.STAT_ABILITY_AREA_CLEAVE] = 5, [Tags.STAT_KNOCKBACK_DAMAGE_BASE] = CONSTANTS.KNOCKBACK_DAMAGE_BASE, [Tags.STAT_KNOCKBACK_DAMAGE_VARIANCE] = CONSTANTS.KNOCKBACK_DAMAGE_VARIANCE })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_AREA_CLEAVE] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_AREA_CLEAVE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Deal %s damage to %s. {C:KEYWORD}Push all targets %s away."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_AREA_CLEAVE, Tags.STAT_ABILITY_RANGE)
end
ABILITY.icon = Vector:new(3, 3)
ABILITY.iconColor = COLORS.STANDARD_PSYCHIC
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local source = entity.body:getPosition()
    local area = abilityStats:get(Tags.STAT_ABILITY_AREA_CLEAVE)
    for position in (ActionUtils.getCleavePositions(source, area, direction))() do
        castingGuide:indicate(position)
    end

end
ABILITY.directions = function(entity, abilityStats)
    local area = abilityStats:get(Tags.STAT_ABILITY_AREA_CLEAVE)
    if area == 8 then
        return false
    else
        return DIRECTIONS_AA
    end

end
local KNOCKBACK_STEP_DURATION = 0.11
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
end

function ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    local abilityStats = self.abilityStats
    local range = abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local diagonalRange = round(range / math.sqrtOf2)
    Common.playSFX("CAST_CHARGE")
    return self.outline:chainFullEvent(currentEvent, ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION):chainEvent(function(_, anchor)
        local area = abilityStats:get(Tags.STAT_ABILITY_AREA_CLEAVE)
        local source = self.entity.body:getPosition()
        for target in (ActionUtils.getCleavePositions(source, area, self.direction))() do
            local hit = self.entity.hitter:createHit()
            hit.soundPitch = 0.75
            hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, abilityStats)
            local direction = Common.getDirectionTowards(source, target, false, true)
            if isDiagonal(direction) then
                hit:setKnockback(diagonalRange, direction, KNOCKBACK_STEP_DURATION * math.sqrtOf2)
            else
                hit:setKnockback(range, direction, KNOCKBACK_STEP_DURATION)
            end

            hit:setKnockbackDamage(abilityStats)
            hit:applyToPosition(anchor, target)
        end

    end)
end

local LEGENDARY = ITEM:createLegendary("Mindforce")
local LEGENDARY_STAT_LINE = "{C:KEYWORD}Pushing a target into an obstacle deals %s bonus damage " .. "for every space it moved {C:NUMBER}+1."
local KNOCKBACK_MULTIPLIER = 0.5
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = CONSTANTS.KNOCKBACK_DAMAGE_BASE * KNOCKBACK_MULTIPLIER, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = CONSTANTS.KNOCKBACK_DAMAGE_VARIANCE, [Tags.STAT_KNOCKBACK_DAMAGE_BOOSTED] = 1 })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
LEGENDARY.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit.knockback and not hit.knockback.isPull then
        hit.knockback.distanceMinDamage = abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
        hit.knockback.distanceMaxDamage = abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
    end

end
return ITEM

