local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local textStatFormat = require("text.stat_format")
local COLORS = require("draw.colors")
local ITEM = require("structures.item_def"):new("Temporal Helm")
local ABILITY = require("structures.ability_def"):new("Time Stop")
ABILITY:addTag(Tags.ABILITY_TAG_BUFF_NOT_CONSIDERED)
ABILITY:addTag(Tags.ABILITY_TAG_SURROUNDING_DISABLE)
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_NOT_IMMUNE)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(22, 16)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 30, [Tags.STAT_MAX_MANA] = 10, [Tags.STAT_ABILITY_POWER] = 5.3, [Tags.STAT_ABILITY_BUFF_DURATION] = 3 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Buff %s - Freeze time, preventing everything else from taking any turns."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION)
end
ABILITY.icon = Vector:new(1, 5)
ABILITY.iconColor = COLORS.STANDARD_LIGHTNING
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local ACTION = class(ACTIONS_FRAGMENT.CAST)
ABILITY.actionClass = ACTION
ABILITY.buffClass = class(BUFFS.DEACTIVATOR)
local SCREEN_FLASH_OPACITY = 0.7
local SCREEN_FLASH_DURATION = 0.6
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = COLORS.STANDARD_STEEL
    self:speedMultiply(ACTION_CONSTANTS.SLOW_CAST_MULTIPLIER)
    self.sound = false
end

function ACTION:setFromLoad()
    self.entity.agentvisitor:getSystemAgent():addTimeStop(1)
    self:getEffects():addTimeStop(1)
end

function ACTION:process(currentEvent)
    return ACTION:super(self, "process", currentEvent):chainEvent(function()
        self.sound = Common.playSFX("TIME_STOP_LOOP")
        local entity = self.entity
        local effects = self:getEffects()
        effects:flashScreen(SCREEN_FLASH_DURATION, COLORS.STANDARD_STEEL, SCREEN_FLASH_OPACITY)
        effects:addTimeStop(1)
        self.entity.agentvisitor:getSystemAgent():addTimeStop(1)
    end)
end

function ACTION:deactivate(anchor)
    self.entity.agentvisitor:getSystemAgent():addTimeStop(-1)
    self:getEffects():addTimeStop(-1)
    self.sound:stop()
end

local LEGENDARY = ITEM:createLegendary("Master of Time")
local LEGENDARY_STAT_LINE = "{C:KEYWORD}Chance after getting hit to freeze time for %s turns."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 2 })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_VALUE)
end
local LEGENDARY_TRIGGER = class(TRIGGERS.POST_HIT)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
    self.sortOrder = self.sortOrder - 1
end

function LEGENDARY_TRIGGER:isEnabled()
    return not self.entity.agentvisitor:getSystemAgent():isTimeStopped()
end

local FLASH_MULTIPLIER = 0.5
function LEGENDARY_TRIGGER:process(currentEvent)
    local effects = self:getEffects()
    Common.playSFX("TIME_STOP")
    effects:flashScreen(SCREEN_FLASH_DURATION, COLORS.STANDARD_STEEL, SCREEN_FLASH_OPACITY * FLASH_MULTIPLIER)
    self.entity.charactereffects:flash(ACTION_CONSTANTS.STANDARD_FLASH_DURATION, COLORS.STANDARD_LIGHTNING)
    local buff = BUFFS:get("REACTIVE_TIME_STOP"):new(self.abilityStats:get(Tags.STAT_MODIFIER_VALUE) + 1)
    self.entity.buffable:apply(buff)
    self.entity.agentvisitor:visit(function(agent)
        agent.agent.hasActedThisTurn = false
    end)
    return currentEvent
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

