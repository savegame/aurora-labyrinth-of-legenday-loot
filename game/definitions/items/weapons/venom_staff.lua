local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTIONS_FRAGMENT = require("actions.fragment")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Venom Staff")
local ABILITY = require("structures.ability_def"):new("Toxic Missile")
ABILITY:addTag(Tags.ABILITY_TAG_PRODUCES_PROJECTILES)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(16, 3)
ITEM.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 17, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.25), [Tags.STAT_COOLDOWN_REDUCTION] = 2, [Tags.STAT_VIRTUAL_RATIO] = 0.84, [Tags.STAT_ABILITY_POWER] = 3.15 * 0.75, [Tags.STAT_ABILITY_PROJECTILE_SPEED] = CONSTANTS.PLAYER_PROJECTILE_SPEED, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 6, [Tags.STAT_POISON_DAMAGE_BASE] = 5.4 * 1.25 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
local FORMAT = "Fire a {C:KEYWORD}Projectile that pierces through enemies. Enemies hit are " .. "{C:KEYWORD}Poisoned, making them lose %s health over %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_POISON_DAMAGE_TOTAL, Tags.STAT_ABILITY_DEBUFF_DURATION)
end
ABILITY.icon = Vector:new(11, 8)
ABILITY.iconColor = COLORS.STANDARD_POISON
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonFrontCantBePassable
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local source = entity.body:getPosition()
    local target = source
    local speed = abilityStats:get(Tags.STAT_ABILITY_PROJECTILE_SPEED)
    while target and (entity.body:hasEntityWithAgent(target) or target == source) do
        target = ActionUtils.indicateProjectile(entity, direction, abilityStats, castingGuide, target, speed)
        speed = CONSTANTS.PRODUCED_PROJECTILE_SPEED
    end

end
local ACTION = class(ACTIONS_FRAGMENT.CAST_PROJECTILE)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.projectilePrefab = "venom_staff"
    self.color = ABILITY.iconColor
end

local LEGENDARY = ITEM:createLegendary("Staff of Achlys")
local LEGENDARY_STAT_LINE = "Enemies lose %s more health every turn from your {C:KEYWORD}Poisons."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 1.5, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = 0 })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
LEGENDARY.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositive() and hit.damageType == Tags.DAMAGE_TYPE_POISON then
        hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
        hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
        hit:increaseBonusState()
    end

end
return ITEM

