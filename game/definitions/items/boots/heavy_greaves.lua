local Vector = require("utils.classes.vector")
local CONSTANTS = require("logic.constants")
local Common = require("common")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Heavy Greaves")
local ABILITY = require("structures.ability_def"):new("Forceful Advance")
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ABILITY:addTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_NOT_IMMUNE)
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(17, 14)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 40, [Tags.STAT_ABILITY_POWER] = 2.15, [Tags.STAT_ABILITY_RANGE] = 2, [Tags.STAT_ABILITY_DAMAGE_BASE] = 10.2, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.43), [Tags.STAT_KNOCKBACK_DAMAGE_BASE] = CONSTANTS.KNOCKBACK_DAMAGE_BASE, [Tags.STAT_KNOCKBACK_DAMAGE_VARIANCE] = CONSTANTS.KNOCKBACK_DAMAGE_VARIANCE })
ITEM:setGrowthMultiplier({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 1.5 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Range %s - Move into an enemy's space, " .. "{C:KEYWORD}Pushing it back {C:NUMBER}1 space. The enemy takes %s damage and skips its turn."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(11, 5)
ABILITY.iconColor = COLORS.STANDARD_STEEL
local function getMoveTo(entity, direction, abilityStats)
    local range = abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local moveTo = entity.body:getPosition()
    for i = 1, range do
        moveTo = moveTo + Vector[direction]
        if not entity.body:isPassable(moveTo) or not entity.vision:isVisible(moveTo) then
            break
        end

    end

    return moveTo
end

ABILITY.getInvalidReason = ActionUtils.getInvalidReasonEnemy
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local entityAt = ActionUtils.indicateEnemyWithinRange(entity, direction, abilityStats, castingGuide, true)
    if entityAt then
        local moveTo = getMoveTo(entity, direction, abilityStats)
        if moveTo then
            castingGuide:indicateMoveTo(moveTo)
            castingGuide:indicate(moveTo)
        end

    end

end
local STEP_DURATION = ACTION_CONSTANTS.WALK_DURATION * 0.65
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("move")
    self:addComponent("charactertrail")
    self.move:setEasingToLinear()
end

function ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    local moveFrom = self.entity.body:getPosition()
    local moveTo = getMoveTo(self.entity, self.direction, self.abilityStats)
    self.charactertrail:start(currentEvent)
    Common.playSFX("DASH", 0.7)
    local initialDistance = moveFrom:distanceManhattan(moveTo) - 1
    if initialDistance > 0 then
        self.move.distance = initialDistance
        self.move:prepare(currentEvent)
        currentEvent = self.move:chainMoveEvent(currentEvent, STEP_DURATION * initialDistance)
    end

    local vDirection = Vector[self.direction]
    local offset = self.entity.offset:createProfile()
    local done = currentEvent:createWaitGroup(1)
    currentEvent:chainProgress(STEP_DURATION / 2, function(progress)
        offset.bodyScrolling = vDirection * progress / 2
    end):chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit(moveTo)
        Common.playSFX("ROCK_SHAKE")
        hit:setKnockback(1, self.direction, STEP_DURATION)
        hit:setKnockbackDamage(self.abilityStats)
        hit.turnSkip = true
        hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        hit:applyToPosition(anchor, moveTo)
        self:shakeScreen(anchor, 2)
        if (not hit.knockback) or hit.knockback.distance == 0 then
            anchor:chainProgress(STEP_DURATION / 2, function(progress)
                offset.bodyScrolling = vDirection * (1 - progress) / 2
            end):chainWaitGroupDone(done)
        else
            self.entity.vision:scan(moveTo)
            self.entity.body:setPosition(moveTo)
            self.entity.triggers:parallelChainPreMove(anchor, moveTo - vDirection, moveTo)
            offset.bodyScrolling = -vDirection / 2
            anchor:chainProgress(STEP_DURATION / 2, function(progress)
                offset.bodyScrolling = -vDirection * (1 - progress) / 2
            end):chainEvent(function(_, anchor)
                self.entity.body:endOfMove(anchor, moveTo - vDirection, moveTo)
            end):chainWaitGroupDone(done)
        end

    end)
    return done:chainEvent(function()
        self.charactertrail:stop()
        self.entity.offset:deleteProfile(offset)
    end)
end

local LEGENDARY = ITEM:createLegendary("Battle Hunger")
LEGENDARY.statLine = "Whenever you kill an enemy with an {C:KEYWORD}Attack, cast this ability " .. "at a random enemy in range for free."
local LEGENDARY_TRIGGER = class(TRIGGERS.ON_ATTACK)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = 12
    self.targetEntity = false
end

function LEGENDARY_TRIGGER:parallelResolve(currentEvent)
    if not self.entity.buffable:canMove() then
        return false
    end

    local entityAt = self.entity.body:getEntityAt(self.attackTarget)
    if ActionUtils.isAliveAgent(entityAt) then
        self.targetEntity = entityAt
    end

end

local CAST_DELAY = 0.2
function LEGENDARY_TRIGGER:process(currentEvent)
    if self.targetEntity and self.targetEntity.tank.hasDiedOnce then
        local directions = DIRECTIONS_AA:shuffle(self:getLogicRNG())
        for direction in directions() do
            local enemy = ActionUtils.getEnemyWithinRange(self.entity, direction, self.abilityStats, true)
            if ActionUtils.isAliveAgent(enemy) then
                local action = self.entity.actor:create(ACTION, direction, self.abilityStats)
                return action:parallelChainEvent(currentEvent:chainProgress(CAST_DELAY))
            end

        end

    end

    return currentEvent
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

