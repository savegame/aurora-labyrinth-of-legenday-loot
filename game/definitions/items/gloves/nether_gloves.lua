local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Nether Gloves")
local ABILITY = require("structures.ability_def"):new("Strike from the Beyond")
ABILITY:addTag(Tags.ABILITY_TAG_PLUS_BASIC_ATTACK)
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ABILITY:addTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(21, 17)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 6, [Tags.STAT_MAX_MANA] = 34, [Tags.STAT_ABILITY_POWER] = 2.45, [Tags.STAT_ABILITY_RANGE_MIN] = 2, [Tags.STAT_ABILITY_RANGE_MAX] = 3, [Tags.STAT_ABILITY_DAMAGE_BASE] = 9.8, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.12) })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE_MAX] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE_MAX] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Range %s - Teleport in front of an enemy and {C:KEYWORD}Attack it," .. " dealing %s bonus damage. Teleport back to your previous position."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_ABILITY_DAMAGE_MIN)
end
local function getTargetEnemy(entity, direction, abilityStats)
    local body = entity.body
    local range = abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local rangeMin = abilityStats:get(Tags.STAT_ABILITY_RANGE_MIN)
    local reason = TERMS.INVALID_DIRECTION_NO_ENEMY
    for i = rangeMin, range do
        local target = body:getPosition() + Vector[direction] * i
        if not entity.vision:isVisible(target) then
            break
        end

        local entityAt = body:getEntityAt(target)
        if ActionUtils.isAliveAgent(entityAt) then
            local moveTo = target - Vector[direction]
            if body:isPassable(moveTo) then
                return entityAt, false
            else
                reason = TERMS.INVALID_DIRECTION_BLOCKED
            end

        end

    end

    return false, reason
end

ABILITY.icon = Vector:new(1, 2)
ABILITY.iconColor = COLORS.STANDARD_PSYCHIC
ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local _, reason = getTargetEnemy(entity, direction, abilityStats)
    return reason
end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local targetEntity = getTargetEnemy(entity, direction, abilityStats)
    local range = abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local rangeMin = abilityStats:get(Tags.STAT_ABILITY_RANGE_MIN)
    for i = rangeMin, range do
        local target = entity.body:getPosition() + Vector[direction] * i
        if not entity.body:canBePassable(target) or not entity.vision:isVisible(target) then
            break
        end

        if targetEntity and target == targetEntity.body:getPosition() then
            castingGuide:indicate(target)
            break
        else
            castingGuide:indicateWeak(target)
        end

    end

end
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local SPRITE_FADE_DURATION = 0.3
local SPEED_MULTIPLIER = 0.7
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("charactereffects")
    self:addComponentAs("charactereffects", "extraeffects")
    self:addComponent("outline")
    self.outline:setIsFull()
    self.outline.color = ABILITY.iconColor
    self:addComponentAs("outline", "extraoutline")
    self.extraoutline:setIsFull()
    self.extraoutline.color = ABILITY.iconColor
end

function ACTION:process(currentEvent)
    local entity = self.entity
    entity.sprite:turnToDirection(self.direction)
    local targetEntity = getTargetEnemy(entity, self.direction, self.abilityStats)
    local moveTo = targetEntity.body:getPosition() - Vector[self.direction]
    local moveFrom = entity.body:getPosition()
    local offset = entity.offset:createProfile()
    local outlineCharacter = entity.sprite:createCharacterCopy()
    self.extraoutline:setEntity(outlineCharacter)
    self.extraeffects:setEntity(outlineCharacter)
    entity.sprite.opacity = 0
    entity.body:setPosition(moveTo)
    offset.bodyScrolling = moveFrom - moveTo
    offset.body = moveTo - moveFrom
    self.extraeffects:chainFadeOutSprite(currentEvent, SPRITE_FADE_DURATION)
    offset.disableModY = true
    self.extraoutline:chainFadeIn(currentEvent, SPRITE_FADE_DURATION):chainEvent(function(_, anchor)
        outlineCharacter.sprite.timeStopped = true
    end)
    Common.playSFX("TELEPORT")
    currentEvent = self.outline:chainFadeIn(currentEvent, SPRITE_FADE_DURATION)
    self.charactereffects:chainFadeInSprite(currentEvent, SPRITE_FADE_DURATION)
    local waitGroup = currentEvent:createWaitGroup(2)
    self.outline:chainFadeOut(currentEvent, SPRITE_FADE_DURATION):chainWaitGroupDone(waitGroup)
    entity.player:multiplyAttackSpeed(SPEED_MULTIPLIER)
    local attackAction = entity.melee:createAction(self.direction)
    attackAction:parallelResolve(currentEvent)
    attackAction.baseAttack:setBonusFromAbilityStats(self.abilityStats)
    currentEvent = attackAction:chainEvent(currentEvent):chainEvent(function(_, anchor)
        entity.body:endOfMove(anchor, moveFrom, moveTo)
        entity.player:multiplyAttackSpeed(1 / SPEED_MULTIPLIER)
    end):chainWaitGroupDone(waitGroup)
    waitGroup:chainEvent(function(_, anchor)
        local position = entity.body:getPosition()
        if position ~= moveTo then
            anchor:chainProgress(SPRITE_FADE_DURATION / 2):chainProgress(SPRITE_FADE_DURATION / 2, function(progress)
                offset.bodyScrolling = moveFrom - moveTo - (position - moveTo) * progress
            end)
        end

    end)
    self.charactereffects:chainFadeOutSprite(waitGroup, SPRITE_FADE_DURATION)
    currentEvent = self.outline:chainFadeIn(waitGroup, SPRITE_FADE_DURATION):chainEvent(function(_, anchor)
        Common.getPositionComponent(outlineCharacter):setPosition(moveTo)
        entity.body:setPosition(moveFrom)
        entity.offset:deleteProfile(offset)
    end)
    self.charactereffects:chainFadeInSprite(currentEvent, SPRITE_FADE_DURATION)
    self.extraoutline:chainFadeOut(currentEvent, SPRITE_FADE_DURATION)
    currentEvent = self.outline:chainFadeOut(currentEvent, SPRITE_FADE_DURATION):chainEvent(function(_, anchor)
        entity.body:endOfMove(anchor, moveTo, moveFrom)
    end)
    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Hand of the Cosmos")
local LEGENDARY_STAT_LINE = "{C:KEYWORD}Chance on {C:KEYWORD}Attack to have exactly " .. "%s {C:KEYWORD}Attack {C:KEYWORD}Damage."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 60, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = 0 })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
LEGENDARY.modifyItem = function(item)
    item.conditionalNonAbilityStat = function(stat, entity, baseStats)
        if entity.playertriggers.proccingSlot == ITEM.slot then
            if stat == Tags.STAT_ATTACK_DAMAGE_MIN or stat == Tags.STAT_ATTACK_DAMAGE_MAX then
                local value = entity.equipment:getStatBonus(stat, ITEM.slot)
                local targetValue = baseStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
                return targetValue - value
            end

        end

        return 0
    end
end
return ITEM

