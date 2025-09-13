local Vector = require("utils.classes.vector")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ACTION_CONSTANTS = require("actions.constants")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Ghost Treads")
local ABILITY = require("structures.ability_def"):new("Ghost Walk")
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(9, 21)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 18, [Tags.STAT_MAX_MANA] = 22, [Tags.STAT_ABILITY_POWER] = 1.72, [Tags.STAT_ABILITY_QUICK] = 1 })
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
local FORMAT_SHORT = "Move to the first unoccupied space in the target direction. {C:KEYWORD}Quick."
ABILITY.getDescription = function(item)
    return FORMAT_SHORT
end
local TEXT_OCCUPIED_REQUIRED = "Must target an occupied space."
ABILITY.icon = Vector:new(12, 9)
ABILITY.iconColor = COLORS.STANDARD_GHOST
local function getMoveTo(entity, direction)
    local target = entity.body:getPosition() + Vector[direction]
    while entity.vision:isVisible(target) do
        if entity.body:isPassable(target) then
            return target
        else
            target = target + Vector[direction]
        end

    end

    return false
end

ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local moveTo = getMoveTo(entity, direction)
    if moveTo then
        if moveTo == entity.body:getPosition() + Vector[direction] then
            return TEXT_OCCUPIED_REQUIRED
        else
            return false
        end

    else
        return TERMS.INVALID_DIRECTION_BLOCKED
    end

end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local moveTo = getMoveTo(entity, direction)
    if moveTo and moveTo ~= entity.body:getPosition() + Vector[direction] then
        castingGuide:indicateMoveTo(moveTo)
    end

end
local STEP_DURATION = ACTION_CONSTANTS.WALK_DURATION * 0.9
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local GHOST_COLOR = ABILITY.iconColor
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("move")
    self.move:setEasingToLinear()
    self.move.interimSkipTriggers = true
    self.move.interimSkipProjectiles = true
    self:addComponent("outline")
    self.outline.color = GHOST_COLOR
    self.outline:setIsFull()
    self:addComponent("charactereffects")
end

function ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    if self.direction == LEFT or self.direction == RIGHT then
        self.entity.sprite.layer = Tags.LAYER_ABOVE_EFFECTS
    end

    local moveTo = getMoveTo(self.entity, self.direction, self.abilityStats)
    self.move.distance = self.entity.body:getPosition():distanceManhattan(moveTo)
    self.move:prepare(currentEvent)
    Common.playSFX("ENCHANT")
    self.outline:chainFadeIn(currentEvent, STEP_DURATION)
    self.charactereffects:chainFadeOutSprite(currentEvent, STEP_DURATION)
    local totalDuration = STEP_DURATION * self.move.distance
    local fadeinEvent = currentEvent:chainProgress(totalDuration - STEP_DURATION)
    self.outline:chainFadeOut(fadeinEvent, STEP_DURATION)
    self.charactereffects:chainFadeInSprite(fadeinEvent, STEP_DURATION)
    return self.move:chainMoveEvent(currentEvent, totalDuration):chainEvent(function()
        self.entity.sprite:resetLayer()
    end)
end

local LEGENDARY = ITEM:createLegendary("The Unseen Apparition")
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_MANA_COST] = -5 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_MANA_COST] = -5 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_MANA_COST] = -5 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ABILITY_MANA_COST] = -5 })
LEGENDARY.modifyItem = function(item)
    item:multiplyStatAndGrowth(Tags.STAT_ABILITY_COOLDOWN, 0)
    item:markAltered(Tags.STAT_ABILITY_COOLDOWN, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ABILITY_MANA_COST, Tags.STAT_UPGRADED)
end
return ITEM

