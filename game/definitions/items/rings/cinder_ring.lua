local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ACTION_CONSTANTS = require("actions.constants")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Cinder Ring")
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(20, 20)
ITEM:setToStatsBase({ [Tags.STAT_SECONDARY_DAMAGE_BASE] = 6.4, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.75), [Tags.STAT_ABILITY_COOLDOWN] = 8, [Tags.STAT_ABILITY_BURN_DURATION] = 3 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT_NORMAL = "Your next {C:KEYWORD}Attack against an enemy will {C:KEYWORD}Burn."
local FORMAT_LEGENDARY = "{B:STAT_LINE}Your {C:KEYWORD}Attacks against enemies will {C:KEYWORD}Burn.{B:NORMAL}"
local FORMAT_END = " {FORCE_NEWLINE} %s, %s health lost per turn."
ITEM.getPassiveDescription = function(item)
    local description
    if item.stats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        description = FORMAT_LEGENDARY
    else
        description = FORMAT_NORMAL
    end

    return description .. textStatFormat(FORMAT_END, item, Tags.STAT_ABILITY_BURN_DURATION, Tags.STAT_SECONDARY_DAMAGE_MIN)
end
ITEM.decorateOutgoingHit = function(entity, hit, abilityStats)
    local slot = abilityStats:get(Tags.STAT_SLOT)
    if abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 or entity.equipment:isReady(slot) then
        if hit:isDamagePositive() and hit.damageType == Tags.DAMAGE_TYPE_MELEE and hit.targetEntity and hit.targetEntity:hasComponent("agent") then
            Common.playSFX("BURN_DAMAGE")
            hit:setSpawnFireFromSecondary(abilityStats)
            if abilityStats:get(Tags.STAT_LEGENDARY, 0) == 0 then
                entity.equipment:setOnCooldown(slot, 1)
                entity.equipment:recordCast(slot)
            end

        end

    end

end
local LEGENDARY = ITEM:createLegendary("Ring of the First Star")
LEGENDARY.strokeColor = COLORS.STANDARD_FIRE
LEGENDARY:setToStatsBase({ [Tags.STAT_SECONDARY_DAMAGE_BASE] = ITEM.statsBase:get(Tags.STAT_SECONDARY_DAMAGE_BASE) / 4, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.75) })
LEGENDARY.modifyItem = function(item)
    item.stats:deleteKey(Tags.STAT_ABILITY_COOLDOWN)
    for i = 1, CONSTANTS.ITEM_UPGRADE_LEVELS do
        local growthForLevel = item:getGrowthForLevel(i)
        growthForLevel:deleteKeyIfExists(Tags.STAT_ABILITY_COOLDOWN)
    end

    item:markAltered(Tags.STAT_SECONDARY_DAMAGE_MIN, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_SECONDARY_DAMAGE_MAX, Tags.STAT_UPGRADED)
end
return ITEM

