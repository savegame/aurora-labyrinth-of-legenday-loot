local Set = require("utils.classes.set")
local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local PLAYER_COMMON = require("actions.player_common")
local PLAYER_TRIGGERS = require("actions.player_triggers")
local ATTACK_WEAPON = require("actions.attack_weapon")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Dimensional Sword")
local ABILITY = require("structures.ability_def"):new("Dimensional Cleave")
ABILITY:addTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(6, 10)
ITEM.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 20.2, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.6), [Tags.STAT_VIRTUAL_RATIO] = 0.47, [Tags.STAT_ABILITY_POWER] = 3.39, [Tags.STAT_ABILITY_RANGE] = 3, [Tags.STAT_ABILITY_DAMAGE_BASE] = 27.08, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.29), [Tags.STAT_ABILITY_AREA_CLEAVE] = 5 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_AREA_CLEAVE] = 2 })
local FORMAT = "{C:KEYWORD}Range %s - Teleport behind the furthest enemy in range then deal %s " .. "to %s, facing the target enemy."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_AREA_CLEAVE)
end
ABILITY.icon = Vector:new(2, 7)
ABILITY.iconColor = COLORS.STANDARD_PSYCHIC
local function getMoveTo(entity, direction, abilityStats)
    local body = entity.body
    local range = abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local currentMoveTo = false
    local reason = TERMS.INVALID_DIRECTION_NO_ENEMY
    for i = 1, range do
        local target = body:getPosition() + Vector[direction] * i
        if not entity.vision:isVisible(target) then
            break
        end

        local entityAt = body:getEntityAt(target)
        if entityAt and entityAt:hasComponent("agent") then
            local moveTo = target + Vector[direction]
            if body:isPassable(moveTo) and entity.vision:isVisible(moveTo) then
                currentMoveTo = moveTo
            else
                reason = TERMS.INVALID_DIRECTION_BLOCKED
            end

        end

    end

    if currentMoveTo then
        return currentMoveTo, false
    else
        return false, reason
    end

end

ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local _, reason = getMoveTo(entity, direction, abilityStats)
    return reason
end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local moveTo = getMoveTo(entity, direction, abilityStats)
    local range = abilityStats:get(Tags.STAT_ABILITY_RANGE)
    for i = 1, range do
        local target = entity.body:getPosition() + Vector[direction] * i
        if not entity.body:canBePassable(target) or not entity.vision:isVisible(target) then
            break
        end

        if target == moveTo then
            break
        end

        castingGuide:indicateWeak(target)
    end

    if moveTo then
        castingGuide:indicateMoveTo(moveTo)
        castingGuide:unindicate(moveTo)
        local area = abilityStats:get(Tags.STAT_ABILITY_AREA_CLEAVE)
        for position in (ActionUtils.getCleavePositions(moveTo, area, reverseDirection(direction))()) do
            castingGuide:indicate(position)
        end

    end

end
local ACTION = class(PLAYER_COMMON.TELEPORT)
ABILITY.actionClass = ACTION
local SPEED_MULTIPLIER = 0.7
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
end

function ACTION:postCharacterMove(currentEvent)
    self.entity.sprite:turnToDirection(reverseDirection(self.direction))
    self.outlineCharacter.sprite:turnToDirection(reverseDirection(self.direction))
end

function ACTION:postEntityMove(currentEvent)
    self.outlineCharacter:delete()
    self.outline:setEntity(self.entity)
    self.entity.charactereffects.outlineOpacity = 1
    self.entity.charactereffects.outlineColor = ABILITY.iconColor
    local cleaveAction = self.entity.actor:create(PLAYER_COMMON.WEAPON_CLEAVE, reverseDirection(self.direction), self.abilityStats)
    return cleaveAction:parallelChainEvent(currentEvent)
end

function ACTION:parallelResolve(anchor)
    self.moveTo = getMoveTo(self.entity, self.direction, self.abilityStats)
end

function ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    return ACTION:super(self, "process", currentEvent)
end

local LEGENDARY = ITEM:createLegendary("The Void Between the Stars")
LEGENDARY.abilityExtraLine = "Recast this ability at a random direction."
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_MANA_COST] = 20 })
local LEGENDARY_TRIGGER = class(PLAYER_TRIGGERS.BARRAGE)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_ALWAYS
end

function LEGENDARY_TRIGGER:shouldDeleteOriginal()
    return false
end

LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_MANA_COST, Tags.STAT_DOWNGRADED)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

