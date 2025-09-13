local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Quicksilver Ring")
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(9, 4)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_COOLDOWN] = 30 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Your next step is {C:KEYWORD}Quick."
ITEM.getPassiveDescription = function(item)
    return FORMAT
end
ITEM.decorateBasicMove = function(entity, action, abilityStats)
    if not action:isQuick() then
        local slot = abilityStats:get(Tags.STAT_SLOT)
        if entity.equipment:isReady(slot) then
            action:setToQuick()
            entity.equipment:setOnCooldown(slot)
            entity.equipment:recordCast(slot)
        end

    end

    if abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 and not action:isQuick() then
        entity.equipment:reduceCooldownSilent(ITEM.slot, abilityStats:get(Tags.STAT_MODIFIER_VALUE))
    end

end
local LEGENDARY = ITEM:createLegendary("Ring of the Silver Dancer")
local LEGENDARY_EXTRA_LINE = "Whenever you take a normal step, reduce this ring's cooldown " .. "by %s."
LEGENDARY.strokeColor = COLORS.STANDARD_STEEL
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY.passiveExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_VALUE)
end
return ITEM

