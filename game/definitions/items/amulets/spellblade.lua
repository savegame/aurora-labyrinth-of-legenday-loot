local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local COLORS = require("draw.colors")
local TRIGGERS = require("actions.triggers")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.amulet_def"):new("Spellblade's Amulet")
ITEM.className = "Spellblade"
ITEM.classSprite = Vector:new(8, 3)
ITEM.icon = Vector:new(21, 19)
ITEM:setToStatsBase({ [Tags.STAT_MAX_MANA] = 100, [Tags.STAT_MANA_REGEN] = -CONSTANTS.MANA_PER_TURN * 2, [Tags.STAT_ABILITY_DENOMINATOR] = 8 })
ITEM:setGrowthMultiplier({ [Tags.STAT_MAX_MANA] = 4 / 3 })
local FORMAT_1 = "Lose mana every turn instead of regenerating. Your {C:KEYWORD}Attacks against enemies restore %s of your max mana."
local FORMAT_2 = "Increase max mana by {C:NUMBER}%s."
ITEM.getPassiveDescription = function(item)
    return Array:new(textStatFormat(FORMAT_1, item, Tags.STAT_ABILITY_DENOMINATOR), FORMAT_2:format(item.stats:get(Tags.STAT_MAX_MANA)))
end
ITEM.onEquip = function(entity, item, fromLoad)
    if not fromLoad then
        entity.mana:setRatio(0)
    end

end
local TRIGGER = class(TRIGGERS.ON_DAMAGE)
function TRIGGER:process(currentEvent)
    return currentEvent:chainEvent(function(_, anchor)
        local denominator = self.abilityStats:get(Tags.STAT_ABILITY_DENOMINATOR)
        local value = round(self.entity.mana:getMax() / denominator)
        self.entity.mana:restoreSilent(value)
        self.entity.mana.preventNextTick = true
    end)
end

function TRIGGER:isEnabled()
    return (self.hit.damageType == Tags.DAMAGE_TYPE_MELEE and self.hit:isDamagePositive() and self.hit:isTargetAgent())
end

ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("Essence of the Arcane")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_GHOST
return ITEM

