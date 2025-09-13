local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ACTION_CONSTANTS = require("actions.constants")
local ACTIONS_FRAGMENT = require("actions.fragment")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Flame Gauntlets")
local ABILITY = require("structures.ability_def"):new("Ring of Fire")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(9, 19)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 34, [Tags.STAT_MAX_MANA] = 6, [Tags.STAT_ABILITY_POWER] = 2.75, [Tags.STAT_ABILITY_DAMAGE_BASE] = 20, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.71), [Tags.STAT_SECONDARY_DAMAGE_BASE] = 9, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.71), [Tags.STAT_ABILITY_BURN_DURATION] = 4, [Tags.STAT_ABILITY_AREA_CLEAVE] = 7 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Deal %s damage to %s. {FORCE_NEWLINE} " .. "%s, %s health lost per turn."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_AREA_CLEAVE, Tags.STAT_ABILITY_BURN_DURATION, Tags.STAT_SECONDARY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(11, 9)
ABILITY.iconColor = COLORS.STANDARD_FIRE
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local source = entity.body:getPosition()
    local area = abilityStats:get(Tags.STAT_ABILITY_AREA_CLEAVE)
    for position in (ActionUtils.getCleavePositions(source, area, direction))() do
        castingGuide:indicate(position)
    end

end
local ACTION = class(ACTIONS_FRAGMENT.ENCHANT)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self.sound = "WEAPON_CHARGE"
end

function ACTION:process(currentEvent)
    local source = self.entity.body:getPosition()
    return ACTION:super(self, "process", currentEvent):chainEvent(function(_, anchor)
        Common.playSFX("BURN_DAMAGE", 1, 2)
        for direction in DIRECTIONS_AA() do
            if direction ~= reverseDirection(self.direction) then
                local hit = self.entity.hitter:createHit()
                hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
                hit:setSpawnFireFromSecondary(self.abilityStats)
                hit:applyToPosition(anchor, source + Vector[direction])
            end

        end

    end):chainProgress(0.3):chainEvent(function(_, anchor)
        Common.playSFX("BURN_DAMAGE", 1, 2)
        for direction in DIRECTIONS_DIAGONAL() do
            local hit = self.entity.hitter:createHit()
            hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
            hit:setSpawnFireFromSecondary(self.abilityStats)
            hit:applyToPosition(anchor, source + Vector[direction])
        end

    end)
end

local LEGENDARY = ITEM:createLegendary("Fire and Brimstone")
local LEGENDARY_FORMAT = "{C:KEYWORD}Resist %s against enemies standing on {C:KEYWORD}Burn spaces."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 2 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_FORMAT, item, Tags.STAT_MODIFIER_VALUE)
end
LEGENDARY.decorateIncomingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositiveDirect() and hit.sourceEntity then
        if hit.sourceEntity:hasComponent("agent") then
            if entity.body:hasSteppableExclusivity(hit.sourcePosition, Tags.STEP_EXCLUSIVE_ENGULF) then
                hit:reduceDamage(abilityStats:get(Tags.STAT_MODIFIER_VALUE))
                hit:decreaseBonusState()
            end

        end

    end

end
return ITEM

