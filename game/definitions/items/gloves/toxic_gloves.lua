local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Toxic Gloves")
local ABILITY = require("structures.ability_def"):new("Toxic Throw")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(8, 19)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 10, [Tags.STAT_MAX_MANA] = 30, [Tags.STAT_ABILITY_POWER] = 2.83, [Tags.STAT_ABILITY_DAMAGE_BASE] = 16, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.18), [Tags.STAT_ABILITY_PROJECTILE_SPEED] = CONSTANTS.PLAYER_PROJECTILE_SPEED, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 4, [Tags.STAT_POISON_DAMAGE_BASE] = 4.1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
local FORMAT = "Throw a {C:KEYWORD}Projectile that deals %s damage " .. "and {C:KEYWORD}Poisons the target, making it lose %s health over %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_POISON_DAMAGE_TOTAL, Tags.STAT_ABILITY_DEBUFF_DURATION)
end
ABILITY.icon = Vector:new(1, 8)
ABILITY.iconColor = COLORS.STANDARD_POISON
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonFrontCantBePassable
ABILITY.indicate = ActionUtils.indicateProjectile
local ON_HIT = class("actions.hit")
function ON_HIT:parallelResolve(anchor)
    ON_HIT:super(self, "parallelResolve", anchor)
    local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
    local poisonDamage = self.abilityStats:get(Tags.STAT_POISON_DAMAGE_TOTAL)
    self.hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_RANGED, self.abilityStats)
    self.hit:addBuff(BUFFS:get("POISON"):new(duration, self.entity, poisonDamage))
end

local ACTION = class(ACTIONS_FRAGMENT.THROW)
ABILITY.actionClass = ACTION
function ACTION:process(currentEvent)
    return ACTION:super(self, "process", currentEvent):chainEvent(function(_, anchor)
        self.entity.projectilespawner:spawnSpecial(anchor, "toxic_gloves", self.direction, self.abilityStats)
    end)
end

local LEGENDARY = ITEM:createLegendary("Assassin's Catalyst")
local LEGENDARY_STAT_LINE = "Your {C:KEYWORD}Poisons last %s less, but have the same amount of " .. "health loss."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DEBUFF_DURATION] = 2 })
LEGENDARY:addPowerSpike({  })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_DEBUFF_DURATION] = 1 })
LEGENDARY:addPowerSpike({  })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_DEBUFF_DURATION)
end
LEGENDARY:setAbilityStatBonus(Tags.STAT_ABILITY_DEBUFF_DURATION, function(item, baseValue, thisAbilityStats, entity, currentValue)
    if item.stats:get(Tags.STAT_POISON_DAMAGE_TOTAL, 0) > 0 and currentValue > 1 then
        local reduction = thisAbilityStats:get(Tags.STAT_MODIFIER_DEBUFF_DURATION)
        return max(-reduction, -currentValue + 1)
    else
        return 0
    end

end)
return ITEM

