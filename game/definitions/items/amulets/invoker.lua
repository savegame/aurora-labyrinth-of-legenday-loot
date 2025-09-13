local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local TRIGGERS = require("actions.triggers")
local ITEM = require("structures.amulet_def"):new("Invoker's Amulet")
ITEM.className = "Invoker"
ITEM.classSprite = Vector:new(8, 2)
ITEM.icon = Vector:new(15, 15)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_VALUE] = 5, [Tags.STAT_ABILITY_DENOMINATOR] = 8 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 2 })
local FORMAT_1 = "Dealing {C:KEYWORD}Non-Attack damage to enemies restores mana equal to %s of the damage dealt."
local FORMAT_2 = "You have {C:KEYWORD}Resist %s while you are " .. "{C:KEYWORD}Sustaining or {C:KEYWORD}Focusing."
ITEM.getPassiveDescription = function(item)
    return Array:new(textStatFormat(FORMAT_1, item, Tags.STAT_ABILITY_DENOMINATOR), textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_VALUE))
end
local TRIGGER = class(TRIGGERS.ON_DAMAGE)
function TRIGGER:isEnabled()
    if self.hit:isDamagePositiveDirect() and self.hit.damageType ~= Tags.DAMAGE_TYPE_MELEE then
        if self.hit.targetEntity and self.hit.targetEntity:hasComponent("agent") then
            return true
        end

    end

    return false
end

function TRIGGER:process(currentEvent)
    local denominator = self.abilityStats:get(Tags.STAT_ABILITY_DENOMINATOR)
    self.entity.mana:restore(self:getLogicRNG():resolveInteger(self.hit.minDamage / denominator), self.entity.body:getPosition())
    return currentEvent
end

ITEM.decorateIncomingHit = function(entity, hit, abilityStats)
    if entity.equipment:getSustainedSlot() and hit:isDamagePositiveDirect() then
        local reduction = abilityStats:get(Tags.STAT_ABILITY_VALUE)
        hit:reduceDamage(abilityStats:get(Tags.STAT_ABILITY_VALUE))
        hit:decreaseBonusState()
    end

end
ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("The Final Judgement")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_HOLY
return ITEM

