local Vector = require("utils.classes.vector")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ATTACK_WEAPON = require("actions.attack_weapon")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local EASING = require("draw.easing")
local textStatFormat = require("text.stat_format")
local TERMS = require("text.terms")
local ITEM = require("structures.item_def"):new("Spectral Rapier")
local ABILITY = require("structures.ability_def"):new("Spectral Lunge")
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(12, 10)
ITEM.attackClass = ATTACK_WEAPON.STAB_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 18, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.0), [Tags.STAT_LUNGE] = 1, [Tags.STAT_VIRTUAL_RATIO] = 0.58, [Tags.STAT_ABILITY_POWER] = 3.00, [Tags.STAT_ABILITY_DAMAGE_BASE] = 26, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.0), [Tags.STAT_ABILITY_RANGE] = 4 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Move up to %s forward, passing through " .. "obstacles. Deal %s damage along the way."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(8, 2)
ABILITY.iconColor = COLORS.STANDARD_GHOST
ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    if ActionUtils.getUnblockedDashMoveTo(entity, direction, abilityStats) then
        return false
    else
        return TERMS.INVALID_DIRECTION_BLOCKED
    end

end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local moveTo = ActionUtils.getUnblockedDashMoveTo(entity, direction, abilityStats)
    if moveTo then
        castingGuide:indicateMoveTo(moveTo)
        local current = moveTo - Vector[direction]
        local isLegendary = abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0
        while current ~= entity.body:getPosition() do
            castingGuide:indicate(current)
            if isLegendary then
                castingGuide:indicate(current + Vector[cwDirection(direction)])
                castingGuide:indicate(current + Vector[ccwDirection(direction)])
            end

            current = current - Vector[direction]
        end

    end

end
local STEP_DURATION = 0.16
local BRACE_DISTANCE = 0.4
local BRACE_JUMP_HEIGHT = 0.13
local BRACE_DURATION = 0.35
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local GHOST_ACTION = class(ACTION)
local GHOST_COLOR = ABILITY.iconColor
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("tackle")
    self.tackle.braceDistance = BRACE_DISTANCE
    self.tackle.forwardDistance = 0
    self:addComponent("jump")
    self.jump.height = BRACE_JUMP_HEIGHT
    self:addComponent("weaponswing")
    self.weaponswing.angleStart = 0
    self:addComponent("move")
    self.move.interimSkipTriggers = true
    self.move.interimSkipProjectiles = true
    self:addComponent("outline")
    self.outline.color = GHOST_COLOR
    self.outline:setIsFull()
    self.moveTo = false
    self.sourceEntity = false
end

function ACTION:prepare()
    local entity, direction = self.entity, self.direction
    entity.sprite:turnToDirection(self.direction)
    if entity.sprite.layer == Tags.LAYER_CHARACTER and (self.direction == LEFT or self.direction == RIGHT) then
        entity.sprite.layer = Tags.LAYER_ABOVE_EFFECTS
    end

    if not self.moveTo then
        self.moveTo = ActionUtils.getUnblockedDashMoveTo(entity, self.direction, self.abilityStats)
    end

    local moveFrom = Common.getPositionComponent(entity):getPosition()
    self.move.distance = moveFrom:distanceManhattan(self.moveTo)
    self.tackle:createOffset()
    self.weaponswing:createSwingItem()
end

function ACTION:setSpriteOpacity(value)
    self.entity.sprite.opacity = value
end

function ACTION:setDamage(hit)
    hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
end

function ACTION:process(currentEvent)
    self:prepare()
    if not self.sourceEntity then
        self.sourceEntity = self.entity
    end

    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        self:createSideGhosts(currentEvent)
    end

    Common.playSFX("WEAPON_CHARGE")
    self.outline:chainFadeIn(currentEvent, BRACE_DURATION)
    currentEvent:chainProgress(BRACE_DURATION, function(progress)
        self:setSpriteOpacity(1 - progress)
    end)
    self.jump:chainFullEvent(currentEvent, BRACE_DURATION)
    currentEvent = self.tackle:chainBraceEvent(currentEvent, BRACE_DURATION):chainEvent(function()
        self.move:prepare(currentEvent)
        Common.playSFX(self.move:getDashSound(), 3 / self.move.distance)
    end)
    local moveDuration = STEP_DURATION * self.move.distance
    self.weaponswing:chainSwingEvent(currentEvent, moveDuration):chainEvent(function()
        self.weaponswing:deleteSwingItem()
    end)
    self.tackle:chainForwardEvent(currentEvent, moveDuration):chainEvent(function()
        self.tackle:deleteOffset()
    end)
    local fadeoutEvent = currentEvent:chainProgress(STEP_DURATION * (self.move.distance - 1))
    self.outline:chainFadeOut(fadeoutEvent, STEP_DURATION)
    fadeoutEvent:chainProgress(STEP_DURATION, function(progress)
        self:setSpriteOpacity(progress)
    end)
    return self.move:chainMoveEvent(currentEvent, moveDuration, function(anchor, stepFrom, stepTo)
        if stepTo ~= self.moveTo then
            local hit = self.sourceEntity.hitter:createHit(stepTo)
            self:setDamage(hit)
            hit:applyToPosition(anchor, stepTo)
        end

    end)
end

function ACTION:createSideGhost(anchor, offset)
    local ghost = self.entity.sprite:createCharacterCopy()
    local source = self.entity.body:getPosition()
    ghost.position:setPosition(source + offset)
    local action = ghost.actor:create(GHOST_ACTION, self.direction, self.abilityStats)
    action.sourceEntity = self.entity
    action.moveTo = self.moveTo + offset
    action:parallelChainEvent(anchor):chainEvent(function()
        ghost:delete()
    end)
end

function ACTION:createSideGhosts(anchor)
    self:createSideGhost(anchor, Vector[cwDirection(self.direction)])
    self:createSideGhost(anchor, Vector[ccwDirection(self.direction)])
end

function GHOST_ACTION:initialize(entity, direction, abilityStats)
    GHOST_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.moveTo = false
end

function GHOST_ACTION:setDamage(hit)
    GHOST_ACTION:super(self, "setDamage", hit)
end

function GHOST_ACTION:parallelResolve(anchor)
    self.entity.sprite.opacity = 0
end

function GHOST_ACTION:prepare()
    self.weaponswing:setSilhouetteColor(GHOST_COLOR)
    self.weaponswing:setTrailToSubtle()
    GHOST_ACTION:super(self, "prepare")
end

function GHOST_ACTION:createSideGhosts(anchor)
end

function GHOST_ACTION:setSpriteOpacity(value)
end

local LEGENDARY = ITEM:createLegendary("Triumvirate")
LEGENDARY.abilityExtraLine = "Create {C:NUMBER}2 ghostly images at each side that deal the same damage."
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 26 / 6, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.0) })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MAX, Tags.STAT_UPGRADED)
end
return ITEM

