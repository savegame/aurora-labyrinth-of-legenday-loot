local Array = require("utils.classes.array")
local Range = require("utils.classes.range")
local Hash = require("utils.classes.hash")
local Common = require("common")
local ModifierDef = require("structures.modifier_def")
local CONSTANTS = require("logic.constants")
local textStatFormat = require("text.stat_format")
local RESILIENCE = ModifierDef:new("Resilience")
RESILIENCE:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 20 })
RESILIENCE.modifyItem = function(item)
    item:markAltered(Tags.STAT_MAX_HEALTH, Tags.STAT_UPGRADED)
end
RESILIENCE.canRoll = function(itemDef)
    return itemDef.statsBase:get(Tags.STAT_MAX_HEALTH, 0) > 0
end
local SPIRIT = ModifierDef:new("Spirit")
SPIRIT:setToStatsBase({ [Tags.STAT_MAX_MANA] = 20 })
SPIRIT.modifyItem = function(item)
    item:markAltered(Tags.STAT_MAX_MANA, Tags.STAT_UPGRADED)
end
SPIRIT.canRoll = function(itemDef)
    if itemDef.statsBase:get(Tags.STAT_COOLDOWN_REDUCTION, 0) > 0 then
        return true
    end

    return itemDef.statsBase:get(Tags.STAT_MAX_MANA, 0) > 0
end
local SKILL = ModifierDef:new("Skill")
local SKILL_DISCOUNT = 0.35
local SKILL_COOLDOWN_PENALTY = 0.2
SKILL.modifyItem = function(item)
    local cooldown = item:getStatAtMax(Tags.STAT_ABILITY_COOLDOWN)
    local costStat = Tags.STAT_ABILITY_MANA_COST
    if item.stats:get(Tags.STAT_ABILITY_HEALTH_COST, 0) > 0 then
        costStat = Tags.STAT_ABILITY_HEALTH_COST
    end

    local cost = item:getStatAtMax(costStat)
    local cooldownPenalty = max(1, round(cooldown * SKILL_COOLDOWN_PENALTY))
    item.stats:add(Tags.STAT_ABILITY_COOLDOWN, cooldownPenalty)
    item:markAltered(Tags.STAT_ABILITY_COOLDOWN, Tags.STAT_DOWNGRADED)
    local discount = round(cost * SKILL_DISCOUNT)
    item.stats:set(costStat, max(1, item.stats:get(costStat) - max(1, discount)))
    item:markAltered(costStat, Tags.STAT_UPGRADED)
end
SKILL.canRoll = function(itemDef)
    if itemDef:getStatAtMax(Tags.STAT_ABILITY_COOLDOWN, 0) <= 1 then
        return false
    end

    return ((itemDef:getStatAtMax(Tags.STAT_ABILITY_MANA_COST) >= 6) or (itemDef:getStatAtMax(Tags.STAT_ABILITY_HEALTH_COST) >= 6))
end
local PROWESS = ModifierDef:new("Prowess")
local PROWESS_WITH_NO_PENALTY = 0.25
PROWESS.modifyItem = function(item)
    local cooldown = item:getStatAtMax(Tags.STAT_ABILITY_COOLDOWN)
    local reduction = round(cooldown * PROWESS_WITH_NO_PENALTY)
    local baseValue = item.stats:get(Tags.STAT_ABILITY_COOLDOWN)
    item.stats:set(Tags.STAT_ABILITY_COOLDOWN, max(1, baseValue - max(1, reduction)))
    item:markAltered(Tags.STAT_ABILITY_COOLDOWN, Tags.STAT_UPGRADED)
end
PROWESS.canRoll = function(itemDef)
    if itemDef:getStatAtMax(Tags.STAT_ABILITY_MANA_COST) <= 0 and itemDef:getStatAtMax(Tags.STAT_ABILITY_HEALTH_COST) <= 0 then
        return false
    end

    return (itemDef:getStatAtMax(Tags.STAT_ABILITY_COOLDOWN) >= 12)
end
local SAVAGERY = ModifierDef:new("Savagery")
SAVAGERY:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 4 })
SAVAGERY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 1 })
SAVAGERY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 1 })
SAVAGERY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 1 })
SAVAGERY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 1 })
SAVAGERY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 1 })
SAVAGERY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 1 })
SAVAGERY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ATTACK_DAMAGE_MAX, Tags.STAT_UPGRADED)
end
SAVAGERY.canRoll = function(itemDef)
    return itemDef.slot == Tags.SLOT_WEAPON
