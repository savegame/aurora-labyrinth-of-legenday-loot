local Vector = require("utils.classes.vector")
local CONSTANTS = require("logic.constants")
local Common = require("common")
local ATTACK_WEAPON = require("actions.attack_weapon")
local TRIGGERS = require("actions.triggers")
local ActionUtils = require("actions.utils")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Titan Hammer")
local ABILITY = require("structures.ability_def"):new("Titanic Smash")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ABILITY:addTag(Tags.ABILITY_TAG_DISENGAGE_MELEE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(12, 8)
ITEM.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 20.75, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.8), [Tags.STAT_VIRTUAL_RATIO] = 0.16, [Tags.STAT_ABILITY_POWER] = 3.55, [Tags.STAT_ABILITY_DAMAGE_BASE] = 16, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.87), [Tags.STAT_SECONDARY_DAMAGE_BASE] = 41.25, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.8), [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_3X3, [Tags.STAT_ABILITY_RANGE] = 1, [Tags.STAT_KNOCKBACK_DAMAGE_BASE] = CONSTANTS.KNOCKBACK_DAMAGE_BASE, [Tags.STAT_KNOCKBACK_DAMAGE_VARIANCE] = CONSTANTS.KNOCKBACK_DAMAGE_VARIANCE })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
local FORMAT = "Deal %s damage to an adjacent space. Deal %s damage and {C:KEYWORD}Push everything around target %s away."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_SECONDARY_DAMAGE_MIN, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_RANGE)
end
ABILITY.icon = Vector:new(4, 8)
ABILITY.iconColor = COLORS.STANDARD_EARTH
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonFrontCantBePassable
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local origin = entity.body:getPosition() + Vector[direction]
    if entity.body:canBePassable(origin) then
        ActionUtils.indicateArea(entity, origin, abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND), castingGuide)
        castingGuide:unindicate(entity.body:getPosition())
    end

end
local SWING_BRACE_DURATION = 0.6
local SWING_BRACE_DISTANCE = 0.4
local SWING_MOVE_DISTANCE = 0.35
local SWING_JUMP_HEIGHT = 0.6
local SWING_MOVE_DURATION = 0.4
local SWING_BACK_DURATION = 0.1
local SWING_HOLD_DURATION = 0.3
local EXPLOSION_SHAKE_INTENSITY = 5
local PUSH_DELAY = 0.06
local KNOCKBACK_STEP_DURATION = 0.12
local ACTION = class(ATTACK_WEAPON.SWING)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self:addComponent("charactertrail")
    self.outline.color = ABILITY.iconColor
    self.tackle.braceDistance = SWING_BRACE_DISTANCE
    self.braceDuration = SWING_BRACE_DURATION
    self.tackle.forwardDistance = SWING_MOVE_DISTANCE
    self.swingDuration = SWING_MOVE_DURATION
    self.jump.height = SWING_JUMP_HEIGHT
    self.backDuration = SWING_BACK_DURATION
    self.holdDuration = SWING_HOLD_DURATION
    self.swingSound = "WHOOSH_BIG"
    self.mainHit = false
end

function ACTION:prepare()
    ACTION:super(self, "prepare")
    self.weaponswing.swingItem.originOffset = 0.05
end

function ACTION:chainBraceEvent(currentEvent)
    Common.playSFX("WEAPON_CHARGE")
    self.outline:chainFadeIn(currentEvent, self.braceDuration)
    return ACTION:super(self, "chainBraceEvent", currentEvent):chainEvent(function(_, anchor)
        self.charactertrail:start(anchor)
    end)
end

function ACTION:getMainHit()
    if self.mainHit then
        return self.mainHit
    else
        local hit = self.entity.hitter:createHit()
        hit:setDamageFromSecondaryStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        return hit
    end

end

function ACTION:chainMainSwingEvent(currentEvent)
    currentEvent = ACTION:super(self, "chainMainSwingEvent", currentEvent)
    local source = self.entity.body:getPosition()
    local origin = source + Vector[self.direction]
    currentEvent:chainEvent(function(_, anchor)
        self.charactertrail:stop()
        self:shakeScreen(anchor, EXPLOSION_SHAKE_INTENSITY)
        Common.playSFX("ROCK_SHAKE")
        local hit = self:getMainHit()
        hit:applyToPosition(anchor, origin)
    end)
    currentEvent:chainProgress(PUSH_DELAY):chainEvent(function(_, anchor)
        local area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
        local range = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
        local diagonalRange = round(range / math.sqrtOf2)
        local positions = ActionUtils.getAreaPositions(self.entity, origin, area, true)
        for position in positions() do
            if position ~= source then
                local direction = Common.getDirectionTowards(origin, position, false, true)
                local hit = self.entity.hitter:createHit()
                hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
                if isDiagonal(direction) then
                    hit:setKnockback(diagonalRange, direction, KNOCKBACK_STEP_DURATION * math.sqrtOf2)
                else
                    hit:setKnockback(range, direction, KNOCKBACK_STEP_DURATION)
                end

                hit:setKnockbackDamage(self.abilityStats)
                hit:applyToPosition(anchor, position)
            end

        end

    end)
    return currentEvent
end

function ACTION:chainHoldEvent(currentEvent)
    self.outline:chainFadeOut(currentEvent, self.holdDuration)
    return ACTION:super(self, "chainHoldEvent", currentEvent)
end

local LEGENDARY = ITEM:createLegendary("World Shatterer")
LEGENDARY.statLine = "{C:KEYWORD}Chance on {C:KEYWORD}Attack to instead cast this ability for free."
local LEGENDARY_ATTACK = class("actions.base_attack")
function LEGENDARY_ATTACK:initialize(entity, direction, abilityStats)
    LEGENDARY_ATTACK:super(self, "initialize", entity, direction, abilityStats)
end

function LEGENDARY_ATTACK:speedMultiply()
end

function LEGENDARY_ATTACK:getAttackDamage()
    local minDamage = self.abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MIN)
    local maxDamage = self.abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MAX)
    return minDamage, maxDamage
end

function LEGENDARY_ATTACK:process(currentEvent)
    local action = self.entity.actor:create(ACTION, self.direction, self.abilityStats)
    action.mainHit = self:createHit()
    return action:parallelChainEvent(currentEvent)
end

LEGENDARY.modifyItem = function(item)
    rawset(item, "getAttackClass", function(item, entity)
        if entity.playertriggers.proccingSlot == ITEM.slot then
            entity.playertriggers:rerollProccingSlot()
            return LEGENDARY_ATTACK
        else
            return ITEM.attackClass
        end

    end)
end
return ITEM

