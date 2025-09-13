local Vector = require("utils.classes.vector")
local CONSTANTS = require("logic.constants")
local Common = require("common")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ActionUtils = require("actions.utils")
local COLORS = require("draw.colors")
local EASING = require("draw.easing")
local BUFFS = require("definitions.buffs")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Colossus Helm")
local ABILITY = require("structures.ability_def"):new("Unstoppable Charge")
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_NOT_IMMUNE)
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(8, 13)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 40, [Tags.STAT_ABILITY_POWER] = 5.2, [Tags.STAT_ABILITY_DAMAGE_BASE] = 60.0, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.57), [Tags.STAT_ABILITY_RANGE] = 3, [Tags.STAT_SECONDARY_RANGE] = 1, [Tags.STAT_ABILITY_BUFF_DURATION] = 1, [Tags.STAT_ABILITY_SUSTAIN_MODE] = Tags.SUSTAIN_MODE_AUTOCAST, [Tags.STAT_KNOCKBACK_DAMAGE_BASE] = CONSTANTS.KNOCKBACK_DAMAGE_BASE, [Tags.STAT_KNOCKBACK_DAMAGE_VARIANCE] = CONSTANTS.KNOCKBACK_DAMAGE_VARIANCE })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Focus - Move up to %s forward. Deal %s damage to enemies in " .. "the way and {C:KEYWORD}Push them %s to the side. Objects in the way are destroyed."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_SECONDARY_RANGE)
end
ABILITY.icon = Vector:new(6, 8)
ABILITY.iconColor = COLORS.STANDARD_STEEL
local function getMoveTo(entity, direction, abilityStats)
    local source = entity.body:getPosition()
    local range = abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local vDirection = Vector[direction]
    local target = source
    for i = 1, range do
        target = target + vDirection
        if not entity.vision:isVisible(target) or not entity.body:canBePassable(target) then
            return target - vDirection
        end

        local entityAt = entity.body:getEntityAt(source + Vector[direction] * i)
        if entityAt then
            if entityAt:hasComponent("agent") then
                if (not entity.body:isPassable(target + Vector[cwDirection(direction)])) and (not entity.body:isPassable(target + Vector[ccwDirection(direction)])) then
                    return target - vDirection
                end

            end

        end

    end

    return target
end

ABILITY.getInvalidReason = ActionUtils.getInvalidReasonFrontCantBePassable
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local moveTo = getMoveTo(entity, direction, abilityStats)
    if moveTo ~= entity.body:getPosition() then
        castingGuide:indicateMoveTo(moveTo)
    end

    local source = entity.body:getPosition()
    for i = 1, abilityStats:get(Tags.STAT_ABILITY_RANGE) do
        local target = source + Vector[direction] * i
        if not entity.vision:isVisible(target) then
            break
        end

        castingGuide:indicate(target)
        if target - Vector[direction] == moveTo then
            break
        end

    end

end
local MAIN_ACTION = class("actions.action")
local BUFF = class(BUFFS.FOCUS)
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.mainActionClass = MAIN_ACTION
end

function BUFF:onTurnStart(anchor, entity)
    if not self.action:isValid() then
        entity.equipment:deactivateSlot(anchor, self.abilityStats:get(Tags.STAT_SLOT))
    end

end

function BUFF:onDelete(anchor, entity)
    self.action:deactivate()
end

local BRACE_DISTANCE = 0.4
local BRACE_DURATION = 0.35
local STEP_DURATION = 0.17
function MAIN_ACTION:initialize(entity, direction, abilityStats)
    MAIN_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("tackle")
    self.tackle.braceDistance = BRACE_DISTANCE
    self.tackle.forwardDistance = 0
    self:addComponentAs("tackle", "extratackle")
    self.extratackle.forwardDistance = 0.5
    self.extratackle.forwardEasing = EASING.LINEAR
    self:addComponent("move")
    self.move:setEasingToLinear()
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
    self:addComponent("charactertrail")
end

