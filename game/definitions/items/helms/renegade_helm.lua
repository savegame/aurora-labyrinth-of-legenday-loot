local Vector = require("utils.classes.vector")
local Set = require("utils.classes.set")
local BUFFS = require("definitions.buffs")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local TRIGGERS = require("actions.triggers")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Renegade Helm")
local ABILITY = require("structures.ability_def"):new("Alacrity")
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(13, 20)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 36, [Tags.STAT_MAX_MANA] = 4, [Tags.STAT_ABILITY_POWER] = 3.75, [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_QUICK] = 1 })
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
local FORMAT = "{C:KEYWORD}Quick {C:KEYWORD}Buff %s - At the end of your turn, {C:KEYWORD}Attack a random enemy that you did not {C:KEYWORD}Attack this turn."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION)
end
ABILITY.icon = Vector:new(12, 6)
ABILITY.iconColor = COLORS.STANDARD_WIND
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local TRIGGER = class(TRIGGERS.END_OF_TURN)
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.excludeEnemies = Set.EMPTY
end

function TRIGGER:isEnabled()
    if not self.entity.player:canAttack() then
        return false
    end

    return toBoolean(ActionUtils.getRandomAttackDirection(self:getLogicRNG(), self.entity, function(entityAt)
        return self:isAttackValid(entityAt)
    end))
end

function TRIGGER:isAttackValid(entityAt)
    return not self.excludeEnemies:contains(entityAt)
end

function TRIGGER:process(currentEvent)
    local direction = ActionUtils.getRandomAttackDirection(self:getLogicRNG(), self.entity, function(entityAt)
        return self:isAttackValid(entityAt)
    end)
    if direction then
        local attackAction = self.entity.melee:createAction(direction)
        return attackAction:parallelChainEvent(currentEvent)
    end

    return currentEvent
end

local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.outlinePulseColor = ABILITY.iconColor
    self.triggerClasses:push(TRIGGER)
    self.attackedEnemies = Set:new()
    self.delayTurn = true
end

function BUFF:decorateTriggerAction(action)
    BUFF:super(self, "decorateTriggerAction", action)
    action.excludeEnemies = self.attackedEnemies
end

function BUFF:decorateOutgoingHit(hit)
    if hit.damageType == Tags.DAMAGE_TYPE_MELEE then
        if hit.targetEntity then
            self.attackedEnemies:add(hit.targetEntity)
        end

    end

end

function BUFF:onTurnStart()
    self.attackedEnemies:clear()
end

local ACTION = class(ACTIONS_FRAGMENT.ENCHANT)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
end

local LEGENDARY = ITEM:createLegendary("Dust Devil")
LEGENDARY.statLine = "{C:KEYWORD}Chance whenever you {C:KEYWORD}Attack an enemy to take another turn."
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
local LEGENDARY_TRIGGER = class(TRIGGERS.ON_ATTACK)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function LEGENDARY_TRIGGER:isEnabled()
    return self.entity.body:hasEntityWithAgent(self.attackTarget)
end

function LEGENDARY_TRIGGER:process(currentEvent)
    local entity = self.entity
    currentEvent:chainEvent(function()
        Common.playSFX("CAST_CHARGE")
    end)
    entity.charactereffects:flash(ACTION_CONSTANTS.STANDARD_FLASH_DURATION, COLORS.STANDARD_WIND)
    entity.buffable:forceApply(BUFFS:get("REACTIVE_TIME_STOP"):new(1))
    return currentEvent:chainProgress(ACTION_CONSTANTS.STANDARD_FLASH_DURATION)
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
    item:markAltered(Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_UPGRADED)
end
return ITEM

