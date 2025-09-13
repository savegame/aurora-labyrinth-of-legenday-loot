local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local TRIGGERS = require("actions.triggers")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Champion Ring")
ITEM:setToMediumComplexity()
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(18, 20)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_VALUE] = 2 })
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
local FORMAT = "{C:KEYWORD}Resist %s against {C:KEYWORD}Elite enemies."
ITEM.getPassiveDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_VALUE)
end
local MIN_DAMAGE = CONSTANTS.MIN_DAMAGE_ON_REDUCE
ITEM.decorateIncomingHit = function(entity, hit, abilityStats)
    local sourceEntity = hit.sourceEntity
    if Common.isElite(sourceEntity) and hit:isDamagePositiveDirect() then
        if hit.minDamage > MIN_DAMAGE or hit.maxDamage > MIN_DAMAGE then
            hit:reduceDamage(abilityStats:get(Tags.STAT_ABILITY_VALUE))
            hit:decreaseBonusState()
        end

    end

end
local LEGENDARY = ITEM:createLegendary("Ring of the Dragonslayer")
LEGENDARY.strokeColor = COLORS.STANDARD_FIRE
local LEGENDARY_EXTRA_LINE = "Whenever an {C:KEYWORD}Elite enemy hits you, deal %s damage back."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 7, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.7) })
LEGENDARY.passiveExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
local LEGENDARY_TRIGGER = class(TRIGGERS.POST_HIT)
function LEGENDARY_TRIGGER:isEnabled()
    return Common.isElite(self.hit.sourceEntity)
end

function LEGENDARY_TRIGGER:process(currentEvent)
    return currentEvent:chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit()
        hit.targetEntity = self.hit.sourceEntity
        hit:setDamageFromModifierStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        hit:applyToEntity(anchor, self.hit.sourceEntity)
    end)
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

