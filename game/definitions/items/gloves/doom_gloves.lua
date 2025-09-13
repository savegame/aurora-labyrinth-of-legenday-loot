local Color = require("utils.classes.color")
local Vector = require("utils.classes.vector")
local CONSTANTS = require("logic.constants")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local EASING = require("draw.easing")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Doom Gloves")
local ABILITY = require("structures.ability_def"):new("Touch of Doom")
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(1, 12)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 8, [Tags.STAT_MAX_MANA] = 32, [Tags.STAT_ABILITY_POWER] = 2.46, [Tags.STAT_ABILITY_DAMAGE_BASE] = 80, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.62), [Tags.STAT_ABILITY_DEBUFF_DURATION] = 11 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = -1 })
local FORMAT = "Target an adjacent enemy. After %s, the target takes %s damage."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DEBUFF_DURATION, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(7, 2)
ABILITY.iconColor = COLORS.STANDARD_DEATH
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonEnemy
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local target = entity.body:getPosition() + Vector[direction]
    if ABILITY.getInvalidReason(entity, direction, abilityStats) then
        castingGuide:indicateWeak(target)
    else
        castingGuide:indicate(target)
    end

end
local BUFF = BUFFS:define("DOOM")
local DOOM_COLOR = Color:new(0.2, 0.1, 0.3, 0.4)
local DOOM_HIT_ICON = Vector:new(21, 7)
local DOOM_HIT = class("actions.action")
local FLASH_DURATION = 0.3
local LINGER_DURATION = 0.15
local FADEOUT_DURATION = 0.35
function DOOM_HIT:initialize(entity, direction, abilityStats)
    DOOM_HIT:super(self, "initialize", entity, direction, abilityStats)
    self.targetEntity = false
    self:addComponent("iconflash")
    self.iconflash.icon = DOOM_HIT_ICON
    self.iconflash.color = COLORS.STANDARD_DEATH_BRIGHTER
end

function DOOM_HIT:process(currentEvent)
    local source = self.targetEntity.body:getPosition()
    self.iconflash.target = self.targetEntity.sprite
    Common.playSFX("DOOM")
    currentEvent = self.iconflash:chainFlashEvent(currentEvent, FLASH_DURATION):chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit(self.entity.body:getPosition())
        hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        hit:applyToEntity(anchor, self.targetEntity)
    end)
    currentEvent = currentEvent:chainProgress(LINGER_DURATION)
    local iconEnd = self.iconflash:chainFadeEvent(currentEvent, FADEOUT_DURATION)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        local range = self.abilityStats:get(Tags.STAT_MODIFIER_RANGE)
        self.entity.agentvisitor:visit(function(agent)
            if agent ~= self.targetEntity and not agent.buffable:isAffectedBy(BUFF) then
                local distance = agent.body:getPosition():distanceManhattan(source)
                if distance <= range then
                    iconEnd:chainEvent(function()
                        if self.entity.vision:isVisible(agent.body:getPosition()) then
                            Common.playSFX("AFFLICT")
                        end

                        agent.buffable:apply(BUFF:new(self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION), self.entity, self.abilityStats))
                    end)
                    return true
                end

            end

        end, true, true)
    end

    return currentEvent
end

local function isExpiring(buff, entity)
    return buff.duration <= 1
end

function BUFF:initialize(duration, sourceEntity, abilityStats)
    BUFF:super(self, "initialize", duration)
    self.abilityStats = abilityStats
    self.flashOnApply = true
    self.sourceEntity = sourceEntity
    self.displayTimerColor = COLORS.STANDARD_DEATH_BRIGHTER
    self.delayTurn = isExpiring
end

function BUFF:getDataArgs()
    return self.duration, self.sourceEntity, self.abilityStats
end

function BUFF:onExpire(anchor, entity)
    local action = self.sourceEntity.actor:create(DOOM_HIT, false, self.abilityStats)
    action.targetEntity = entity
    action:parallelChainEvent(anchor)
end

function BUFF:onCombine(oldBuff)
    self.abilityStats = self.abilityStats:clone()
    self.abilityStats:add(Tags.STAT_ABILITY_DAMAGE_MIN, oldBuff.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN))
    self.abilityStats:add(Tags.STAT_ABILITY_DAMAGE_MAX, oldBuff.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX))
    self.duration = max(self.duration, oldBuff.duration)
    return false
end

local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local OUTLINE_DURATION = ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION
local FORWARD_DURATION = 0.27
local BACK_DURATION = 0.32
local FORWARD_DISTANCE = 0.5
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("tackle")
    self:addComponent("charactertrail")
    self.tackle.forwardDistance = FORWARD_DISTANCE
    self:addComponent("outline")
    self.outline.color = COLORS.STANDARD_DEATH_BRIGHTER
end

function ACTION:process(currentEvent)
    local entity = self.entity
    entity.sprite:turnToDirection(self.direction)
    self.tackle:createOffset()
    self.tackle.offset.disableModY = true
    Common.playSFX("CAST_CHARGE")
    currentEvent = self.outline:chainFadeIn(currentEvent, OUTLINE_DURATION):chainEvent(function(_, anchor)
        self.charactertrail:start(anchor)
    end)
    currentEvent = self.tackle:chainForwardEvent(currentEvent, FORWARD_DURATION)
    currentEvent = currentEvent:chainEvent(function(_, anchor)
        local hit = entity.hitter:createHit()
        local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
        local buff = BUFF:new(duration, entity, self.abilityStats)
        hit:addBuff(buff)
        Common.playSFX("AFFLICT")
        hit:applyToPosition(anchor, entity.body:getPosition() + Vector[self.direction])
        self.charactertrail:stop()
    end)
    self.tackle:chainBackEvent(currentEvent, BACK_DURATION):chainEvent(function()
        self.tackle:deleteOffset()
    end)
    self.outline:chainFadeOut(currentEvent, BACK_DURATION)
    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Ruination")
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DEBUFF_DURATION] = 1, [Tags.STAT_MODIFIER_RANGE] = 3 })
local LEGENDARY_STAT_LINE = "{C:KEYWORD}Attacks accelerate {B:ABILITY_LABEL}" .. ABILITY.name .. "."
local LEGENDARY_EXTRA_LINE = "After dealing damage, apply the effect to another enemy within " .. "%s of the target."
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item)
end
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_RANGE)
end
local LEGENDARY_TRIGGER = class(TRIGGERS.ON_ATTACK)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = -1
end

function LEGENDARY_TRIGGER:process(currentEvent)
    local targetEntity = self.entity.body:getEntityAt(self.attackTarget)
    if targetEntity and targetEntity:hasComponent("buffable") then
        local buff = targetEntity.buffable:findOneWithClass(BUFF)
        if buff then
            buff.duration = buff.duration - self.abilityStats:get(Tags.STAT_MODIFIER_DEBUFF_DURATION)
            if buff.duration <= 0 then
                buff:onExpire(currentEvent, targetEntity)
                targetEntity.buffable:delete(currentEvent, BUFF)
            end

        end

    end

    return currentEvent
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

