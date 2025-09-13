local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.amulet_def"):new("Warrior's Amulet")
ITEM.className = "Warrior"
ITEM.classSprite = Vector:new(16, 3)
ITEM.icon = Vector:new(21, 2)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_VALUE] = 2, [Tags.STAT_SECONDARY_VALUE] = 2 })
ITEM:setGrowthMultiplier({ [Tags.STAT_MAX_MANA] = 0 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1, [Tags.STAT_SECONDARY_VALUE] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_SECONDARY_VALUE] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1, [Tags.STAT_SECONDARY_VALUE] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_SECONDARY_VALUE] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1, [Tags.STAT_SECONDARY_VALUE] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_SECONDARY_VALUE] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1, [Tags.STAT_SECONDARY_VALUE] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_SECONDARY_VALUE] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1, [Tags.STAT_SECONDARY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1, [Tags.STAT_SECONDARY_VALUE] = 1 })
local FORMAT_1 = "Your armor ability costs half mana."
local FORMAT_2 = "{C:KEYWORD}Resist %s against {C:KEYWORD}Melee {C:KEYWORD}Attacks. {FORCE_NEWLINE} " .. "{C:KEYWORD}Resist {C:DOWNGRADED}-%s against non-{C:KEYWORD}Melee {C:KEYWORD}Attacks."
ITEM.getPassiveDescription = function(item)
    return Array:new(FORMAT_1, textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_VALUE, Tags.STAT_SECONDARY_VALUE))
end
ITEM.postCreate = function(item)
    item:markAltered(Tags.STAT_SECONDARY_VALUE, Tags.STAT_DOWNGRADED)
end
ITEM.decorateIncomingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositiveDirect() then
        if hit:isDamageAnyMelee() then
            local reduction = abilityStats:get(Tags.STAT_ABILITY_VALUE)
            hit:reduceDamage(abilityStats:get(Tags.STAT_ABILITY_VALUE))
            hit:decreaseBonusState()
        else
            local increase = abilityStats:get(Tags.STAT_SECONDARY_VALUE)
            hit.minDamage = hit.minDamage + increase
            hit.maxDamage = hit.maxDamage + increase
            hit:increaseBonusState()
        end

    end

end
local MIN_MANA_COST = 10
ITEM:setAbilityStatBonus(Tags.STAT_ABILITY_MANA_COST, function(item, baseValue, thisAbilityStats)
    if item:getSlot() == Tags.SLOT_ARMOR then
        if baseValue > MIN_MANA_COST then
            local value = -min(baseValue - MIN_MANA_COST, ceil(baseValue / 2))
            return value
        end

    end

    return 0
end)
local LEGENDARY = ITEM:createLegendary("Apotheosis")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_STEEL
return ITEM

