local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local ActionUtils = require("actions.utils")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Overlord Armor")
local ABILITY = require("structures.ability_def"):new("Bonds of Pain")
ABILITY:addTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(1, 17)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 48, [Tags.STAT_MAX_MANA] = 12, [Tags.STAT_ABILITY_POWER] = 4.8, [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_RANGE] = 3, [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Range %s - Target an enemy. {FORCE_NEWLINE} {C:KEYWORD}Quick " .. "{C:KEYWORD}Buff %s - Whenever you take damage, Deal the same amount of damage to the target."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_ABILITY_BUFF_DURATION)
end
ABILITY.icon = Vector:new(3, 9)
ABILITY.iconColor = COLORS.STANDARD_DEATH
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonEnemy
ABILITY.indicate = ActionUtils.indicateEnemyWithinRange
local TRIGGER = class(TRIGGERS.POST_HIT)
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.targetEntity = false
    self.sortOrder = 0
end

function TRIGGER:isEnabled()
    return self.hit:isDamagePositiveDirect()
end

function TRIGGER:process(currentEvent)
    local hit = self.entity.hitter:createHit()
    hit.sound = false
    hit:setDamage(Tags.DAMAGE_TYPE_SPELL, self.hit.minDamage, self.hit.maxDamage)
    hit.slotSource = self:getSlot()
    hit:applyToEntity(currentEvent, self.targetEntity)
    return currentEvent
end

local BUFF = class(BUFFS.DEACTIVATOR)
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats)
    self.triggerClasses:push(TRIGGER)
    self.expiresAtStart = true
end

function BUFF:onTurnStart(anchor, entity)
    if self.action:shouldDeactivate() then
        self.action:deactivate()
        entity.equipment:deactivateSlot(anchor, self.abilityStats:get(Tags.STAT_SLOT))
    end

end

function BUFF:decorateTriggerAction(action)
    BUFF:super(self, "decorateTriggerAction", action)
    action.targetEntity = self.action.targetEntity
end

local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local DRAIN_STARTING_RANGE = 0.6
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
    self:addComponent("drain")
    self.drain.color = ABILITY.iconColor
    self.drain.startingRange = DRAIN_STARTING_RANGE
    self.drain.speedMin = 1.5
    self.drain.speedMax = 3
    self.targetEntity = false
    self.sound = false
end

function ACTION:shouldDeactivate()
    if self.targetEntity.tank.hasDiedOnce then
        return true
    end

    return not self:isVisible(self.targetEntity.body:getPosition())
end

function ACTION:toData(convertToData)
    return { targetEntity = convertToData(self.targetEntity) }
end

function ACTION:setFromLoad(data, convertFromData)
    self.targetEntity = convertFromData(data.targetEntity)
    self.drain:start(self.targetEntity, self.entity)
    self.sound = Common.playSFX("DRAIN", 0.4, 1)
end

function ACTION:deactivate()
    self.drain:stop()
    self.sound:stop()
end

local DRAIN_COLOR = ABILITY.iconColor
function ACTION:process(currentEvent)
    self.targetEntity = ActionUtils.getEnemyWithinRange(self.entity, self.direction, self.abilityStats)
    Common.playSFX("CAST_CHARGE")
    return self.outline:chainFullEvent(currentEvent, ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION):chainEvent(function()
        self.sound = Common.playSFX("DRAIN", 0.4, 1)
        self.drain:start(self.targetEntity, self.entity)
    end)
end

local LEGENDARY = ITEM:createLegendary("Tormentor's Rapture")
local LEGENDARY_STAT_LINE = "Whenever you get damaged, reduce a random ability's cooldown by " .. "%s."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_VALUE)
end
local LEGENDARY_TRIGGER = class(TRIGGERS.POST_HIT)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    self:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = -1
end

function LEGENDARY_TRIGGER:isEnabled()
    if not self.hit:isDamagePositiveDirect() then
        return false
    end

    local equipment = self.entity.equipment
    for slot in (equipment:getSlotsWithAbilities())() do
        local cooldown = equipment:getCooldownFor(slot)
        if cooldown > 0 then
            return true
        end

    end

    return false
end

function LEGENDARY_TRIGGER:parallelResolve(currentEvent)
    self.hit:forceResolve()
end

function LEGENDARY_TRIGGER:process(currentEvent)
    local equipment = self.entity.equipment
    local slotsWithCooldown = equipment:getSlotsWithAbilities():accept(function(slot)
        return equipment:getCooldownFor(slot) > 0
    end)
    if not slotsWithCooldown:isEmpty() then
        local slot = slotsWithCooldown:randomValue(self:getLogicRNG())
        equipment:reduceCooldown(slot, self.abilityStats:get(Tags.STAT_MODIFIER_VALUE))
    end

    return currentEvent
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

