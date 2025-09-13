local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.amulet_def"):new("Hunter's Amulet")
ITEM.className = "Hunter"
ITEM.classSprite = Vector:new(20, 2)
ITEM.icon = Vector:new(15, 18)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_PROJECTILE_SPEED] = 2, [Tags.STAT_ABILITY_DAMAGE_BASE] = 10, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = 0 })
local FORMAT_1 = "{C:NUMBER}+%s {C:KEYWORD}Projectile speed."
local FORMAT_2 = "Increase {C:KEYWORD}Projectile damage by %s if there are no enemies adjacent to you."
ITEM.getPassiveDescription = function(item)
    return Array:new(textStatFormat(FORMAT_1, item, Tags.STAT_ABILITY_PROJECTILE_SPEED), textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_DAMAGE_MIN))
end
ITEM:setAbilityStatBonus(Tags.STAT_ABILITY_PROJECTILE_SPEED, function(item, baseValue, thisAbilityStats)
    return thisAbilityStats:get(Tags.STAT_ABILITY_PROJECTILE_SPEED)
end)
ITEM.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositive() and hit.damageType == Tags.DAMAGE_TYPE_RANGED then
        local body = entity.body
        for direction in DIRECTIONS_AA() do
            if body:hasEntityWithAgent(body:getPosition() + Vector[direction]) then
                return 
            end

        end

        hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN)
        hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX)
        hit:increaseBonusState()
    end

end
local LEGENDARY = ITEM:createLegendary("Eyes of Omniscience")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_WIND
return ITEM

