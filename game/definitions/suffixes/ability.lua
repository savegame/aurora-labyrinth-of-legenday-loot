local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local BUFFS = require("definitions.buffs")
local Common = require("common")
local textStatFormat = require("text.stat_format")
local ModifierDef = require("structures.modifier_def")
local COLORS = require("draw.colors")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local ACTION_CONSTANTS = require("actions.constants")
local PLAYER_TRIGGERS = require("actions.player_triggers")
local BUFFS = require("definitions.buffs")
local MULTIPLICABLE_BASE_DAMAGE = 1000
local BLITZ = ModifierDef:new("Blitz")
local BLITZ_FORMAT = "Deals %s bonus damage to enemies with full health."
local BLITZ_RATIO = 1 / 4
BLITZ:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = MULTIPLICABLE_BASE_DAMAGE, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = 0 })
BLITZ.abilityExtraLine = function(item)
    return textStatFormat(BLITZ_FORMAT, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
BLITZ.canRoll = function(itemDef)
    return itemDef.ability:hasTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
end
BLITZ.modifyItem = function(item)
    local targetMinDamage = item:getStatAtMax(Tags.STAT_ABILITY_DAMAGE_MIN) * BLITZ_RATIO
    local targetMaxDamage = item:getStatAtMax(Tags.STAT_ABILITY_DAMAGE_MAX) * BLITZ_RATIO
    local modDamage = item.modifierDef:getStatAtMax(Tags.STAT_MODIFIER_DAMAGE_MIN)
    item:multiplyStatAndGrowth(Tags.STAT_MODIFIER_DAMAGE_MIN, targetMinDamage / modDamage)
    item:multiplyStatAndGrowth(Tags.STAT_MODIFIER_DAMAGE_MAX, targetMaxDamage / modDamage)
end
BLITZ.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit.slotSource == abilityStats:get(Tags.STAT_SLOT) then
        if hit:isDamagePositiveDirect() then
            if hit.targetEntity and hit.targetEntity.tank:getRatio() == 1 then
                hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
                hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
                hit:increaseBonusState()
            end

        end

    end

end
local PARAGON = ModifierDef:new("Paragon")
local PARAGON_FORMAT = "Deals %s bonus damage to {C:KEYWORD}Elite enemies."
local PARAGON_RATIO = 0.4
PARAGON:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = MULTIPLICABLE_BASE_DAMAGE, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = 0 })
PARAGON.abilityExtraLine = function(item)
    return textStatFormat(PARAGON_FORMAT, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
PARAGON.canRoll = function(itemDef)
    return (itemDef.ability:hasTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE) or itemDef.ability:hasTag(Tags.ABILITY_TAG_BOOSTABLE_PERIODIC_DAMAGE))
end
PARAGON.modifyItem = function(item)
    local targetMinDamage = item:getStatAtMax(Tags.STAT_ABILITY_DAMAGE_MIN) * PARAGON_RATIO
    local targetMaxDamage = item:getStatAtMax(Tags.STAT_ABILITY_DAMAGE_MAX) * PARAGON_RATIO
    local modDamage = item.modifierDef:getStatAtMax(Tags.STAT_MODIFIER_DAMAGE_MIN)
    item:multiplyStatAndGrowth(Tags.STAT_MODIFIER_DAMAGE_MIN, targetMinDamage / modDamage)
    item:multiplyStatAndGrowth(Tags.STAT_MODIFIER_DAMAGE_MAX, targetMaxDamage / modDamage)
end
PARAGON.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit.slotSource == abilityStats:get(Tags.STAT_SLOT) then
        if hit:isDamagePositiveDirect() then
            if Common.isElite(hit.targetEntity) then
                hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
                hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
                hit:increaseBonusState()
            end

        end

    end

end
local CHILLING = ModifierDef:new("Chilling")
local CHILLING_FORMAT = "Apply {C:KEYWORD}Cold to damaged enemies for %s."
CHILLING:setToStatsBase({ [Tags.STAT_MODIFIER_DEBUFF_DURATION] = 2 })
CHILLING.abilityExtraLine = function(item)
    return textStatFormat(CHILLING_FORMAT, item, Tags.STAT_MODIFIER_DEBUFF_DURATION)
