local Vector = require("utils.classes.vector")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTIONS_FRAGMENT = require("actions.fragment")
local TRIGGERS = require("actions.triggers")
local BUFFS = require("definitions.buffs")
local CONSTANTS = require("logic.constants")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Fire Staff")
local ABILITY = require("structures.ability_def"):new("Fireball")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(15, 3)
ITEM.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 17, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.25), [Tags.STAT_COOLDOWN_REDUCTION] = 2, [Tags.STAT_VIRTUAL_RATIO] = 0.89, [Tags.STAT_ABILITY_POWER] = 3.09 * 0.75, [Tags.STAT_ABILITY_DAMAGE_BASE] = 21.5 * 1.25, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.69), [Tags.STAT_ABILITY_PROJECTILE_SPEED] = CONSTANTS.PLAYER_PROJECTILE_SPEED, [Tags.STAT_SECONDARY_DAMAGE_BASE] = 7.87 * 1.25, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.69), [Tags.STAT_ABILITY_BURN_DURATION] = 2, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_CROSS })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BURN_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BURN_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Fire a {C:KEYWORD}Projectile that explodes on collision, dealing %s damage to a " .. "%s. {FORCE_NEWLINE} %s, %s health lost per turn."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_AREA_ROUND, Tags.STAT_ABILITY_BURN_DURATION, Tags.STAT_SECONDARY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(4, 7)
ABILITY.iconColor = COLORS.STANDARD_FIRE
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
    self.projectilePrefab = "fire_staff"
    self.color = ABILITY.iconColor
end

local LEGENDARY = ITEM:createLegendary("Staff of Hemera")
local LEGENDARY_STAT_LINE = "Whenever you kill an enemy on a {C:KEYWORD}Burn space, " .. "it deals %s damage to all targets around it."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 11.2, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.7) })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
local LEGENDARY_TRIGGER = class(TRIGGERS.ON_KILL)
local EXPLOSION_DURATION = 0.5
local EXPLOSION_SHAKE_INTENSITY = 1.0
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.explosion.excludeSelf = true
    self.explosion.shakeIntensity = EXPLOSION_SHAKE_INTENSITY
end

function LEGENDARY_TRIGGER:process(currentEvent)
    self.explosion:setArea(Tags.ABILITY_AREA_3X3)
    self.explosion.source = self.position
    Common.playSFX("EXPLOSION_MEDIUM")
    return self.explosion:chainFullEvent(currentEvent, EXPLOSION_DURATION, function(anchor, position)
        if position ~= self.entity.body:getPosition() then
            local hit = self.entity.hitter:createHit(self.explosion.source)
            hit:setDamageFromModifierStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
            hit:applyToPosition(anchor, position)
        end

    end)
end

function LEGENDARY_TRIGGER:isEnabled()
    if not self.killed:hasComponent("agent") then
        return false
    end

    if self.killingHit and self.killingHit.spawnFire then
        return true
    end

    return self.entity.body:hasSteppableExclusivity(self.position, Tags.STEP_EXCLUSIVE_ENGULF)
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

