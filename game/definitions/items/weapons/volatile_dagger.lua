local Vector = require("utils.classes.vector")
local Common = require("common")
local COLORS = require("draw.colors")
local BUFFS = require("definitions.buffs")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTIONS_FRAGMENT = require("actions.fragment")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Volatile Dagger")
local ABILITY = require("structures.ability_def"):new("Explosive Throw")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(17, 17)
ITEM.attackClass = ATTACK_WEAPON.STAB_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 18, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.0), [Tags.STAT_LUNGE] = 1, [Tags.STAT_VIRTUAL_RATIO] = 0.79, [Tags.STAT_ABILITY_POWER] = 3.85, [Tags.STAT_SECONDARY_DAMAGE_BASE] = 18, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.0), [Tags.STAT_ABILITY_DAMAGE_BASE] = 24.75, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.6), [Tags.STAT_ABILITY_PROJECTILE_SPEED] = CONSTANTS.PLAYER_PROJECTILE_SPEED, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_3X3, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 3 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Throw a {C:KEYWORD}Projectile that deals %s damage. If the target enemy is alive " .. "after %s, it deals %s damage to %s centered on it."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_SECONDARY_DAMAGE_MIN, Tags.STAT_ABILITY_DEBUFF_DURATION, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_AREA_ROUND)
end
ABILITY.icon = Vector:new(10, 1)
ABILITY.iconColor = COLORS.STANDARD_FIRE
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonFrontCantBePassable
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local target = ActionUtils.indicateProjectile(entity, direction, abilityStats, castingGuide)
    if target then
        local entityAt = entity.body:getEntityAt(target)
        if ActionUtils.isAliveAgent(entityAt) then
            local area = abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
            for position in (ActionUtils.getAreaPositions(entity, target, area, true))() do
                castingGuide:indicateWeak(position)
            end

        end

    end

end
local EXPLOSION = class("actions.action")
local EXPLOSION_DURATION = 0.6
local EXPLOSION_SHAKE_INTENSITY = 3.0
function EXPLOSION:initialize(entity, direction, abilityStats)
    EXPLOSION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.explosion.excludeSelf = false
    self.explosion.shakeIntensity = EXPLOSION_SHAKE_INTENSITY
    self.targetEntity = false
end

function EXPLOSION:process(currentEvent)
    self.explosion.source = self.targetEntity.body:getPosition()
    Common.playSFX("EXPLOSION_MEDIUM")
    return self.explosion:chainFullEvent(currentEvent, EXPLOSION_DURATION, function(anchor, position)
        if self.entity.body:getPosition() ~= position then
            local hit = self.entity.hitter:createHit(self.explosion.source)
            hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
            hit:applyToPosition(anchor, position)
        end

    end)
end

local BUFF = BUFFS:define("TIMED_EXPLOSION")
local function isExpiring(buff, entity)
    return buff.duration <= 1
end

function BUFF:initialize(duration, sourceEntity, abilityStats)
    BUFF:super(self, "initialize", duration)
    self.displayTimerColor = COLORS.STANDARD_FIRE
    self.sourceEntity = sourceEntity
    self.abilityStats = abilityStats
    self.delayTurn = isExpiring
end

function BUFF:getDataArgs()
    return self.duration, self.sourceEntity, self.abilityStats
end

function BUFF:onExpire(anchor, entity)
    local action = self.sourceEntity.actor:create(EXPLOSION, false, self.abilityStats)
    action.targetEntity = entity
    action:parallelChainEvent(anchor)
end

function BUFF:shouldCombine()
    return false
end

local ACTION = class(ACTIONS_FRAGMENT.THROW)
ABILITY.actionClass = ACTION
function ACTION:process(currentEvent)
    return ACTION:super(self, "process", currentEvent):chainEvent(function(_, anchor)
        self.entity.projectilespawner:spawnSpecial(anchor, "volatile_dagger", self.direction, self.abilityStats)
    end)
end

local LEGENDARY = ITEM:createLegendary("The Ireblade")
LEGENDARY.statLine = ("{C:KEYWORD}Chance on {C:KEYWORD}Attack to apply " .. "{B:ABILITY_LABEL}%s's {B:BASE}hit effect to the target."):format(ITEM.ability.name)
LEGENDARY.decorateOutgoingHit = function(entity, hit, abilityStats)
    local slot = abilityStats:get(Tags.STAT_SLOT)
    if entity.playertriggers.proccingSlot == slot and hit.damageType == Tags.DAMAGE_TYPE_MELEE then
        local duration = abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
        hit:addBuff(BUFF:new(duration, entity, abilityStats))
    end

end
return ITEM