end
CHILLING.canRoll = function(itemDef)
    return ((not itemDef.ability:hasTag(Tags.ABILITY_TAG_DEBUFF_COLD)) and (itemDef.statsBase:get(Tags.STAT_ABILITY_BURN_DURATION, 0) == 0) and itemDef.ability:hasTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE))
end
CHILLING.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit.slotSource == abilityStats:get(Tags.STAT_SLOT) then
        if hit:isDamagePositiveDirect() then
            local duration = abilityStats:get(Tags.STAT_MODIFIER_DEBUFF_DURATION)
            hit:addBuff(BUFFS:get("COLD"):new(duration))
        end

    end

end
local SUPERIORITY = ModifierDef:new("Superiority")
SUPERIORITY.abilityExtraLine = "{C:KEYWORD}Chance to deal double damage."
SUPERIORITY.canRoll = function(itemDef)
    return (itemDef.ability:hasTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE) or itemDef.ability:hasTag(Tags.ABILITY_TAG_BOOSTABLE_PERIODIC_DAMAGE))
end
SUPERIORITY.decorateOutgoingHit = function(entity, hit, abilityStats)
    local slot = abilityStats:get(Tags.STAT_SLOT)
    if hit.slotSource == slot then
        if hit:isDamagePositiveDirect() then
            if entity.playertriggers.proccingSlot == slot then
                hit:multiplyDamage(2)
                hit:increaseBonusState()
            end

        end

    end

end
local EXECUTION = ModifierDef:new("Execution")
local EXECUTION_FORMAT = "Deals %s bonus damage to enemies with less than half health."
local EXECUTION_RATIO = 1 / 4
EXECUTION:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = MULTIPLICABLE_BASE_DAMAGE, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = 0 })
EXECUTION.abilityExtraLine = function(item)
    return textStatFormat(EXECUTION_FORMAT, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
EXECUTION.canRoll = function(itemDef)
    return (itemDef.ability:hasTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE) or itemDef.ability:hasTag(Tags.ABILITY_TAG_BOOSTABLE_PERIODIC_DAMAGE))
end
EXECUTION.modifyItem = function(item)
    local targetMinDamage = item:getStatAtMax(Tags.STAT_ABILITY_DAMAGE_MIN) * EXECUTION_RATIO
    local targetMaxDamage = item:getStatAtMax(Tags.STAT_ABILITY_DAMAGE_MAX) * EXECUTION_RATIO
    local modDamage = item.modifierDef:getStatAtMax(Tags.STAT_MODIFIER_DAMAGE_MIN)
    item:multiplyStatAndGrowth(Tags.STAT_MODIFIER_DAMAGE_MIN, targetMinDamage / modDamage)
    item:multiplyStatAndGrowth(Tags.STAT_MODIFIER_DAMAGE_MAX, targetMaxDamage / modDamage)
end
EXECUTION.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit.slotSource == abilityStats:get(Tags.STAT_SLOT) then
        if hit:isDamagePositiveDirect() then
            if hit.targetEntity and hit.targetEntity.tank:getRatio() < 1 / 2 then
                hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
                hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
                hit:increaseBonusState()
            end

        end

    end

