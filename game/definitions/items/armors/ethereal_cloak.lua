local Vector = require("utils.classes.vector")
local CONSTANTS = require("logic.constants")
local BUFFS = require("definitions.buffs")
local ACTION_CONSTANTS = require("actions.constants")
local ACTIONS_BASIC = require("actions.basic")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local Common = require("common")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Ethereal Cloak")
local ABILITY = require("structures.ability_def"):new("Ethereal Form")
ABILITY:addTag(Tags.ABILITY_TAG_NEGATES_DAMAGE)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(20, 16)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 8, [Tags.STAT_MAX_MANA] = 52, [Tags.STAT_ABILITY_POWER] = 2.5, [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_SUSTAIN_MODE] = Tags.SUSTAIN_MODE_MOBILE })
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
local FORMAT = "{C:KEYWORD}Sustain %s - Immune to all effects and projectiles. Can move while {C:KEYWORD}Sustaining."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION)
end
ABILITY.icon = Vector:new(9, 7)
ABILITY.iconColor = COLORS.STANDARD_GHOST
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
ABILITY.modeCancelClass = ACTIONS_BASIC.WAIT_MODE_CANCEL
local TRIGGER = class(TRIGGERS.PRE_HIT)
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = -10
end

function TRIGGER:isEnabled()
    return self.hit:isDamagePositive() or (not self.hit.buffs:isEmpty()) or self.hit.knockback
end

function TRIGGER:parallelResolve(anchor)
    self.hit:clear()
    self.hit.sound = false
end

local BUFF = class(BUFFS.DEACTIVATOR)
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats)
    self.expiresAtStart = true
    self.outlinePulseColor = ABILITY.iconColor
    self.triggerClasses:push(TRIGGER)
end

local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local GHOST_COLOR = ABILITY.iconColor
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = GHOST_COLOR
    self.outline:setIsFull()
    self:addComponent("charactereffects")
end

function ACTION:process(currentEvent)
    self.entity.body.isFlying = true
    self.entity.body.phaseProjectiles = true
    local duration = ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION
    self.charactereffects:chainFadeOutSprite(currentEvent, duration)
    Common.playSFX("GLOW_MODAL")
    return self.outline:chainFadeIn(currentEvent, duration)
end

function ACTION:setFromLoad()
    self.entity.sprite.opacity = 0
    self.outline:setToFilled()
end

function ACTION:deactivate(currentEvent)
    local duration = ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION
    self.charactereffects:chainFadeInSprite(currentEvent, duration)
    Common.playSFX("CAST_CANCEL")
    return self.outline:chainFadeOut(currentEvent, duration):chainEvent(function(_, anchor)
        self.entity.body.isFlying = false
        self.entity.body.phaseProjectiles = false
        local position = self.entity.body:getPosition()
        self.entity.body:catchProjectilesAt(anchor, position)
        self.entity.body:stepAt(anchor, position)
    end)
end

local LEGENDARY = ITEM:createLegendary("Incorporeal Essence")
LEGENDARY.abilityExtraLine = "You can move through occupied spaces, moving continuously until " .. "the first unoccupied space."
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1, [Tags.STAT_ABILITY_SUSTAIN_MODE] = 1 })
local LEGENDARY_MOVE_ACTION = class(ACTIONS_BASIC.MOVE)
function LEGENDARY_MOVE_ACTION:checkParallel()
    return self.move.distance == 1
end

function LEGENDARY_MOVE_ACTION:process(currentEvent)
    return self.move:chainMoveEvent(currentEvent, self.stepDuration * self.move.distance):chainEvent(function()
        self.charactertrail:stop(currentEvent)
    end)
end

local function getMoveDistance(entity, direction)
    local distance = 1
    local target = entity.body:getPosition() + Vector[direction]
    while entity.vision:isVisible(target) do
        if entity.body:isPassable(target) then
            return distance
        else
            target = target + Vector[direction]
            distance = distance + 1
        end

    end

    return 0
end

function BUFF:getSustainSpecialAction(direction)
    local entity = self.action.entity
    local distance = getMoveDistance(entity, direction)
    if distance == 0 then
        return false
    end

    local action = entity.actor:create(LEGENDARY_MOVE_ACTION, direction)
    action.move.distance = distance
    return action
end

LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_UPGRADED)
end
return ITEM

