local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local TRIGGERS = require("actions.triggers")
local ACTION_CONSTANTS = require("actions.constants")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local PLAYER_TRIGGERS = require("actions.player_triggers")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Gust Boots")
local ABILITY = require("structures.ability_def"):new("Buffeting Winds")
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(14, 21)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 10, [Tags.STAT_MAX_MANA] = 30, [Tags.STAT_ABILITY_POWER] = 2.5, [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_QUICK] = 1, [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Target a direction. {FORCE_NEWLINE} {C:KEYWORD}Quick {C:KEYWORD}Buff %s - At " .. "the end of your turn, move %s in that direction."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_RANGE)
end
ABILITY.icon = Vector:new(12, 11)
ABILITY.iconColor = COLORS.STANDARD_WIND
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local body = entity.body
    castingGuide:indicate(body:getPosition())
    if body:isPassable(body:getPosition() + Vector[direction]) then
        castingGuide:indicateMoveTo(body:getPosition() + Vector[direction])
    end

end
local STEP_DURATION = ACTION_CONSTANTS.WALK_DURATION * 0.9
local TRIGGER = class(TRIGGERS.END_OF_TURN)
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("move")
    self:addComponent("charactertrail")
    self.enabled = false
end

function TRIGGER:isEnabled()
    if not self.enabled then
        return false
    end

    return self.entity.body:isPassableDirection(self.direction)
end

function TRIGGER:process(currentEvent)
    self.charactertrail:start(currentEvent)
    self.move.distance = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
    self.move.direction = self.direction
    self.move:prepare(currentEvent)
    Common.playSFX("DASH_SHORT")
    return self.move:chainMoveEvent(currentEvent, STEP_DURATION):chainEvent(function()
        return self.charactertrail:stop()
    end)
end

local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats)
    self.outlinePulseColor = ABILITY.iconColor
    self.triggerClasses:push(TRIGGER)
end

function BUFF:rememberAction()
    return true
end

function BUFF:decorateTriggerAction(action)
    BUFF:super(self, "decorateTriggerAction", action)
    action.enabled = action.entity.buffable:canMove()
    action.direction = self.action.direction
end

local ACTION = class(ACTIONS_FRAGMENT.SHOW_ICON_SELF)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self.icon = ITEM.icon
end

local LEGENDARY = ITEM:createLegendary("Boots of the Warding Monsoon")
LEGENDARY.statLine = "{C:KEYWORD}Chance before getting hit by a {C:KEYWORD}Melee " .. "{C:KEYWORD}Attack to move {C:NUMBER}1 step towards a random direction."
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
local LEGENDARY_PASSIVE_TRIGGER = class(PLAYER_TRIGGERS.EVASIVE_STEP)
function LEGENDARY_PASSIVE_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_PASSIVE_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_UPGRADED)
    item.triggers:push(LEGENDARY_PASSIVE_TRIGGER)
end
return ITEM

