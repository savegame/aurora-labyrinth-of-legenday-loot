local Vector = require("utils.classes.vector")
local Common = require("common")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local ActionUtils = require("actions.utils")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local TERMS = require("text.terms")
local ITEM = require("structures.item_def"):new("Gale Treads")
local ABILITY = require("structures.ability_def"):new("Dash")
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_NOT_IMMUNE)
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(14, 16)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 16, [Tags.STAT_MAX_MANA] = 24, [Tags.STAT_ABILITY_POWER] = 1.625, [Tags.STAT_ABILITY_RANGE] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Move up to %s"
local FORMAT_LEGENDARY = ", {B:STAT_LINE}passing through obstacles"
ABILITY.getDescription = function(item)
    local description = textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE)
    if item.stats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        description = description .. FORMAT_LEGENDARY
    end

    return description .. "."
end
ABILITY.icon = Vector:new(2, 6)
ABILITY.iconColor = COLORS.STANDARD_WIND
local function getMoveTo(entity, direction, abilityStats)
    if abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        return ActionUtils.getUnblockedDashMoveTo(entity, direction, abilityStats)
    else
        return ActionUtils.getDashMoveTo(entity, direction, abilityStats)
    end

end

ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local moveTo = getMoveTo(entity, direction, abilityStats)
    if moveTo and moveTo ~= entity.body:getPosition() then
        return false
    else
        return TERMS.INVALID_DIRECTION_BLOCKED
    end

end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local moveTo = getMoveTo(entity, direction, abilityStats)
    if moveTo and moveTo ~= entity.body:getPosition() then
        castingGuide:indicateMoveTo(moveTo)
    end

end
local STEP_DURATION = ACTION_CONSTANTS.WALK_DURATION * 0.5
local ACTION = class(ACTIONS_FRAGMENT.TRAIL_MOVE)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.stepDuration = STEP_DURATION
    if abilityStats:get(Tags.STAT_LEGENDARY, 0) then
        self:addComponent("outline")
        self.outline.color = ABILITY.iconColor
        self.outline:setIsFull()
        self:addComponent("charactereffects")
    end

end

local LEGENDARY_GLOW_DURATION = 0.25
function ACTION:parallelResolve(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        self.move.interimSkipTriggers = true
        self.move.interimSkipProjectiles = true
    end

    local moveTo = getMoveTo(self.entity, self.direction, self.abilityStats)
    self.distance = self.entity.body:getPosition():distanceManhattan(moveTo)
    return ACTION:super(self, "parallelResolve", currentEvent)
end

function ACTION:process(currentEvent)
    local isLegendary = self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0
    if isLegendary and self.distance > 1 then
        Common.playSFX("CAST_CHARGE")
        self.charactereffects:chainFadeOutSprite(currentEvent, LEGENDARY_GLOW_DURATION)
        currentEvent = self.outline:chainFadeIn(currentEvent, LEGENDARY_GLOW_DURATION)
        local fadeOutEvent = currentEvent:chainProgress(self.distance * self.stepDuration - LEGENDARY_GLOW_DURATION)
        self.charactereffects:chainFadeInSprite(fadeOutEvent, LEGENDARY_GLOW_DURATION)
        self.outline:chainFadeOut(fadeOutEvent, LEGENDARY_GLOW_DURATION)
    end

    currentEvent = ACTION:super(self, "process", currentEvent)
    if isLegendary and self.distance > 1 then
        self.charactertrail:stop()
    end

    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Messenger of the Gods")
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_RANGE] = 1 })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_RANGE, Tags.STAT_UPGRADED)
end
return ITEM

