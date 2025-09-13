local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local TRIGGERS = require("actions.triggers")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local Common = require("common")
local ITEM = require("structures.amulet_def"):new("Warlock's Amulet")
ITEM.className = "Warlock"
ITEM.classSprite = Vector:new(14, 3)
ITEM.icon = Vector:new(17, 19)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_VALUE] = 1, [Tags.STAT_ABILITY_LIMIT] = 15 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_LIMIT] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_LIMIT] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_LIMIT] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_LIMIT] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_LIMIT] = -1 })
local FORMAT_1 = "If you don't have enough mana to pay for an ability, you can pay half the amount " .. "in health instead."
local FORMAT_2 = "Reduce all ability cooldowns over %s turns by %s (min. %s{C:BASE})."
ITEM.getPassiveDescription = function(item)
    return Array:new(FORMAT_1, textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_LIMIT, Tags.STAT_ABILITY_VALUE, Tags.STAT_ABILITY_LIMIT))
end
ITEM:setAbilityStatBonus(Tags.STAT_ABILITY_COOLDOWN, function(item, baseValue, thisAbilityStats, entity, currentValue)
    if item:isAccessory() then
        return 0
    end

    local discountLine = thisAbilityStats:get(Tags.STAT_ABILITY_LIMIT)
    if currentValue > discountLine then
        local value = -min(currentValue - discountLine, thisAbilityStats:get(Tags.STAT_ABILITY_VALUE))
        return value
    else
        return 0
    end

end)
ITEM:setAbilityStatBonus(Tags.STAT_ABILITY_MANA_COST, function(item, baseValue, thisAbilityStats, entity, currentValue)
    if item:isAccessory() then
        return 0
    end

    if entity.mana:getCurrent() < currentValue then
        return -currentValue
    else
        return 0
    end

end)
ITEM:setAbilityStatBonus(Tags.STAT_ABILITY_HEALTH_COST, function(item, baseValue, thisAbilityStats, entity, currentValue)
    if item:isAccessory() then
        return 0
    end

    if baseValue == 0 and currentValue == 0 then
        local slotCost = entity.equipment:getSlotStat(item:getSlot(), Tags.STAT_ABILITY_MANA_COST, thisAbilityStats:get(Tags.STAT_SLOT))
        if entity.mana:getCurrent() < slotCost then
            return ceil(slotCost / 2)
        end

    end

    return 0
end)
local LEGENDARY = ITEM:createLegendary("Fragment of the Dead God")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_RAGE
return ITEM