end
local EMPOWERING = ModifierDef:new("Empowering")
local EMPOWERING_FORMAT = "In addition, your {C:KEYWORD}Attack "
local EMPOWERING_FORMAT_END = " deals %s bonus damage."
local EMPOWERING_QUICK = "this turn"
local EMPOWERING_NORMAL = "next turn"
EMPOWERING:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = MULTIPLICABLE_BASE_DAMAGE, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.35) })
EMPOWERING.abilityExtraLine = function(item)
    local line = EMPOWERING_FORMAT
    if item.stats:get(Tags.STAT_ABILITY_QUICK, 0) > 0 then
        line = line .. EMPOWERING_QUICK
    else
        line = line .. EMPOWERING_NORMAL
    end

    return line .. textStatFormat(EMPOWERING_FORMAT_END, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
EMPOWERING.canRoll = function(itemDef)
    if itemDef.statsBase:get(Tags.STAT_ABILITY_SUSTAIN_MODE, 0) > 0 then
        return false
    end

    if itemDef.ability:hasTag(Tags.ABILITY_TAG_DISENGAGE_MELEE) then
        return false
    end

    return not itemDef.ability:hasTag(Tags.ABILITY_TAG_PLUS_BASIC_ATTACK)
end
local EMPOWERING_BUFF = BUFFS:define("EMPOWER")
function EMPOWERING_BUFF:initialize(duration, abilityStats)
    EMPOWERING_BUFF:super(self, "initialize", duration)
    self.abilityStats = abilityStats
    self.expiresImmediately = (abilityStats:get(Tags.STAT_ABILITY_QUICK, 0) > 0)
    self.outlinePulseColor = COLORS.STANDARD_PSYCHIC
end

function EMPOWERING_BUFF:getDataArgs()
    return self.duration, self.abilityStats
end

function EMPOWERING_BUFF:decorateOutgoingHit(hit)
    if hit.damageType == Tags.DAMAGE_TYPE_MELEE and hit:isDamagePositive() then
        hit.minDamage = hit.minDamage + self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
        hit.maxDamage = hit.maxDamage + self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
        hit:increaseBonusState()
    end

end

function EMPOWERING_BUFF:shouldCombine(oldBuff)
    return false
end

local EMPOWERING_TRIGGER = class(TRIGGERS.POST_CAST)
function EMPOWERING_TRIGGER:isEnabled()
    return self.triggeringSlot == self:getSlot()
end

function EMPOWERING_TRIGGER:process(currentEvent)
    local buff = EMPOWERING_BUFF:new(1, self.abilityStats)
    if self.abilityStats:get(Tags.STAT_ABILITY_QUICK, 0) > 0 then
        self.entity.buffable:forceApply(buff)
    else
        self.entity.buffable:apply(buff)
    end

    return currentEvent
end

local EMPOWERING_RATIO = 0.08
EMPOWERING.modifyItem = function(item)
    local costStat = Tags.STAT_ABILITY_MANA_COST
    if item.stats:get(Tags.STAT_ABILITY_HEALTH_COST, 0) > 0 then
        costStat = Tags.STAT_ABILITY_HEALTH_COST
    end

    local cost = max(item:getStatAtMax(costStat), 60)
    local multiplier = EMPOWERING_RATIO * cost / MULTIPLICABLE_BASE_DAMAGE
    if costStat == Tags.STAT_ABILITY_HEALTH_COST then
        multiplier = multiplier * 2
    end

    item:multiplyStatAndGrowth(Tags.STAT_MODIFIER_DAMAGE_MIN, multiplier)
    item:multiplyStatAndGrowth(Tags.STAT_MODIFIER_DAMAGE_MAX, multiplier)
    item.triggers:push(EMPOWERING_TRIGGER)
end
local PROTECTION = ModifierDef:new("Protection")
local PROTECTION_FORMAT = "In addition, gain {C:KEYWORD}Resist %s until the start of your next turn."
PROTECTION:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 4, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = 0 })
PROTECTION.abilityExtraLine = function(item)
    return textStatFormat(PROTECTION_FORMAT, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
PROTECTION.canRoll = function(itemDef)
            if itemDef.ability:hasTag(Tags.ABILITY_TAG_SURROUNDING_DISABLE) then
        return false
    elseif itemDef.ability:hasTag(Tags.ABILITY_TAG_DISENGAGE_MELEE) then
        return false
    elseif itemDef.ability:hasTag(Tags.ABILITY_TAG_NEGATES_DAMAGE) then
        return false
    end

    return true
end
local PROTECTION_BUFF = class("structures.buff")
function PROTECTION_BUFF:initialize(duration, abilityStats)
    PROTECTION_BUFF:super(self, "initialize", duration)
    self.expiresAtStart = true
    self.abilityStats = abilityStats
    self.outlinePulseColor = COLORS.STANDARD_STEEL
end

function PROTECTION_BUFF:decorateIncomingHit(hit)
    if hit:isDamagePositiveDirect() then
        hit:reduceDamage(self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN))
        hit:decreaseBonusState()
    end