function MAIN_ACTION:process(currentEvent)
    self.charactertrail:start(currentEvent)
    Common.playSFX("WEAPON_CHARGE")
    self.outline:chainFadeIn(currentEvent, BRACE_DURATION)
    local pushDistance = self.abilityStats:get(Tags.STAT_SECONDARY_RANGE)
    local body = self.entity.body
    local moveTo = getMoveTo(self.entity, self.direction, self.abilityStats)
    if not self.entity.buffable:canMove() then
        moveTo = body:getPosition()
    end

    local entityAtMoveTo = body:getEntityAt(moveTo)
    self.move.distance = body:getPosition():distanceManhattan(moveTo)
    self.tackle:createOffset()
    currentEvent = self.tackle:chainBraceEvent(currentEvent, BRACE_DURATION):chainEvent(function()
        if self.move.distance > 0 then
            self.move:prepare(currentEvent)
        end

    end)
    local moveDuration = max(STEP_DURATION, STEP_DURATION * self.move.distance)
    self.tackle:chainForwardEvent(currentEvent, moveDuration)
    local willExtraTackle = self.abilityStats:get(Tags.STAT_ABILITY_RANGE) > self.move.distance
    willExtraTackle = (willExtraTackle and body:canBePassable(moveTo + Vector[self.direction]))
    willExtraTackle = (willExtraTackle and self.entity.vision:isVisible(moveTo + Vector[self.direction]))
    if not willExtraTackle then
        self.outline:chainFadeOut(currentEvent:chainProgress(moveDuration - STEP_DURATION), STEP_DURATION)
    end

    local previousDirection = choose(self:getLogicRNG():random() < 0.5, cwDirection(self.direction), ccwDirection(self.direction))
    currentEvent:chainEvent(function()
        Common.playSFX("DASH", 0.7)
    end)
    if self.move.distance > 0 then
        currentEvent = self.move:chainMoveEvent(currentEvent, moveDuration, function(anchor, stepFrom, stepTo)
            local entityAt = body:getEntityAt(stepTo)
            if stepTo == moveTo then
                entityAt = entityAtMoveTo
            end

            if entityAt then
                previousDirection = reverseDirection(previousDirection)
                if not body:isPassable(stepTo + Vector[previousDirection]) then
                    previousDirection = reverseDirection(previousDirection)
                end

                if not entityAt:hasComponent("agent") then
                    entityAt.tank:kill(anchor, self.entity)
                    Common.playSFX("ROCK_SHAKE")
                    self:shakeScreen(anchor, 1)
                else
                    local hit = self.entity.hitter:createHit(stepTo)
                    hit:setKnockback(pushDistance, previousDirection, STEP_DURATION)
                    hit:setKnockbackDamage(self.abilityStats)
                    hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
                    hit:applyToEntity(anchor, entityAt)
                    Common.playSFX("ROCK_SHAKE")
                    self:shakeScreen(anchor, 1)
                end

            end

        end)
    end

    if willExtraTackle then
        self.extratackle:createOffset()
        self.outline:chainFadeOut(currentEvent, STEP_DURATION)
        currentEvent = self.extratackle:chainForwardEvent(currentEvent, STEP_DURATION / 2):chainEvent(function(_, anchor)
            local hit = self.entity.hitter:createHit()
            hit:setKnockback(pushDistance, reverseDirection(previousDirection), STEP_DURATION)
            hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
            hit:applyToPosition(anchor, moveTo + Vector[self.direction])
            Common.playSFX("ROCK_SHAKE")
            self:shakeScreen(anchor, 1)
        end)
        currentEvent = self.extratackle:chainBackEvent(currentEvent, STEP_DURATION / 2)
    end

    return currentEvent:chainEvent(function()
        self.tackle:deleteOffset()
        self.charactertrail:stop()
    end)
end

local ACTION = class(ACTIONS_FRAGMENT.GLOW_MODAL)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = COLORS.STANDARD_RAGE
    self.sound = "ENCHANT"
end

function ACTION:deactivate()
end

function ACTION:isValid()
    return not ABILITY.getInvalidReason(self.entity, self.direction, self.abilityStats)
end

local LEGENDARY = ITEM:createLegendary("Helm of the Juggernaut")
LEGENDARY.abilityExtraLine = "You are immune to any effect until this ability is finished casting."
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_RANGE] = 1 })
LEGENDARY.decorateIncomingHit = function(entity, hit, abilityStats)
    local slot = abilityStats:get(Tags.STAT_SLOT)
    if entity.equipment:isSlotActive(slot) and (hit:isDamageOrDebuff() or hit:isDamagePositive()) then
        hit:clear()
        hit.sound = "HIT_BLOCKED"
        hit.forceFlash = true
    end

end
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_RANGE, Tags.STAT_UPGRADED)
end
return ITEM

