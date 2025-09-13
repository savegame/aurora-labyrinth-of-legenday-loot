local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTIONS_FRAGMENT = require("actions.fragment")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Arcane Staff")
local ABILITY = require("structures.ability_def"):new("Arcane Missile")
ABILITY:addTag(Tags.ABILITY_TAG_PRODUCES_PROJECTILES)
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(10, 15)
ITEM.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 17, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.25), [Tags.STAT_COOLDOWN_REDUCTION] = 2, [Tags.STAT_VIRTUAL_RATIO] = 0.95, [Tags.STAT_ABILITY_POWER] = 3.21 * 0.75, [Tags.STAT_ABILITY_DAMAGE_BASE] = 20.63 * 1.25, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.16), [Tags.STAT_ABILITY_PROJECTILE_SPEED] = CONSTANTS.PLAYER_PROJECTILE_SPEED, [Tags.STAT_ABILITY_COUNT] = 3 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COUNT] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Fire a {C:KEYWORD}Projectile that deals %s damage. The {C:KEYWORD}Projectile " .. "splits into %s more projectiles upon collision, dealing the same damage."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_COUNT)
end
local function getSpawnDirections(direction, abilityStats)
    local result = Array:new(cwDirection(direction), ccwDirection(direction))
    local count = abilityStats:get(Tags.STAT_ABILITY_COUNT)
    if count >= 3 then
        result:push(direction)
    end

    if count >= 5 then
        result:push(cwDirection(direction, 1))
        result:push(ccwDirection(direction, 1))
    end

    return result
end

ABILITY.icon = Vector:new(8, 7)
ABILITY.iconColor = COLORS.STANDARD_PSYCHIC
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonFrontCantBePassable
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local target = ActionUtils.indicateProjectile(entity, direction, abilityStats, castingGuide)
    if target then
        for spawnDirection in (getSpawnDirections(direction, abilityStats))() do
            ActionUtils.indicateProjectile(entity, spawnDirection, abilityStats, castingGuide, target, CONSTANTS.PRODUCED_PROJECTILE_SPEED)
        end

    end

end
local ACTION = class(ACTIONS_FRAGMENT.CAST_PROJECTILE)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.projectilePrefab = "arcane_staff"
    self.color = ABILITY.iconColor
end

local MIN_COOLDOWN = CONSTANTS.MIN_COOLDOWN_ON_REDUCE
local LEGENDARY = ITEM:createLegendary("Staff of Chronos")
LEGENDARY.statLine = ("Reduce all ability cooldowns by half (min. {C:NUMBER}%d{C:BASE})."):format(MIN_COOLDOWN)
LEGENDARY.modifyItem = function(item)
    item.stats:deleteKey(Tags.STAT_COOLDOWN_REDUCTION)
end
LEGENDARY:setAbilityStatBonus(Tags.STAT_ABILITY_COOLDOWN, function(item, baseValue, thisAbilityStats, entity, currentValue)
    if entity.equipment:getSlotsWithAbilities():contains(item.stats:get(Tags.STAT_SLOT)) then
        if currentValue > MIN_COOLDOWN then
            local value = -min(currentValue - MIN_COOLDOWN, floor(baseValue / 2))
            return value
        end

    end

    return 0
end)
return ITEM

