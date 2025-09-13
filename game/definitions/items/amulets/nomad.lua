local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local TRIGGERS = require("actions.triggers")
local CONSTANTS = require("logic.constants")
local ITEM = require("structures.amulet_def"):new("Nomad's Amulet")
ITEM.className = "Nomad"
ITEM.classSprite = Vector:new(12, 2)
ITEM.icon = Vector:new(14, 19)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_VALUE] = 2, [Tags.STAT_ABILITY_COUNT] = 3 })
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
local MIN_COOLDOWN = CONSTANTS.MIN_COOLDOWN_ON_REDUCE
local FORMAT_1 = "{C:NUMBER}-%s cooldown to your boots ability {FORCE_NEWLINE} " .. ("(min. {C:NUMBER}%d{C:BASE})."):format(MIN_COOLDOWN)
local FORMAT_2 = "{C:KEYWORD}Resist %s if you were at a different position last turn."
ITEM.getPassiveDescription = function(item)
    return Array:new(textStatFormat(FORMAT_1, item, Tags.STAT_ABILITY_COUNT), textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_VALUE))
end
ITEM:setAbilityStatBonus(Tags.STAT_ABILITY_COOLDOWN, function(item, baseValue, thisAbilityStats, entity, currentValue)
    if item.stats:get(Tags.STAT_SLOT) == Tags.SLOT_BOOTS then
        if currentValue > MIN_COOLDOWN then
            local value = -min(currentValue - MIN_COOLDOWN, thisAbilityStats:get(Tags.STAT_ABILITY_COUNT))
            return value
        end

    end

    return 0
end)
local SAVE_POSITION = class(TRIGGERS.START_OF_TURN)
function SAVE_POSITION:process(currentEvent)
    local entity = self.entity
    local slot = self.abilityStats:get(Tags.STAT_SLOT)
    local position = entity.body:getPosition()
    entity.equipment:setTempStatBonus(slot, Tags.STAT_POSITION_X, position.x)
    entity.equipment:setTempStatBonus(slot, Tags.STAT_POSITION_Y, position.y)
    return currentEvent
end

ITEM.decorateIncomingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositiveDirect() then
        local slot = abilityStats:get(Tags.STAT_SLOT)
        local x = entity.equipment:getTempStatBonus(slot, Tags.STAT_POSITION_X)
        local y = entity.equipment:getTempStatBonus(slot, Tags.STAT_POSITION_Y)
        if x ~= 0 and y ~= 0 then
            local position = entity.body:getPosition()
            local distance = abs(position.x - x) + abs(position.y - y)
            if distance > 0 then
                hit:reduceDamage(abilityStats:get(Tags.STAT_ABILITY_VALUE))
                hit:decreaseBonusState()
            end

        end

    end

end
ITEM.triggers:push(SAVE_POSITION)
local LEGENDARY = ITEM:createLegendary("Fateweaver")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_WIND
return ITEM

