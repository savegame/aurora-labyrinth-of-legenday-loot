local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Force Gloves")
local ABILITY = require("structures.ability_def"):new("Force Bolt")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(8, 18)
ITEM:setToStatsBase({ [Tags.STAT_MAX_MANA] = 40, [Tags.STAT_ABILITY_POWER] = 2.44, [Tags.STAT_ABILITY_DAMAGE_BASE] = 21.8, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.13), [Tags.STAT_ABILITY_PROJECTILE_SPEED] = CONSTANTS.PLAYER_PROJECTILE_SPEED, [Tags.STAT_ABILITY_RANGE] = 1, [Tags.STAT_KNOCKBACK_DAMAGE_BASE] = CONSTANTS.KNOCKBACK_DAMAGE_BASE, [Tags.STAT_KNOCKBACK_DAMAGE_VARIANCE] = CONSTANTS.KNOCKBACK_DAMAGE_VARIANCE })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT_NORMAL = "Fire a {C:KEYWORD}Projectile that"
local FORMAT_LEGENDARY = "Fire %s {C:KEYWORD}Projectiles in %s directions. " .. "Each {C:KEYWORD}Projectile"
local FORMAT_END = " deals %s damage and {C:KEYWORD}Pushes the target back %s."
ABILITY.getDescription = function(item)
    if item.stats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        return textStatFormat(FORMAT_LEGENDARY .. FORMAT_END, item, Tags.STAT_ABILITY_COUNT, Tags.STAT_ABILITY_COUNT, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_RANGE)
    else
        return textStatFormat(FORMAT_NORMAL .. FORMAT_END, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_RANGE)
    end

end
ABILITY.icon = Vector:new(10, 4)
ABILITY.iconColor = COLORS.STANDARD_PSYCHIC
ABILITY.directions = function(entity, abilityStats)
    if abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        return false
    else
        return DIRECTIONS_AA
    end

end
ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    if abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        return false
    else
        ActionUtils.getInvalidReasonFrontCantBePassable(entity, direction, abilityStats)
    end

end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    ActionUtils.indicateProjectile(entity, direction, abilityStats, castingGuide)
    if abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        for otherDirection in DIRECTIONS_AA() do
            if otherDirection ~= direction then
                ActionUtils.indicateProjectile(entity, otherDirection, abilityStats, castingGuide)
            end

        end

    end

end
local ACTION = class(ACTIONS_FRAGMENT.CAST_PROJECTILE)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.projectilePrefab = "force_gloves"
    self.color = ABILITY.iconColor
end

function ACTION:process(currentEvent)
    local currentEvent = ACTION:super(self, "process", currentEvent)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        currentEvent = currentEvent:chainEvent(function(_, anchor)
            for direction in DIRECTIONS_AA() do
                if direction ~= self.direction then
                    self.entity.projectilespawner:spawnSpecial(anchor, self.projectilePrefab, direction, self.abilityStats)
                end

            end

        end)
    end

    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Impetus")
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_COUNT] = 4 })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_COUNT, Tags.STAT_UPGRADED)
end
return ITEM

