local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local textStatFormat = require("text.stat_format")
local Common = require("common")
local ITEM = require("structures.item_def"):new("Ritual Ring")
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(19, 17)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 9.2, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.53), [Tags.STAT_ABILITY_MANA_COST] = 15 })
local FORMAT = "Whenever you deal damage to enemies, consume %s mana " .. "and deal %s bonus damage. "
ITEM.getPassiveDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_MANA_COST, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ITEM.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositiveDirect() and ActionUtils.isAliveAgent(hit.targetEntity) then
        local cost = abilityStats:get(Tags.STAT_ABILITY_MANA_COST)
        if entity.mana:getCurrent() >= cost then
            entity.mana:consume(cost)
            hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN)
            hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX)
            hit:increaseBonusState()
        end

    end

end
local LEGENDARY = ITEM:createLegendary("Master of Ceremonies")
local LEGENDARY_EXTRA_LINE = "At the end of your turn, if you have less than %s mana, restore " .. "%s mana."
LEGENDARY.strokeColor = COLORS.STANDARD_RAGE
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 12, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = 0 })
LEGENDARY.passiveExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_ABILITY_MANA_COST, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
local LEGENDARY_TRIGGER = class(TRIGGERS.END_OF_TURN)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
end

function LEGENDARY_TRIGGER:isEnabled()
    return self.entity.mana:getCurrent() < self.abilityStats:get(Tags.STAT_ABILITY_MANA_COST)
end

function LEGENDARY_TRIGGER:process(currentEvent)
    local hit = self.entity.hitter:createHit()
    local value = self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
    hit:setHealing(value, value, self.abilityStats)
    hit.affectsMana = true
    hit:applyToEntity(currentEvent, self.entity)
    return currentEvent
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

