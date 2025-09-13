local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local COLORS = require("draw.colors")
local ITEM = require("structures.item_def"):new("Veteran Helm")
local ABILITY = require("structures.ability_def"):new("Mastery")
ABILITY:addTag(Tags.ABILITY_TAG_DYNAMIC_COOLDOWN)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(8, 20)
ITEM.extraCostLine = "Cooldown: {C:NUMBER}X"
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 34, [Tags.STAT_MAX_MANA] = 6, [Tags.STAT_ABILITY_MANA_COST] = 60, [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_COST] = -4 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_COST] = -4 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_COST] = -4 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_COST] = -4 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_COST] = -4 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_COST] = -4 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_COST] = -4 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_COST] = -4 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_COST] = -4 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_COST] = -4 })
local MINIMUM_COOLDOWN = 3
local FORMAT = ("Reset your weapon ability's cooldown and transfer it to this ability (min. {C:NUMBER}%d{C:BASE}). {C:KEYWORD}Quick."):format(MINIMUM_COOLDOWN)
ABILITY.getDescription = function(item)
    return FORMAT
end
ABILITY.icon = Vector:new(7, 3)
ABILITY.iconColor = COLORS.STANDARD_STEEL
ABILITY.directions = false
ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    if entity.equipment:getCooldownFor(Tags.SLOT_WEAPON) <= 0 then
        return "Weapon ability not on cooldown"
    else
        return false
    end

end
ABILITY.indicate = ActionUtils.indicateSelf
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
function ACTION:process(currentEvent)
    local enchantAction = self.entity.actor:create(ACTIONS_FRAGMENT.ENCHANT, self.direction)
    enchantAction.color = ABILITY.iconColor
    return enchantAction:parallelChainEvent(currentEvent):chainEvent(function()
        local equipment = self.entity.equipment
        local minValue = MINIMUM_COOLDOWN + self.entity.stats:get(Tags.STAT_COOLDOWN_REDUCTION)
        equipment:setTempStatBonus(self.abilityStats:get(Tags.STAT_SLOT), Tags.STAT_ABILITY_COOLDOWN, max(minValue, equipment:getCooldownFor(Tags.SLOT_WEAPON)))
        equipment:resetCooldown(Tags.SLOT_WEAPON)
    end)
end

local LEGENDARY = ITEM:createLegendary("Helm of the Ascendant")
LEGENDARY.statLine = "Your weapon ability costs half mana."
LEGENDARY:setToStatsBase({  })
LEGENDARY.modifyItem = function(item)
end
LEGENDARY:setAbilityStatBonus(Tags.STAT_ABILITY_MANA_COST, function(item, baseValue, thisAbilityStats)
    if item.stats:get(Tags.STAT_SLOT) == Tags.SLOT_WEAPON then
        return -ceil(baseValue / 2)
    end

    return 0
end)
return ITEM

