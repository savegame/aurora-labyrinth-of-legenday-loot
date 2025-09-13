local Vector = require("utils.classes.vector")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Marathon Treads")
local ABILITY = require("structures.ability_def"):new("Sprint")
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_NOT_IMMUNE)
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(1, 18)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 24, [Tags.STAT_MAX_MANA] = 16, [Tags.STAT_ABILITY_POWER] = 1.88, [Tags.STAT_ABILITY_BUFF_DURATION] = 2, [Tags.STAT_ABILITY_SUSTAIN_MODE] = Tags.SUSTAIN_MODE_FULL, [Tags.STAT_ABILITY_RANGE] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Sustain %s - Move %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_RANGE)
end
ABILITY.icon = Vector:new(3, 1)
ABILITY.iconColor = COLORS.STANDARD_WIND
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonFrontIsNotPassable
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local moveTo = ActionUtils.getDashMoveTo(entity, direction, abilityStats)
    if moveTo and moveTo ~= entity.body:getPosition() then
        castingGuide:indicateMoveTo(moveTo)
    end

end
local STEP_DURATION = ACTION_CONSTANTS.WALK_DURATION
local TRIGGER = class(TRIGGERS.END_OF_TURN)
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.buff = false
end

function TRIGGER:process(currentEvent)
    local moveTo = ActionUtils.getDashMoveTo(self.entity, self.direction, self.abilityStats)
    local distance = self.entity.body:getPosition():distanceManhattan(moveTo)
    if distance > 0 then
        local moveAction = self.entity.actor:create(ACTIONS_FRAGMENT.TRAIL_MOVE, self.direction, self.abilityStats)
        moveAction.distance = distance
        self.buff.totalDistance = self.buff.totalDistance + distance
        moveAction.stepDuration = STEP_DURATION / self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
        currentEvent = moveAction:parallelChainEvent(currentEvent)
    end

    return currentEvent
end

local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats)
    self.outlinePulseColor = ABILITY.iconColor
    self.triggerClasses:push(TRIGGER)
    self.expiresImmediately = true
    self.totalDistance = 0
end

function BUFF:rememberAction()
    return true
end

function BUFF:toData()
    return { totalDistance = self.totalDistance }
end

function BUFF:fromData(data)
    self.totalDistance = data.totalDistance
end

function BUFF:onTurnStart(anchor, entity)
    self.action:deactivateIfBlocked(anchor)
end

function BUFF:decorateTriggerAction(action)
    BUFF:super(self, "decorateTriggerAction", action)
    action.direction = self.action.direction
    action.buff = self
end

function BUFF:onDelete(anchor, entity)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        local hit = entity.hitter:createHit()
        hit:setHealing(self.totalDistance * self.abilityStats:get(Tags.STAT_MODIFIER_VALUE))
        hit.affectsMana = true
        hit:applyToEntity(anchor, entity)
    end

end

local ACTION = class(ACTIONS_FRAGMENT.SHOW_ICON_SELF)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self.icon = ITEM.icon
end

function ACTION:deactivateIfBlocked(anchor)
    local moveTo = ActionUtils.getDashMoveTo(self.entity, self.direction, self.abilityStats)
    if moveTo == self.entity.body:getPosition() or not self.entity.buffable:canMove() then
        self.entity.equipment:deactivateSlot(anchor, self.abilityStats:get(Tags.STAT_SLOT))
    end

end

local LEGENDARY = ITEM:createLegendary("Indefatigable")
local LEGENDARY_EXTRA_LINE = "When this ability ends, restore %s mana for every " .. "space traveled."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 5 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_VALUE)
end
return ITEM