end

function PROTECTION_BUFF:shouldCombine(oldBuff)
    return false
end

local PROTECTION_TRIGGER = class(TRIGGERS.POST_CAST)
function PROTECTION_TRIGGER:isEnabled()
    return self.triggeringSlot == self:getSlot()
end

function PROTECTION_TRIGGER:process(currentEvent)
    self.entity.buffable:apply(PROTECTION_BUFF:new(1, self.abilityStats))
    return currentEvent
end

PROTECTION.modifyItem = function(item)
    if item.stats:get(Tags.STAT_ABILITY_QUICK, 0) > 0 or item:getSlot() == Tags.SLOT_GLOVES then
        item:multiplyStatAndGrowth(Tags.STAT_MODIFIER_DAMAGE_MIN, 0.6)
        item:multiplyStatAndGrowth(Tags.STAT_MODIFIER_DAMAGE_MAX, 0.6)
    end

    item.triggers:push(PROTECTION_TRIGGER)
end
local BARRAGE = ModifierDef:new("Barrage")
BARRAGE.abilityExtraLine = "{C:KEYWORD}Chance to recast this ability for free at another " .. "random direction."
BARRAGE.canRoll = function(itemDef)
    return itemDef.ability:hasTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
end
BARRAGE.modifyItem = function(item)
    item.triggers:push(PLAYER_TRIGGERS.BARRAGE)
end
local CADENCE = ModifierDef:new("Rhythm")
local CADENCE_FORMAT = "{C:KEYWORD}Chance to instantly reset this ability's cooldown after "
local CADENCE_INSTANT = "casting."
local CADENCE_BUFF = "expiring or being canceled."
CADENCE.abilityExtraLine = function(item)
    if (item.stats:get(Tags.STAT_ABILITY_BUFF_DURATION, 0) > 0 and item.stats:get(Tags.STAT_ABILITY_SUSTAIN_MODE, 0) ~= Tags.SUSTAIN_MODE_AUTOCAST) then
        return CADENCE_FORMAT .. CADENCE_BUFF
    else
        return CADENCE_FORMAT .. CADENCE_INSTANT
    end

end
CADENCE.canRoll = function(itemDef)
    return true
end
local CADENCE_TRIGGER = class(TRIGGERS.ON_SLOT_DEACTIVATE)
function CADENCE_TRIGGER:initialize(entity, direction, abilityStats)
    CADENCE_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function CADENCE_TRIGGER:isEnabled()
    return self.triggeringSlot == self:getSlot()
end

function CADENCE_TRIGGER:process(currentEvent)
    self.entity.equipment:resetCooldown(self.triggeringSlot)
    return currentEvent
end

CADENCE.modifyItem = function(item)
    item.triggers:push(CADENCE_TRIGGER)
end
local RANCOR = ModifierDef:new("Enmity")
RANCOR.statLine = "{C:KEYWORD}Chance to {C:KEYWORD}Attack a random enemy whenever you cast an ability directly."
RANCOR.canRoll = function(itemDef)
    return itemDef.slot ~= Tags.SLOT_ARMOR
end
local RANCOR_TRIGGER = class(TRIGGERS.POST_CAST)
function RANCOR_TRIGGER:initialize(entity, direction, abilityStats)
    RANCOR_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function RANCOR_TRIGGER:isEnabled()
    return self.entity.player:canAttack()
end

function RANCOR_TRIGGER:process(currentEvent)
    local direction = ActionUtils.getRandomAttackDirection(self:getLogicRNG(), self.entity)
    if direction then
        local attackAction = self.entity.melee:createAction(direction)
        return attackAction:parallelChainEvent(currentEvent)
    end

    return currentEvent
end

RANCOR.modifyItem = function(item)
    item.triggers:push(RANCOR_TRIGGER)
end
local MAGUS = ModifierDef:new("Magus")
local MAGUS_FORMAT = "{C:KEYWORD}Chance to restore %s mana after casting."
MAGUS.abilityExtraLine = function(item)
    return textStatFormat(MAGUS_FORMAT, item, Tags.STAT_ABILITY_MANA_COST)
