local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local COLORS = require("draw.colors")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Maven Ring")
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(19, 21)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_COOLDOWN] = 50 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -2 })
local FORMAT = "Your next ability costs {C:NUMBER}0 mana."
ITEM.getPassiveDescription = function(item)
    return FORMAT
end
ITEM:setAbilityStatBonus(Tags.STAT_ABILITY_MANA_COST, function(item, baseValue, thisAbilityStats, entity, currentValue)
    if entity.equipment:isReady(thisAbilityStats:get(Tags.STAT_SLOT)) then
        return -currentValue
    else
        return 0
    end

end)
local TRIGGER = class(TRIGGERS.POST_CAST)
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = -1
end

function TRIGGER:isEnabled()
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        return true
    end

    return self.entity.equipment:isReady(self:getSlot())
end

function TRIGGER:process(currentEvent)
    local item = self.entity.equipment:get(self.triggeringSlot)
        if self.entity.equipment:isReady(self:getSlot()) then
        if item.stats:get(Tags.STAT_ABILITY_MANA_COST, 0) > 0 then
            self.entity.equipment:setOnCooldown(self:getSlot(), 1)
            self.entity.equipment:recordCast(self:getSlot())
        end

    elseif self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        self.entity.equipment:reduceCooldown(self:getSlot(), self.abilityStats:get(Tags.STAT_MODIFIER_VALUE))
    end

    return currentEvent
end

ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("Mark of the Prodigy")
LEGENDARY.strokeColor = COLORS.STANDARD_GHOST
local LEGENDARY_EXTRA_LINE = "Whenever you cast an ability directly, reduce this ring's " .. "cooldown by %s."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 3 })
LEGENDARY.passiveExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_VALUE)
end
return ITEM

