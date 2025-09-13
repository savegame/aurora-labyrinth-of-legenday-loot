local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local BUFFS = require("definitions.buffs")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local ActionUtils = require("actions.utils")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Sky Treads")
local ABILITY = require("structures.ability_def"):new("Leap")
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_DISENGAGE_MELEE)
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(13, 14)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 20, [Tags.STAT_MAX_MANA] = 20, [Tags.STAT_ABILITY_POWER] = 1.5, [Tags.STAT_ABILITY_RANGE] = 3, [Tags.STAT_ABILITY_BUFF_DURATION] = 1, [Tags.STAT_ABILITY_SUSTAIN_MODE] = Tags.SUSTAIN_MODE_AUTOCAST, [Tags.STAT_SECONDARY_RANGE] = 1, [Tags.STAT_KNOCKBACK_DAMAGE_BASE] = CONSTANTS.KNOCKBACK_DAMAGE_BASE, [Tags.STAT_KNOCKBACK_DAMAGE_VARIANCE] = CONSTANTS.KNOCKBACK_DAMAGE_VARIANCE })
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
local FORMAT = "{C:KEYWORD}Focus - "
local FORMAT_LEGENDARY = "{B:STAT_LINE}Deal %s damage to all enemies around " .. "you, {B:NORMAL}then l"
local FORMAT_END = "eap up to %s forward. {C:KEYWORD}Push " .. "all adjacent enemies %s upon landing."
ABILITY.getDescription = function(item)
    local description = FORMAT
    if item.stats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        description = description .. textStatFormat(FORMAT_LEGENDARY, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
    else
        description = description .. "L"
    end

    return description .. textStatFormat(FORMAT_END, item, Tags.STAT_ABILITY_RANGE, Tags.STAT_SECONDARY_RANGE)
end
ABILITY.icon = Vector:new(9, 9)
ABILITY.iconColor = COLORS.STANDARD_WIND
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
    end

    if abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        local area = abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
        local position = entity.body:getPosition()
        ActionUtils.indicateArea(entity, entity.body:getPosition(), area, castingGuide)
        castingGuide:unindicate(entity.body:getPosition())
    end

end
local MAIN_ACTION = class(ACTIONS_FRAGMENT.TRAIL_MOVE)
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

local STEP_DURATION = ACTION_CONSTANTS.WALK_DURATION * 0.55
local KNOCKBACK_STEP_DURATION = 0.1
local JUMP_HEIGHT = 1.5
local EXPLOSION_DURATION = 0.6
local EXPLOSION_SHAKE_INTENSITY = 1.5
function MAIN_ACTION:initialize(entity, direction, abilityStats)
    MAIN_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.stepDuration = STEP_DURATION
    self.move.interimSkipTriggers = true
    self.move.interimSkipProjectiles = true
    self.move:setEasingToLinear()
    self:setJumpHeight(JUMP_HEIGHT)
    self.moveFrom = false
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        self:addComponent("explosion")
        self.explosion.excludeSelf = true
        self.explosion:setHueToFire()
        self.explosion.shakeIntensity = EXPLOSION_SHAKE_INTENSITY
    end

end

function MAIN_ACTION:parallelResolve(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    self.moveFrom = self.entity.body:getPosition()
    local moveTo = ActionUtils.getUnblockedDashMoveTo(self.entity, self.direction, self.abilityStats)
    if not moveTo then
        self.distance = 0
    else
        self.distance = self.entity.body:getPosition():distanceManhattan(moveTo)
    end

    return MAIN_ACTION:super(self, "parallelResolve", currentEvent)
end

function MAIN_ACTION:process(currentEvent)
    self.entity.sprite.layer = Tags.LAYER_FLYING
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        self.explosion.source = self.moveFrom
        Common.playSFX("EXPLOSION_MEDIUM")
        self.explosion:chainFullEvent(currentEvent, EXPLOSION_DURATION, function(anchor, position)
            local hit = self.entity.hitter:createHit(self.moveFrom)
            hit:setDamageFromModifierStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
            hit:applyToPosition(anchor, position)
        end)
    end

    if self.distance == 0 then
        return currentEvent:chainEvent(function()
            self.entity.sprite:resetLayer()
        end)
    end

    return MAIN_ACTION:super(self, "process", currentEvent):chainEvent(function(_, anchor)
        self.entity.sprite:resetLayer()
        local pushDistance = self.abilityStats:get(Tags.STAT_SECONDARY_RANGE)
        Common.playSFX("ROCK_SHAKE")
        for direction in DIRECTIONS_AA() do
            local hit = self.entity.hitter:createHit()
            hit:setKnockback(pushDistance, direction, KNOCKBACK_STEP_DURATION)
            hit:setKnockbackDamage(self.abilityStats)
            hit:applyToPosition(anchor, self.entity.body:getPosition() + Vector[direction])
        end

        return self:shakeScreen(anchor, 2)
    end)
end

local ACTION = class(ACTIONS_FRAGMENT.GLOW_MODAL)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = COLORS.STANDARD_RAGE
    self.sound = "ENCHANT"
end

function ACTION:isValid()
    return (ActionUtils.getUnblockedDashMoveTo(self.entity, self.direction, self.abilityStats) ~= self.entity.body:getPosition()) and self.entity.buffable:canMove()
end

local LEGENDARY = ITEM:createLegendary("Blast Off!")
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_3X3, [Tags.STAT_MODIFIER_DAMAGE_BASE] = 22.4, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.75) })
LEGENDARY.strokeColor = COLORS.STANDARD_FIRE
return ITEM

