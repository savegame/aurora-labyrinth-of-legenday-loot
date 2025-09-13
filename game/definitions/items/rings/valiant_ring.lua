local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local Common = require("common")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Valiant Ring")
ITEM:setToMediumComplexity()
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(11, 4)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_COUNT] = 3, [Tags.STAT_ABILITY_DAMAGE_BASE] = 8.4, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.41) })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 1 })
local FORMAT = "If %s or more abilities are on cooldown, deal %s bonus damage."
ITEM.getPassiveDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_COUNT, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ITEM.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositiveDirect() then
        local onCooldown = 0
        local equipment = entity.equipment
        local SLOTS_WITH_ABILITIES = require("definitions.items").SLOTS_WITH_ABILITIES
        for slot in SLOTS_WITH_ABILITIES() do
            if equipment:get(slot) and not equipment:isReady(slot) then
                onCooldown = onCooldown + 1
            end

        end

        if onCooldown >= abilityStats:get(Tags.STAT_ABILITY_COUNT) then
            hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN)
            hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX)
            hit:increaseBonusState()
        end

    end

end
local LEGENDARY = ITEM:createLegendary("Ring of the Undaunted")
local LEGENDARY_EXTRA_LINE = "Reduce all mana costs by half, but increase all cooldowns by %s."
LEGENDARY.strokeColor = COLORS.STANDARD_STEEL
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 10 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = -1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = -1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = -1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = -1 })
LEGENDARY.passiveExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_VALUE)
end
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_MODIFIER_VALUE, Tags.STAT_DOWNGRADED)
end
LEGENDARY:setAbilityStatBonus(Tags.STAT_ABILITY_MANA_COST, function(item, baseValue, thisAbilityStats, entity, currentValue)
    if entity.equipment:getSlotsWithAbilities():contains(item.stats:get(Tags.STAT_SLOT)) then
        return -floor(baseValue / 2)
    end

    return 0
end)
LEGENDARY:setAbilityStatBonus(Tags.STAT_ABILITY_COOLDOWN, function(item, baseValue, thisAbilityStats, entity, currentValue)
    return thisAbilityStats:get(Tags.STAT_MODIFIER_VALUE)
end)
return ITEM