end
MAGUS.canRoll = function(itemDef)
    return itemDef:getStatAtMax(Tags.STAT_ABILITY_MANA_COST) > 10
end
local MAGUS_TRIGGER = class(TRIGGERS.POST_CAST)
function MAGUS_TRIGGER:initialize(entity, direction, abilityStats)
    MAGUS_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function MAGUS_TRIGGER:isEnabled()
    return self.triggeringSlot == self:getSlot()
end

function MAGUS_TRIGGER:process(currentEvent)
    local hit = self.entity.hitter:createHit()
    local manaCost = self.entity.equipment:getBaseSlotStat(self:getSlot(), Tags.STAT_ABILITY_MANA_COST)
    hit:setHealing(manaCost, manaCost, self.abilityStats)
    hit.affectsMana = true
    hit:applyToEntity(currentEvent, self.entity)
    return currentEvent
end

MAGUS.modifyItem = function(item)
    item.triggers:push(MAGUS_TRIGGER)
end
local PENDULUM = ModifierDef:new("the Pendulum")
PENDULUM.abilityExtraLine = "{C:KEYWORD}Chance to take another turn after casting."
PENDULUM.canRoll = function(itemDef)
    local statsBase = itemDef.statsBase
            if statsBase:get(Tags.STAT_ABILITY_SUSTAIN_MODE, 0) > 0 then
        return false
    elseif statsBase:get(Tags.STAT_ABILITY_QUICK, 0) > 0 then
        return false
    elseif itemDef.ability:hasTag(Tags.ABILITY_TAG_SURROUNDING_DISABLE) then
        return false
    end

    if itemDef.slot == Tags.SLOT_ARMOR then
        return false
    end

    return itemDef:getStatAtMax(Tags.STAT_ABILITY_COOLDOWN) >= 12
end
local PENDULUM_TRIGGER = class(TRIGGERS.POST_CAST)
function PENDULUM_TRIGGER:initialize(entity, direction, abilityStats)
    PENDULUM_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function PENDULUM_TRIGGER:isEnabled()
    return self.triggeringSlot == self:getSlot()
end

function PENDULUM_TRIGGER:process(currentEvent)
    local entity = self.entity
    currentEvent:chainEvent(function()
        Common.playSFX("TIME_STOP")
    end)
    entity.charactereffects:flash(ACTION_CONSTANTS.STANDARD_FLASH_DURATION, COLORS.STANDARD_LIGHTNING)
    entity.buffable:forceApply(BUFFS:get("REACTIVE_TIME_STOP"):new(1))
    return currentEvent:chainProgress(ACTION_CONSTANTS.STANDARD_FLASH_DURATION)
end

PENDULUM.modifyItem = function(item)
    item.triggers:push(PENDULUM_TRIGGER)
