local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local Common = require("common")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.amulet_def"):new("Firebrand's Amulet")
ITEM.className = "Firebrand"
ITEM.classSprite = Vector:new(18, 1)
ITEM.icon = Vector:new(18, 17)
local MAX_VALUE = 100
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1, [Tags.STAT_ABILITY_VALUE] = 1, [Tags.STAT_ABILITY_DAMAGE_BASE] = 8.9, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.67) })
local FORMAT_1 = "Immune to {C:KEYWORD}Burn health loss."
local FORMAT_2 = "Deal %s bonus damage to enemies stepping on {C:KEYWORD}Burn spaces."
ITEM.getPassiveDescription = function(item)
    return Array:new(textStatFormat(FORMAT_1, item), textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_DAMAGE_MIN))
end
ITEM.postCreate = function(item)
    item:markAltered(Tags.STAT_ABILITY_VALUE, Tags.STAT_DOWNGRADED)
end
ITEM.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositiveDirect() then
        if entity.body:hasSteppableExclusivity(hit.targetPosition, Tags.STEP_EXCLUSIVE_ENGULF) then
            hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN)
            hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX)
            hit:increaseBonusState()
        end

    end

end
ITEM.decorateIncomingHit = function(entity, hit, abilityStats)
    if hit.damageType == Tags.DAMAGE_TYPE_BURN then
        hit:clear()
        hit.sound = false
    end

end
local LEGENDARY = ITEM:createLegendary("Herald of the Apocalypse")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_FIRE
return ITEM

