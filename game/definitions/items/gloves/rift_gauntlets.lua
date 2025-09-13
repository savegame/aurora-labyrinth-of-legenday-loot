local Set = require("utils.classes.set")
local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local PLAYER_COMMON = require("actions.player_common")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Rift Gauntlets")
local ABILITY = require("structures.ability_def"):new("Rift Strike")
ABILITY:addTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_PLUS_BASIC_ATTACK)
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(8, 16)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 28, [Tags.STAT_MAX_MANA] = 12, [Tags.STAT_ABILITY_POWER] = 3.05, [Tags.STAT_ABILITY_RANGE] = 3, [Tags.STAT_ABILITY_DAMAGE_BASE] = 9.6, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.26) })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
local FORMAT = "{C:KEYWORD}Range %s - Teleport behind the furthest enemy in range and " .. "{C:KEYWORD}Attack it, dealing %s bonus damage."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(9, 5)
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
        castingGuide:indicate(moveTo - Vector[direction])
    end

end
local ACTION = class(PLAYER_COMMON.TELEPORT)
ABILITY.actionClass = ACTION
local SPEED_MULTIPLIER = 0.7
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:speedMultiply(SPEED_MULTIPLIER)
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
    local attackAction = self.entity.melee:createAction(reverseDirection(self.direction))
    attackAction:parallelResolve(currentEvent)
    attackAction.baseAttack:setBonusFromAbilityStats(self.abilityStats)
    attackAction:chainEvent(currentEvent)
end

function ACTION:parallelResolve(anchor)
    self.moveTo = getMoveTo(self.entity, self.direction, self.abilityStats)
end

function ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    return ACTION:super(self, "process", currentEvent)
end

local LEGENDARY = ITEM:createLegendary("Endless Spiral")
LEGENDARY.statLine = "{C:KEYWORD}Chance before getting hit to cast this " .. "ability for free at the attacker."
local LEGENDARY_TRIGGER = class(TRIGGERS.PRE_HIT)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
    self.hitSource = false
end

function LEGENDARY_TRIGGER:isEnabled()
    if self.entity.buffable:canMove() and self.entity.player:canAttack() then
        if self.hit:isDamageOrDebuff() then
            local sourceEntity = self.hit.sourceEntity
            if ActionUtils.isAliveAgent(sourceEntity) then
                local source = sourceEntity.body:getPosition()
                local entityPosition = self.entity.body:getPosition()
                if source.x == entityPosition.x or source.y == entityPosition.y then
                    local direction = Common.getDirectionTowards(entityPosition, source)
                    local teleportLocation = source + Vector[direction]
                    if self.entity.vision:isVisible(teleportLocation) and self.entity.body:isPassable(teleportLocation) then
                        return true
                    end

                end

            end

        end

    end

    return false
end

function LEGENDARY_TRIGGER:process(currentEvent)
    local entity = self.entity
    local source = self.hitSource.body:getPosition()
    local direction = Common.getDirectionTowards(entity.body:getPosition(), source)
    local teleportLocation = source + Vector[direction]
    local action = entity.actor:create(ACTION, direction, self.abilityStats)
    action:parallelResolve(currentEvent)
    action.moveTo = teleportLocation
    local buff = ABILITY.buffClass:new(1, self.abilityStats, action)
    entity.buffable:forceApply(buff)
    return action:chainEvent(currentEvent):chainEvent(function(_, anchor)
        entity.buffable:delete(anchor, ABILITY.buffClass)
    end)
end

function LEGENDARY_TRIGGER:parallelResolve(currentEvent)
    self.hitSource = self.hit.sourceEntity
    self.hit:clear()
    self.hit.sound = false
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

