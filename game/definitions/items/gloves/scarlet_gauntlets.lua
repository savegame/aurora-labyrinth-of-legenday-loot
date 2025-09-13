local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ACTION_CONSTANTS = require("actions.constants")
local ACTIONS_FRAGMENT = require("actions.fragment")
local TRIGGERS = require("actions.triggers")
local ActionUtils = require("actions.utils")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local TERMS = require("text.terms")
local ITEM = require("structures.item_def"):new("Scarlet Gauntlets")
local ABILITY = require("structures.ability_def"):new("Vampiric Strike")
ABILITY:addTag(Tags.ABILITY_TAG_RESTORES_HEALTH)
ABILITY:addTag(Tags.ABILITY_TAG_PLUS_BASIC_ATTACK)
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(1, 20)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 32, [Tags.STAT_MAX_MANA] = 8, [Tags.STAT_ABILITY_POWER] = 2.64, [Tags.STAT_ABILITY_DENOMINATOR] = 3, [Tags.STAT_SECONDARY_DAMAGE_BASE] = 6.4, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = 0 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DENOMINATOR] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Attack an enemy. Restore health equal " .. "to %s of the damage dealt plus %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DENOMINATOR, Tags.STAT_SECONDARY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(7, 11)
ABILITY.iconColor = COLORS.STANDARD_RAGE
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonEnemyAttack
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local target = ActionUtils.indicateExtendableAttack(entity, direction, abilityStats, castingGuide)
    if ABILITY.getInvalidReason(entity, direction, abilityStats) then
        castingGuide:indicateWeak(target)
    end

end
local TRIGGER = class(TRIGGERS.ON_DAMAGE)
local EFFECT_DELAY = 0.4
local HEAL_DELAY = 0.2
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("drain")
    self.drain.particleGapMultiplier = 0.5
    self.drain.speedMin = 2
    self.drain.speedMax = 3
end

function TRIGGER:process(currentEvent)
    self.drain:start(self.entity, self.hit.targetEntity)
    local sound = Common.playSFX("DRAIN")
    return currentEvent:chainProgress(EFFECT_DELAY):chainEvent(function()
        self.drain:stop()
    end):chainProgress(HEAL_DELAY):chainEvent(function(_, anchor)
        sound:stop()
        local bonus = self.abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MIN)
        local denominator = self.abilityStats:get(Tags.STAT_ABILITY_DENOMINATOR)
        local hitter = self.entity.hitter
        local value = hitter:resolveInteger(self.hit.minDamage / denominator) + bonus
        local healHit = hitter:createHit()
        healHit:setHealing(value, value, self.abilityStats)
        healHit:applyToEntity(anchor, self.entity)
    end)
end

function TRIGGER:isEnabled()
    return self.hit.damageType == Tags.DAMAGE_TYPE_MELEE and self.hit:isDamagePositive()
end

local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.triggerClasses:push(TRIGGER)
end

function BUFF:decorateTriggerAction(action)
    BUFF:super(self, "decorateTriggerAction", action)
    self.triggerClasses:clear()
end

local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local GLOW_DURATION = 0.25
local SPEED_MULTIPLIER = 0.5
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
end

function ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    self.entity.player:multiplyAttackSpeed(SPEED_MULTIPLIER)
    self.outline:chainFadeIn(currentEvent, GLOW_DURATION)
    local attackAction = self.entity.melee:createAction(self.direction)
    attackAction:parallelResolve(currentEvent)
    return attackAction:chainEvent(currentEvent):chainEvent(function(_, anchor)
        self.outline:chainFadeOut(anchor, GLOW_DURATION)
        self.entity.player:multiplyAttackSpeed(1 / SPEED_MULTIPLIER)
    end)
end

local LEGENDARY = ITEM:createLegendary("Bloodthirst")
local LEGENDARY_STAT_LINE = "After casting, if your health is still below %s" .. ", reset this ability's cooldown."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DENOMINATOR] = 2 })
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_DENOMINATOR)
end
local LEGENDARY_TRIGGER = class(TRIGGERS.ON_SLOT_DEACTIVATE)
function LEGENDARY_TRIGGER:isEnabled()
    local denominator = self.abilityStats:get(Tags.STAT_MODIFIER_DENOMINATOR)
    if self.entity.tank:getRatio() >= 1 / denominator then
        return false
    end

    return self.triggeringSlot == self:getSlot()
end

function LEGENDARY_TRIGGER:process(currentEvent)
    self.entity.equipment:resetCooldown(self.triggeringSlot)
    return currentEvent
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

