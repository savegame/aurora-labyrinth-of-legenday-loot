local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local Common = require("common")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.amulet_def"):new("Templar's Amulet")
ITEM.className = "Templar"
ITEM.classSprite = Vector:new(10, 3)
ITEM.icon = Vector:new(20, 15)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_VALUE] = 1, [Tags.STAT_ABILITY_DAMAGE_BASE] = 5, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.4) })
local FORMAT_1 = "{C:NUMBER}+1 turn duration to all {C:KEYWORD}Buffs " .. "that last more than {C:NUMBER}1 turn."
local FORMAT_2 = "Your {C:KEYWORD}Attacks deal %s bonus damage for every " .. "active {C:KEYWORD}Buff."
ITEM.getPassiveDescription = function(item)
    return Array:new(textStatFormat(FORMAT_1, item, Tags.STAT_ABILITY_VALUE), textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_DAMAGE_MIN))
end
ITEM.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit.damageType == Tags.DAMAGE_TYPE_MELEE then
        local SLOTS = require("definitions.items").SLOTS_WITH_ABILITIES
        local boosted = false
        for slot in SLOTS() do
            if entity.equipment:isSlotActive(slot) then
                local stats = entity.equipment:getSlotStats(slot)
                if stats:get(Tags.STAT_ABILITY_BUFF_DURATION, 0) >= 1 and stats:get(Tags.STAT_ABILITY_SUSTAIN_MODE, 0) == 0 then
                    hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN)
                    hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX)
                    boosted = true
                end

            end

        end

        if boosted then
            hit:increaseBonusState()
        end

    end

end
ITEM:setAbilityStatBonus(Tags.STAT_ABILITY_BUFF_DURATION, function(item, baseValue, thisAbilityStats)
    if baseValue > 1 and item.stats:get(Tags.STAT_ABILITY_SUSTAIN_MODE, 0) == 0 then
        return 1
    end

    return 0
end)
local LEGENDARY = ITEM:createLegendary("Spark of Divinity")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_HOLY
return ITEM

