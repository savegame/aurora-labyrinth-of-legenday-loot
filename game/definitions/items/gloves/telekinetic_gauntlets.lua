local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local BUFFS = require("definitions.buffs")
local ACTIONS_BASIC = require("actions.basic")
local ACTION_CONSTANTS = require("actions.constants")
local ActionUtils = require("actions.utils")
local COLORS = require("draw.colors")
local EASING = require("draw.easing")
local textStatFormat = require("text.stat_format")
local TERMS = require("text.terms")
local ITEM = require("structures.item_def"):new("Telekinetic Gauntlets")
local ABILITY = require("structures.ability_def"):new("Telekinetic Pull")
ABILITY:addTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_PLUS_BASIC_ATTACK)
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(9, 20)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 32, [Tags.STAT_MAX_MANA] = 8, [Tags.STAT_ABILITY_POWER] = 2.1, [Tags.STAT_ABILITY_DAMAGE_BASE] = 11.0, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.28), [Tags.STAT_ABILITY_RANGE_MIN] = 2, [Tags.STAT_ABILITY_RANGE_MAX] = 3 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE_MAX] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE_MAX] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Range %s - Pull the target towards an adjacent space and " .. "{C:KEYWORD}Attack it, dealing %s bonus damage"
local FORMAT_LEGENDARY = " {B:STAT_LINE}for every space it traveled."
ABILITY.getDescription = function(item)
    if item.stats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        return textStatFormat(FORMAT .. FORMAT_LEGENDARY, item, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_ABILITY_DAMAGE_MIN)
    else
        return textStatFormat(FORMAT .. ".", item, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_ABILITY_DAMAGE_MIN)
    end

end
local TEXT_CANT_PULL = "Target cannot be pulled"
ABILITY.icon = Vector:new(5, 9)
ABILITY.iconColor = COLORS.STANDARD_PSYCHIC
ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local target = ActionUtils.getTargetWithinRange(entity, direction, abilityStats)
    if not target then
        return TERMS.INVALID_DIRECTION_NO_TARGET
    end

    if target.body.cantBeMoved then
        return TEXT_CANT_PULL
    else
        return false
    end

end
ABILITY.indicate = ActionUtils.indicateTargetWithinRange
local KNOCKBACK_STEP_DURATION = 0.1
local FADE_DURATION = ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION
local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local LIFT_HEIGHT = 0.3
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
    self:addComponentAs("outline", "targetoutline")
    self.targetoutline.color = ABILITY.iconColor
end

function ACTION:process(currentEvent)
    local done = currentEvent:createWaitGroup(1)
    self.entity.sprite:turnToDirection(self.direction)
    local range = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local targetEntity = ActionUtils.getTargetWithinRange(self.entity, self.direction, self.abilityStats)
    local pullRange = targetEntity.body:getPosition():distanceManhattan(self.entity.body:getPosition()) - 1
    self.targetoutline:setEntity(targetEntity)
    self.targetoutline:chainFadeIn(currentEvent, FADE_DURATION)
    Common.playSFX("CAST_CHARGE")
    currentEvent = self.outline:chainFadeIn(currentEvent, FADE_DURATION):chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit()
        hit.sound = false
        hit:setKnockback(pullRange, reverseDirection(self.direction), KNOCKBACK_STEP_DURATION, false, true)
        hit:applyToEntity(anchor, targetEntity)
        pullRange = min(pullRange, hit.knockback.distance + 1)
        anchor = anchor:chainProgress(KNOCKBACK_STEP_DURATION * (pullRange - 1))
        local resolvedDistance = hit.knockback.distance
        if resolvedDistance == pullRange then
            local attackAction = self.entity.melee:createAction(self.direction)
            attackAction:parallelResolve(anchor)
            local minDamage = self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN)
            local maxDamage = self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX)
            if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
                minDamage = minDamage * resolvedDistance
                maxDamage = maxDamage * resolvedDistance
            end

            attackAction.baseAttack:setBonus(minDamage, maxDamage)
            anchor = attackAction:chainEvent(anchor)
        end

        self.outline:chainFadeOut(anchor, FADE_DURATION)
        self.targetoutline:chainFadeOut(anchor, FADE_DURATION)
        anchor:chainWaitGroupDone(done)
    end)
    return done
end

local LEGENDARY = ITEM:createLegendary("Inescapable Grasp")
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_RANGE_MAX] = 1 })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_RANGE_MAX, Tags.STAT_UPGRADED)
end
return ITEM

