local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTIONS_FRAGMENT = require("actions.fragment")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Frost Staff")
local ABILITY = require("structures.ability_def"):new("Frost Bolt")
ABILITY:addTag(Tags.ABILITY_TAG_DEBUFF_COLD)
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(13, 3)
ITEM.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 17, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.25), [Tags.STAT_COOLDOWN_REDUCTION] = 2, [Tags.STAT_VIRTUAL_RATIO] = 1, [Tags.STAT_ABILITY_POWER] = 3.27 * 0.75, [Tags.STAT_ABILITY_DAMAGE_BASE] = 24.18 * 1.25, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.01), [Tags.STAT_SECONDARY_DAMAGE_BASE] = 12.08 * 1.25, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.01), [Tags.STAT_ABILITY_PROJECTILE_SPEED] = CONSTANTS.PLAYER_PROJECTILE_SPEED, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 2, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_CROSS })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Fire a {C:KEYWORD}Projectile that deals %s damage to the main target and %s damage to targets adjacent to it. {FORCE_NEWLINE} Applies {C:KEYWORD}Cold for %s to all targets hit."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_SECONDARY_DAMAGE_MIN, Tags.STAT_ABILITY_DEBUFF_DURATION)
end
ABILITY.icon = Vector:new(3, 2)
ABILITY.iconColor = COLORS.STANDARD_ICE
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonFrontCantBePassable
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local target = ActionUtils.indicateProjectile(entity, direction, abilityStats, castingGuide)
    if target then
        local area = abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
        ActionUtils.indicateArea(entity, target, area, castingGuide)
        castingGuide:unindicate(entity.body:getPosition())
    end

end
local ACTION = class(ACTIONS_FRAGMENT.CAST_PROJECTILE)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.projectilePrefab = "frost_staff"
    self.color = ABILITY.iconColor
end

local LEGENDARY = ITEM:createLegendary("Staff of Nyx")
local LEGENDARY_STAT_LINE = "Increase all {C:KEYWORD}Cold duration by %s."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DEBUFF_DURATION] = 1 })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_DEBUFF_DURATION)
end
LEGENDARY.decorateOutgoingHit = function(entity, hit, abilityStats)
    local value = abilityStats:get(Tags.STAT_MODIFIER_DEBUFF_DURATION)
    for buff in hit.buffs() do
        if BUFFS:get("COLD"):isInstance(buff) then
            buff.duration = buff.duration + value
        end

    end

end
return ITEM

