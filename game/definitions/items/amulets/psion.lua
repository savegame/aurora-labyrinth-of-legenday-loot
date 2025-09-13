local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local Common = require("common")
local TRIGGERS = require("actions.triggers")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.amulet_def"):new("Psion's Amulet")
ITEM.className = "Psion"
ITEM.classSprite = Vector:new(20, 3)
ITEM.icon = Vector:new(18, 18)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_RANGE] = 1, [Tags.STAT_SECONDARY_RANGE] = 3, [Tags.STAT_ABILITY_VALUE] = 1, [Tags.STAT_ABILITY_DAMAGE_BASE] = 11, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.1) })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
local FORMAT_1 = "Increase push distance by %s."
local MIN_MANA_COST = 10
local FORMAT_2 = "Increase damage by %s to " .. "targets at least %s away."
ITEM.getPassiveDescription = function(item)
    return Array:new(textStatFormat(FORMAT_1, item, Tags.STAT_ABILITY_RANGE), textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_SECONDARY_RANGE))
end
ITEM.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit.knockback and not hit.knockback.isPull then
        hit.knockback.distance = hit.knockback.distance + abilityStats:get(Tags.STAT_ABILITY_RANGE)
    end

    if hit:isDamagePositiveDirect() then
        local range = abilityStats:get(Tags.STAT_SECONDARY_RANGE)
        if hit:getApplyDistance() >= range then
            hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN)
            hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX)
            hit:increaseBonusState()
        end

    end

end
local LEGENDARY = ITEM:createLegendary("Reflection of Infinity")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_PSYCHIC
return ITEM

