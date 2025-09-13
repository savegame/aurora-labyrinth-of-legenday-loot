local Vector = require("utils.classes.vector")
local Color = require("utils.classes.color")
local Common = require("common")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local ActionUtils = require("actions.utils")
local PLAYER_TRIGGERS = require("actions.player_triggers")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Crimson Gloves")
local ABILITY = require("structures.ability_def"):new("Life Drain")
ABILITY:addTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_RESTORES_HEALTH)
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_PERIODIC_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(3, 12)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 12, [Tags.STAT_MAX_MANA] = 28, [Tags.STAT_ABILITY_POWER] = 4, [Tags.STAT_ABILITY_DAMAGE_BASE] = 16, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.54), [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_SUSTAIN_MODE] = Tags.SUSTAIN_MODE_FULL, [Tags.STAT_ABILITY_RANGE] = 3 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Range %s - Target an enemy. {FORCE_NEWLINE} {C:KEYWORD}Sustain %s - " .. "Deal %s damage to the target and restore health equal to half of the damage."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(9, 4)
ABILITY.iconColor = COLORS.STANDARD_RAGE
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonEnemy
ABILITY.indicate = ActionUtils.indicateEnemyWithinRange
local TRIGGER = class(TRIGGERS.END_OF_TURN)
function TRIGGER:initialize(entity, direction, abilityStats)
    self:super(self, "initialize", entity, direction, abilityStats)
    self.targetEntity = false
end

function TRIGGER:process(currentEvent)
    local hit = self.entity.hitter:createHit()
    hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
    hit:applyToEntity(currentEvent, self.targetEntity)
    local healHit = self.entity.hitter:createHit()
    healHit:setHealing(hit.minDamage / 2, hit.maxDamage / 2, self.abilityStats)
    healHit:applyToEntity(currentEvent, self.entity)
    return currentEvent
end

local BUFF = class(BUFFS.DEACTIVATOR)
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats)
    self.triggerClasses:push(TRIGGER)
    self.expiresImmediately = true
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
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
    self:addComponent("drain")
    self.targetEntity = false
    self.sound = false
end

function ACTION:toData(convertToData)
    return { targetEntity = convertToData(self.targetEntity) }
end

function ACTION:setFromLoad(data, convertFromData)
    self.targetEntity = convertFromData(data.targetEntity)
    self.drain:start(self.entity, self.targetEntity)
    self.sound = Common.playSFX("DRAIN")
end

function ACTION:shouldDeactivate()
    if self.targetEntity.tank.hasDiedOnce then
        return true
    end

    return not self:isVisible(self.targetEntity.body:getPosition())
end

function ACTION:deactivate()
    self.drain:stop()
    self.sound:stop()
end

function ACTION:process(currentEvent)
    self.targetEntity = ActionUtils.getEnemyWithinRange(self.entity, self.direction, self.abilityStats)
    Common.playSFX("CAST_CHARGE")
    return self.outline:chainFullEvent(currentEvent, ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION):chainEvent(function()
        self.drain:start(self.entity, self.targetEntity)
        self.sound = Common.playSFX("DRAIN")
    end)
end

local LEGENDARY = ITEM:createLegendary("The Blue Moon's Hunger")
LEGENDARY.strokeColor = COLORS.STANDARD_ICE
LEGENDARY.statLine = "Whenever you restore health, restore mana equal to half of the health restored."
local LEGENDARY_TRIGGER = class(PLAYER_TRIGGERS.MANA_ON_HEAL)
function LEGENDARY_TRIGGER:isEnabled()
    return not self.hit.affectsMana
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

