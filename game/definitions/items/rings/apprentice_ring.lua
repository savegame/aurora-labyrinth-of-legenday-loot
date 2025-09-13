local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local CONSTANTS = require("logic.constants")
local ITEM = require("structures.item_def"):new("Apprentice Ring")
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(12, 18)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_VALUE] = 5 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
local MIN_MANA_COST = 5
local FORMAT = "Reduce all ability mana costs by %s."
ITEM.getPassiveDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_VALUE)
end
ITEM:setAbilityStatBonus(Tags.STAT_ABILITY_MANA_COST, function(item, baseValue, thisAbilityStats)
        if thisAbilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 and baseValue >= thisAbilityStats:get(Tags.STAT_MODIFIER_VALUE) then
        local minValue = thisAbilityStats:get(Tags.STAT_MODIFIER_VALUE_2)
        return -min(baseValue - minValue, thisAbilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN))
    elseif baseValue > MIN_MANA_COST then
        return -min(baseValue - MIN_MANA_COST, thisAbilityStats:get(Tags.STAT_ABILITY_VALUE))
    else
        return 0
    end

end)
local LEGENDARY = ITEM:createLegendary("Gift of the Magi")
LEGENDARY.strokeColor = COLORS.STANDARD_GHOST
local LEGENDARY_EXTRA_LINE = "Reduce abilities that cost %s mana or more by %s instead (min. %s{C:BASE})."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 20, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = 0, [Tags.STAT_MODIFIER_VALUE] = 120, [Tags.STAT_MODIFIER_VALUE_2] = 100 })
LEGENDARY.passiveExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_VALUE, Tags.STAT_MODIFIER_DAMAGE_MIN, Tags.STAT_MODIFIER_VALUE_2)
end
return ITEM

