local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTIONS_FRAGMENT = require("actions.fragment")
local TRIGGERS = require("actions.triggers")
local ActionUtils = require("actions.utils")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Seismic Hammer")
local ABILITY = require("structures.ability_def"):new("Strength of the Mountain")
ABILITY:addTag(Tags.ABILITY_TAG_BUFF_HALF_CONSIDERED)
ABILITY:addTag(Tags.ABILITY_TAG_BUFF_NO_EXTEND)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(10, 18)
ITEM.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 20.75, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.8), [Tags.STAT_VIRTUAL_RATIO] = 0.32, [Tags.STAT_ABILITY_POWER] = 3.89, [Tags.STAT_ABILITY_BUFF_DURATION] = 10, [Tags.STAT_ABILITY_COUNT] = 3, [Tags.STAT_ABILITY_DAMAGE_BASE] = 20.75 / 2, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.85), [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_3X3, [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Quick {C:KEYWORD}Buff %s - Your next %s {C:KEYWORD}Attacks shake the ground, dealing %s damage to the target and all spaces around it (except yours)."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_COUNT, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(10, 9)
ABILITY.iconColor = COLORS.STANDARD_EARTH
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local TRIGGER = class(TRIGGERS.ON_ATTACK)
local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.triggerClasses:push(TRIGGER)
    self.outlinePulseColor = ABILITY.iconColor
    self.instances = abilityStats:get(Tags.STAT_ABILITY_COUNT)
end

function BUFF:toData()
    return { instances = self.instances }
end

function BUFF:fromData(data)
    self.instances = data.instances
end

function BUFF:reduceInstances(anchor, entity)
    self.instances = self.instances - 1
    if self.instances == 0 then
        entity.equipment:deactivateSlot(anchor, self.abilityStats:get(Tags.STAT_SLOT))
    end

end

function BUFF:decorateTriggerAction(action)
    BUFF:super(self, "decorateTriggerAction", action)
    action.buff = self
end

local EFFECT_DELAY = 0.25
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = 6
    self:addComponent("explosion")
    self.explosion.excludeSelf = false
    self.explosion:setArea(Tags.ABILITY_AREA_3X3)
    self.explosion:setHueToEarth()
    self.buff = false
end

local EXPLOSION_DURATION = 0.45
function TRIGGER:process(currentEvent)
    self.buff:reduceInstances(currentEvent, self.entity)
    currentEvent = currentEvent:chainProgress(EFFECT_DELAY):chainEvent(function(_, anchor)
        Common.playSFX("ROCK_SHAKE")
        self:shakeScreen(anchor, 3)
    end)
    self.explosion.source = self.attackTarget
    return self.explosion:chainFullEvent(currentEvent, EXPLOSION_DURATION, function(anchor, position)
        if position ~= self.entity.body:getPosition() then
            local hit = self.entity.hitter:createHit()
            hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
            hit:applyToPosition(anchor, position)
        end

    end)
end

local ACTION = class(ACTIONS_FRAGMENT.ENCHANT)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
end

local LEGENDARY = ITEM:createLegendary("Rumble")
local LEGENDARY_STAT_LINE = "{C:KEYWORD}Chance after {C:KEYWORD}Attack for " .. "lightning to strike, dealing %s damage and {C:KEYWORD}Stunning for %s."
LEGENDARY.strokeColor = COLORS.STANDARD_LIGHTNING
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 8, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(1), [Tags.STAT_MODIFIER_DEBUFF_DURATION] = 2 })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN, Tags.STAT_MODIFIER_DEBUFF_DURATION)
end
local LEGENDARY_TRIGGER = class(TRIGGERS.ON_ATTACK)
local EFFECT_DELAY = 0.25
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("lightningspawner")
    self.sortOrder = 7
    self.activationType = Tags.TRIGGER_CHANCE
end

function LEGENDARY_TRIGGER:process(currentEvent)
    currentEvent = currentEvent:chainProgress(EFFECT_DELAY):chainEvent(function()
        Common.playSFX("LIGHTNING")
    end)
    return self.lightningspawner:spawn(currentEvent, self.attackTarget):chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit()
        hit:setDamageFromModifierStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        local stunDuration = self.abilityStats:get(Tags.STAT_MODIFIER_DEBUFF_DURATION)
        hit:addBuff(BUFFS:get("STUN"):new(stunDuration))
        hit:applyToPosition(anchor, self.attackTarget)
    end)
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