end
local FULMINATION = ModifierDef:new("Fulmination")
local FULMINATION_FORMAT = "Deal %s damage to all adjacent enemies after casting."
local FULMINATION_AREA = Tags.ABILITY_AREA_CROSS
FULMINATION:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = MULTIPLICABLE_BASE_DAMAGE, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.9) })
FULMINATION.abilityExtraLine = function(item)
    return textStatFormat(FULMINATION_FORMAT, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
FULMINATION.canRoll = function(itemDef)
    if itemDef.ability:hasTag(Tags.ABILITY_TAG_DISENGAGE_MELEE) then
        return false
    end

    return true
end
local FULMINATION_TRIGGER = class(TRIGGERS.POST_CAST)
function FULMINATION_TRIGGER:initialize(entity, direction, abilityStats)
    FULMINATION_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.explosion:setHueToLightning()
    self.explosion.excludeSelf = true
end

function FULMINATION_TRIGGER:isEnabled()
    return self.triggeringSlot == self:getSlot()
end

local FULMINATION_EXPLOSION_DURATION = 0.4
function FULMINATION_TRIGGER:process(currentEvent)
    self.explosion.source = self.entity.body:getPosition()
    self.explosion:setArea(FULMINATION_AREA)
    Common.playSFX("EXPLOSION_SMALL")
    return self.explosion:chainFullEvent(currentEvent, FULMINATION_EXPLOSION_DURATION, function(anchor, target)
        local hit = self.entity.hitter:createHit()
        hit:setDamageFromModifierStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        hit:applyToPosition(anchor, target)
    end)
end

local FULMINATION_RATIO = 0.6
FULMINATION.modifyItem = function(item)
    local cost = max(item:getStatAtMax(Tags.STAT_ABILITY_COOLDOWN), 6)
    if item:getAbility():hasTag(Tags.ABILITY_TAG_DYNAMIC_COOLDOWN) then
        cost = 15
    end

    local multiplier = FULMINATION_RATIO * cost / MULTIPLICABLE_BASE_DAMAGE
    item:multiplyStatAndGrowth(Tags.STAT_MODIFIER_DAMAGE_MIN, multiplier)
    item:multiplyStatAndGrowth(Tags.STAT_MODIFIER_DAMAGE_MAX, multiplier)
    item.triggers:push(FULMINATION_TRIGGER)
end
local LICH = ModifierDef:new("the Lich")
local LICH_FORMAT = "Restore health equal to %s of the damage dealt to enemies at the end of this ability."
LICH:setToStatsBase({ [Tags.STAT_MODIFIER_DENOMINATOR] = 10 })
LICH.abilityExtraLine = function(item)
    return textStatFormat(LICH_FORMAT, item, Tags.STAT_MODIFIER_DENOMINATOR)
end
LICH.canRoll = function(itemDef)
    if itemDef.ability:hasTag(Tags.ABILITY_TAG_RESTORES_HEALTH) then
        return false
    end

    return (itemDef.ability:hasTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE) and (itemDef.statsBase:get(Tags.STAT_ABILITY_PROJECTILE_SPEED, 0) == 0))
end
local LICH_RECORDING_TRIGGER = class(TRIGGERS.ON_DAMAGE)
function LICH_RECORDING_TRIGGER:isEnabled()
    if self.hit.slotSource == self:getSlot() and self.hit:isDamagePositiveDirect() then
        if self.hit.targetEntity and self.hit.targetEntity:hasComponent("agent") then
            return true
        end

    end

    return false
end

function LICH_RECORDING_TRIGGER:process(currentEvent)
    local equipment = self.entity.equipment
    local slot = self:getSlot()
    local value = equipment:getTempStatBonus(slot, Tags.STAT_MODIFIER_VALUE)
    equipment:setTempStatBonus(slot, Tags.STAT_MODIFIER_VALUE, value + self.hit.minDamage)
    return currentEvent
end

local LICH_TRIGGER = class(TRIGGERS.ON_SLOT_DEACTIVATE)
function LICH_TRIGGER:initialize(entity, direction, abilityStats)
    LICH_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
end

function LICH_TRIGGER:isEnabled()
    return self.triggeringSlot == self:getSlot()
end

function LICH_TRIGGER:process(currentEvent)
    local equipment = self.entity.equipment
    local slot = self:getSlot()
    local value = equipment:getTempStatBonus(slot, Tags.STAT_MODIFIER_VALUE)
    equipment:setTempStatBonus(slot, Tags.STAT_MODIFIER_VALUE, 0)
    local hit = self.entity.hitter:createHit()
    local denominator = self.abilityStats:get(Tags.STAT_MODIFIER_DENOMINATOR)
    hit:setHealing(value / denominator, self.abilityStats)
    hit:applyToEntity(currentEvent, self.entity)
    return currentEvent
end

LICH.modifyItem = function(item)
    item.triggers:push(LICH_RECORDING_TRIGGER)
    item.triggers:push(LICH_TRIGGER)
end
return { BLITZ = BLITZ, PARAGON = PARAGON, CHILLING = CHILLING, SUPERIORITY = SUPERIORITY, EXECUTION = EXECUTION, EMPOWERING = EMPOWERING, PROTECTION = PROTECTION, BARRAGE = BARRAGE, CADENCE = CADENCE, RANCOR = RANCOR, MAGUS = MAGUS, PENDULUM = PENDULUM, FULMINATION = FULMINATION, LICH = LICH }

