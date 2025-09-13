local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Hash = require("utils.classes.hash")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local COLORS = require("draw.colors")
local ActionUtils = require("actions.utils")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTIONS_FRAGMENT = require("actions.fragment")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Sharp Spear")
local ABILITY = require("structures.ability_def"):new("Penetrating Throw")
ABILITY:addTag(Tags.ABILITY_TAG_PRODUCES_PROJECTILES)
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(7, 17)
ITEM.attackClass = ATTACK_WEAPON.STAB_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 16.0, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.85), [Tags.STAT_REACH] = 1, [Tags.STAT_VIRTUAL_RATIO] = 0.21, [Tags.STAT_ABILITY_POWER] = 2.91, [Tags.STAT_ABILITY_DAMAGE_BASE] = 23, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.65), [Tags.STAT_SECONDARY_DAMAGE_BASE] = 8, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.5), [Tags.STAT_ABILITY_PROJECTILE_SPEED] = CONSTANTS.PLAYER_PROJECTILE_SPEED })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Throw a {C:KEYWORD}Projectile that deals %s damage. It pierces through all " .. "targets, and whenever it does, its damage increases by %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_SECONDARY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(8, 9)
ABILITY.iconColor = COLORS.STANDARD_STEEL
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local target = entity.body:getPosition()
    local speed = abilityStats:get(Tags.STAT_ABILITY_PROJECTILE_SPEED)
    while target and entity.body:canBePassable(target) do
        target = ActionUtils.indicateProjectile(entity, direction, abilityStats, castingGuide, target, speed)
        speed = CONSTANTS.PRODUCED_PROJECTILE_SPEED
    end

end
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonFrontCantBePassable
local ACTION = class(ACTIONS_FRAGMENT.THROW)
ABILITY.actionClass = ACTION
function ACTION:process(currentEvent)
    return ACTION:super(self, "process", currentEvent):chainEvent(function(_, anchor)
        self.entity.projectilespawner:spawnSpecial(anchor, "sharp_spear", self.direction, self.abilityStats)
    end)
end

local LEGENDARY = ITEM:createLegendary("Spear of the Great Hunt")
LEGENDARY.modifyItem = function(item)
    local minStats = Array:new(Tags.STAT_ATTACK_DAMAGE_MIN, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_SECONDARY_DAMAGE_MIN)
    local maxStats = Array:new(Tags.STAT_ATTACK_DAMAGE_MAX, Tags.STAT_ABILITY_DAMAGE_MAX, Tags.STAT_SECONDARY_DAMAGE_MAX)
    item:multiplyStatAndGrowth(Tags.STAT_ATTACK_DAMAGE_MAX, 45 / 55)
    for i = 1, minStats:size() do
        local minStat, maxStat = minStats[i], maxStats[i]
        item:markAltered(minStat, Tags.STAT_UPGRADED)
        item.stats:set(minStat, item.stats:get(maxStat))
        for j = 1, CONSTANTS.ITEM_UPGRADE_LEVELS do
            local growthForLevel = item:getGrowthForLevel(j)
            local growthMin = growthForLevel:get(minStat, 0)
            if not item.extraGrowth:hasKey(j) then
                item.extraGrowth:set(j, Hash:new())
            end

            local extraGrowth = item.extraGrowth:get(j)
            local growthMax = growthForLevel:get(maxStat, 0) + extraGrowth:get(maxStat, 0)
            extraGrowth:set(minStat, growthMax - growthMin)
        end

    end

end
return ITEM