end
local ACCURACY = ModifierDef:new("Accuracy")
ACCURACY:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_MIN] = 3 })
ACCURACY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MIN] = 1 })
ACCURACY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MIN] = 1 })
ACCURACY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MIN] = 1 })
ACCURACY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MIN] = 1 })
ACCURACY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MIN] = 1 })
ACCURACY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MIN] = 1 })
ACCURACY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MIN] = 1 })
ACCURACY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ATTACK_DAMAGE_MIN, Tags.STAT_UPGRADED)
end
ACCURACY.canRoll = function(itemDef)
    return itemDef.slot == Tags.SLOT_WEAPON
end
local COMBAT = ModifierDef:new("Combat")
COMBAT:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 2, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.5) })
COMBAT.modifyItem = function(item)
    item:markAltered(Tags.STAT_ATTACK_DAMAGE_MIN, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ATTACK_DAMAGE_MAX, Tags.STAT_UPGRADED)
end
COMBAT.canRoll = function(itemDef)
    return itemDef.slot == Tags.SLOT_GLOVES or itemDef.slot == Tags.SLOT_HELM or itemDef.slot == Tags.SLOT_BOOTS
end
local WIZARDRY = ModifierDef:new("Wizardry")
WIZARDRY:setToStatsBase({ [Tags.STAT_COOLDOWN_REDUCTION] = 1 })
WIZARDRY.canRoll = function(itemDef)
    return itemDef.slot == Tags.SLOT_HELM
end
local JOURNEY = ModifierDef:new("Journey")
JOURNEY.modifyItem = function(item)
    if item.stats:get(Tags.STAT_ABILITY_RANGE, 0) > 0 then
        item.stats:add(Tags.STAT_ABILITY_RANGE, 1)
        item:markAltered(Tags.STAT_ABILITY_RANGE, Tags.STAT_UPGRADED)
    else
        item.stats:add(Tags.STAT_SECONDARY_RANGE, 1)
        item:markAltered(Tags.STAT_SECONDARY_RANGE, Tags.STAT_UPGRADED)
    end

end
JOURNEY.canRoll = function(itemDef)
    local ability = itemDef.ability
    return ability:hasTag(Tags.ABILITY_TAG_MOVEMENT_EXTENDABLE)
end
local HORIZON = ModifierDef:new("the Horizon")
HORIZON:setToStatsBase({ [Tags.STAT_ABILITY_RANGE] = 2 })
HORIZON.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_RANGE, Tags.STAT_UPGRADED)
end
HORIZON.canRoll = function(itemDef)
    local ability = itemDef.ability
    return ability:hasTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
end
local MARKSMAN = ModifierDef:new("Marksmanship")
MARKSMAN:setToStatsBase({ [Tags.STAT_ABILITY_PROJECTILE_SPEED] = 1 })
MARKSMAN:addPowerSpike()
MARKSMAN:addPowerSpike()
MARKSMAN:addPowerSpike({ [Tags.STAT_ABILITY_PROJECTILE_SPEED] = 1 })
MARKSMAN:addPowerSpike()
local MARKSMAN_FORMAT = "{C:NUMBER}+%d {C:KEYWORD}Projectile speed."
MARKSMAN.abilityExtraLine = function(item)
    return MARKSMAN_FORMAT:format(item.stats:get(Tags.STAT_ABILITY_PROJECTILE_SPEED) - CONSTANTS.PLAYER_PROJECTILE_SPEED)
end
MARKSMAN.canRoll = function(itemDef)
    return itemDef.statsBase:get(Tags.STAT_ABILITY_PROJECTILE_SPEED, 0) > 0
end
local KINGS = ModifierDef:new("Kings")
local KINGS_BONUS = 0.25
local KINGS_COST_PENALTY = 0.15
KINGS.modifyItem = function(item)
    local multiplier = 1 + KINGS_BONUS
    if item:getAbility():hasTag(Tags.ABILITY_TAG_PLUS_BASIC_ATTACK) then
        local minDamage = item.stats:get(Tags.STAT_ABILITY_DAMAGE_MIN)
        local maxDamage = item.stats:get(Tags.STAT_ABILITY_DAMAGE_MAX)
        local average = (minDamage + maxDamage) / 2
        multiplier = (average * multiplier + 4) / average
    end

    item:multiplyStatAndGrowth(Tags.STAT_ABILITY_DAMAGE_MIN, multiplier)
    item:multiplyStatAndGrowth(Tags.STAT_ABILITY_DAMAGE_MAX, multiplier)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MAX, Tags.STAT_UPGRADED)
    local costStat = Tags.STAT_ABILITY_MANA_COST
    if item.stats:get(Tags.STAT_ABILITY_HEALTH_COST, 0) > 0 then
        costStat = Tags.STAT_ABILITY_HEALTH_COST
    end

    local cost = item:getStatAtMax(costStat)
    local costPenalty = max(1, round(cost * KINGS_COST_PENALTY))
    item.stats:add(costStat, costPenalty)
    item:markAltered(costStat, Tags.STAT_DOWNGRADED)
end
KINGS.canRoll = function(itemDef)
    local statsBase = itemDef.statsBase
    if itemDef:getStatAtMax(Tags.STAT_ABILITY_MANA_COST) < 10 then
        if itemDef:getStatAtMax(Tags.STAT_ABILITY_HEALTH_COST) < 10 then
            return false
        end

    end

    local statsBase = itemDef.statsBase
    local abilityDamage = statsBase:get(Tags.STAT_ABILITY_DAMAGE_MIN, 0)
    if abilityDamage > 1 and abilityDamage ~= statsBase:get(Tags.STAT_ATTACK_DAMAGE_MIN, 0) then
        if statsBase:get(Tags.STAT_ABILITY_BURN_DURATION, 0) > 0 then
            local secondaryDamage = statsBase:get(Tags.STAT_SECONDARY_DAMAGE_MIN, 0)
            if secondaryDamage >= abilityDamage then
                return false
            end

        end

        return true
    else
        return false
    end

end
local LONGEVITY = ModifierDef:new("Longevity")
LONGEVITY:setToStatsBase({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
LONGEVITY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_UPGRADED)
end
LONGEVITY.canRoll = function(itemDef)
    local ability = itemDef.ability
    if ability:hasTag(Tags.ABILITY_TAG_BUFF_NO_EXTEND) then
        return false
    else
        return itemDef.statsBase:get(Tags.STAT_ABILITY_BUFF_DURATION, 0) > 1
    end

end
local IGNITION = ModifierDef:new("Ignition")
IGNITION:setToStatsBase({ [Tags.STAT_ABILITY_BURN_DURATION] = 1 })
local IGNITION_BONUS = 0.5
IGNITION.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_BURN_DURATION, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_SECONDARY_DAMAGE_MIN, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_SECONDARY_DAMAGE_MAX, Tags.STAT_UPGRADED)
    item:multiplyStatAndGrowth(Tags.STAT_SECONDARY_DAMAGE_MIN, 1 + IGNITION_BONUS)
    item:multiplyStatAndGrowth(Tags.STAT_SECONDARY_DAMAGE_MAX, 1 + IGNITION_BONUS)
end
IGNITION.canRoll = function(itemDef)
    return itemDef.statsBase:get(Tags.STAT_ABILITY_BURN_DURATION, 0) > 1
end
local MOMENTUM = ModifierDef:new("Momentum")
local MOMENTUM_FORMAT = "{C:KEYWORD}Pushing an enemy into an obstacle deals %s bonus damage."
MOMENTUM:setToStatsBase({ [Tags.STAT_KNOCKBACK_DAMAGE_BASE] = CONSTANTS.KNOCKBACK_DAMAGE_BASE / 2, [Tags.STAT_KNOCKBACK_DAMAGE_VARIANCE] = CONSTANTS.KNOCKBACK_DAMAGE_VARIANCE, [Tags.STAT_MODIFIER_DAMAGE_BASE] = CONSTANTS.KNOCKBACK_DAMAGE_BASE / 2, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = CONSTANTS.KNOCKBACK_DAMAGE_VARIANCE, [Tags.STAT_KNOCKBACK_DAMAGE_BOOSTED] = 1 })
MOMENTUM.abilityExtraLine = function(item)
    return textStatFormat(MOMENTUM_FORMAT, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
MOMENTUM.canRoll = function(itemDef)
    return itemDef.statsBase:get(Tags.STAT_KNOCKBACK_DAMAGE_MIN, 0) > 0
end
local DISEASE = ModifierDef:new("Affliction")
DISEASE.modifyItem = function(item)
    local bonusDuration = 2
    local currentDuration = item.stats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
    local currentValue = item.stats:get(Tags.STAT_POISON_DAMAGE_TOTAL)
    local targetValue = ceil(currentValue * (bonusDuration + currentDuration) / currentDuration)
    local previousBonus = targetValue - currentValue
    item.stats:add(Tags.STAT_POISON_DAMAGE_TOTAL, previousBonus, 0)
    item.stats:add(Tags.STAT_ABILITY_DEBUFF_DURATION, bonusDuration, 0)
    if item.stats:hasKey(Tags.STAT_ABILITY_BUFF_DURATION) then
        item.stats:add(Tags.STAT_ABILITY_BUFF_DURATION, bonusDuration, 0)
    end

    for i = 1, CONSTANTS.ITEM_UPGRADE_LEVELS do
        local growthForLevel = item:getGrowthForLevel(i)
        local growthDamage = growthForLevel:get(Tags.STAT_POISON_DAMAGE_TOTAL, 0)
        local previousValue = currentValue
        currentValue = currentValue + growthDamage
        currentDuration = currentDuration + growthForLevel:get(Tags.STAT_ABILITY_DEBUFF_DURATION, 0)
        targetValue = ceil(currentValue * (bonusDuration + currentDuration) / currentDuration)
        item.extraGrowth:set(i, Hash:new({ [Tags.STAT_POISON_DAMAGE_TOTAL] = targetValue - currentValue - previousBonus }))
        previousBonus = targetValue - currentValue
    end

    item:markAltered(Tags.STAT_ABILITY_DEBUFF_DURATION, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_POISON_DAMAGE_TOTAL, Tags.STAT_UPGRADED)
    if item.stats:hasKey(Tags.STAT_ABILITY_BUFF_DURATION) then
        item:markAltered(Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_UPGRADED)
    end

end
DISEASE.canRoll = function(itemDef)
    return itemDef.statsBase:get(Tags.STAT_POISON_DAMAGE_TOTAL, 0) > 0
end
local AFFLICTION = ModifierDef:new("Affliction")
AFFLICTION:setToStatsBase({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
AFFLICTION.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_DEBUFF_DURATION, Tags.STAT_UPGRADED)
end
AFFLICTION.canRoll = function(itemDef)
    local ability = itemDef.ability
    return ability:hasTag(Tags.ABILITY_TAG_DEBUFF_EXTENDABLE) or ability:hasTag(Tags.ABILITY_TAG_DEBUFF_COLD)
end
local INTELLIGENCE = ModifierDef:new("Intelligence")
local INTELLIGENCE_FORMAT = "Regenerate %s extra mana every turn."
INTELLIGENCE:setToStatsBase({ [Tags.STAT_FLAT_MANA_REGEN] = 1 })
INTELLIGENCE.statLine = function(item)
    return textStatFormat(INTELLIGENCE_FORMAT, item, Tags.STAT_FLAT_MANA_REGEN)
end
INTELLIGENCE.canRoll = function(itemDef)
    if itemDef.slot == Tags.SLOT_WEAPON then
        return itemDef.statsBase:get(Tags.STAT_COOLDOWN_REDUCTION, 0) > 0
    end

    return itemDef.slot ~= Tags.SLOT_GLOVES
end
local FORGING = ModifierDef:new("Forging")
FORGING:setToStatsBase({ [Tags.STAT_UPGRADE_DISCOUNT] = 5 })
local FORGING_FORMAT = "Costs %s less scrap to upgrade."
FORGING.statLine = function(item)
    return textStatFormat(FORGING_FORMAT, item, Tags.STAT_UPGRADE_DISCOUNT)
end
FORGING:addPowerSpike({ [Tags.STAT_UPGRADE_DISCOUNT] = 1 })
FORGING:addPowerSpike({ [Tags.STAT_UPGRADE_DISCOUNT] = 1 })
FORGING:addPowerSpike({ [Tags.STAT_UPGRADE_DISCOUNT] = 1 })
FORGING:addPowerSpike({ [Tags.STAT_UPGRADE_DISCOUNT] = 1 })
FORGING:addPowerSpike({ [Tags.STAT_UPGRADE_DISCOUNT] = 1 })
FORGING:addPowerSpike({ [Tags.STAT_UPGRADE_DISCOUNT] = 1 })
FORGING:addPowerSpike({ [Tags.STAT_UPGRADE_DISCOUNT] = 1 })
FORGING:addPowerSpike({ [Tags.STAT_UPGRADE_DISCOUNT] = 1 })
FORGING:addPowerSpike({ [Tags.STAT_UPGRADE_DISCOUNT] = 1 })
FORGING:addPowerSpike({  })
FORGING.canRoll = alwaysTrue
return { RESILIENCE = RESILIENCE, SPIRIT = SPIRIT, SKILL = SKILL, PROWESS = PROWESS, SAVAGERY = SAVAGERY, ACCURACY = ACCURACY, COMBAT = COMBAT, WIZARDRY = WIZARDRY, JOURNEY = JOURNEY, HORIZON = HORIZON, MARKSMAN = MARKSMAN, KINGS = KINGS, DISEASE = DISEASE, AFFLICTION = AFFLICTION, LONGEVITY = LONGEVITY, IGNITION = IGNITION, MOMENTUM = MOMENTUM, INTELLIGENCE = INTELLIGENCE, FORGING = FORGING }

