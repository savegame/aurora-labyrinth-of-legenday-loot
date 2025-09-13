local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ATTACK_UNARMED = require("actions.attack_unarmed")
local PLAYER_COMMON = require("actions.player_common")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Hightail Boots")
local ABILITY = require("structures.ability_def"):new("Disengage")
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_DISENGAGE_MELEE)
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_NOT_IMMUNE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(19, 14)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 8, [Tags.STAT_MAX_MANA] = 32, [Tags.STAT_ABILITY_POWER] = 1.5, [Tags.STAT_ABILITY_RANGE] = 1, [Tags.STAT_SECONDARY_RANGE] = 1, [Tags.STAT_KNOCKBACK_DAMAGE_BASE] = CONSTANTS.KNOCKBACK_DAMAGE_BASE, [Tags.STAT_KNOCKBACK_DAMAGE_VARIANCE] = CONSTANTS.KNOCKBACK_DAMAGE_VARIANCE })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Push an adjacent enemy %s and move backwards %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_SECONDARY_RANGE, Tags.STAT_ABILITY_RANGE)
end
ABILITY.icon = Vector:new(10, 2)
ABILITY.iconColor = COLORS.STANDARD_WIND
ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local forIndicate = abilityStats:clone()
    forIndicate:set(Tags.STAT_ABILITY_RANGE, 1)
    return ActionUtils.getInvalidReasonEnemy(entity, direction, forIndicate)
end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local forIndicate = abilityStats:clone()
    forIndicate:set(Tags.STAT_ABILITY_RANGE, 1)
    ActionUtils.indicateEnemyWithinRange(entity, direction, forIndicate, castingGuide)
    if entity.buffable:canMove() then
        local moveTo = ActionUtils.getDashMoveTo(entity, reverseDirection(direction), abilityStats)
        if moveTo and moveTo ~= entity.body:getPosition() then
            castingGuide:indicateMoveTo(moveTo)
        end

    end

end
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local STEP_DURATION = 0.15
local EXPLODE_DURATION = 0.4
local SPEED_MULTIPLIER = 1.43
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("move")
    self.move:setEasingToLinear()
    self:addComponent("charactertrail")
    self:addComponent("explosion")
    self.explosion:setArea(Tags.ABILITY_AREA_SINGLE)
    self.explosion:setHueToPoison()
end

function ACTION:process(currentEvent)
    local entity = self.entity
    self.explosion.source = entity.body:getPosition() + Vector[self.direction] / 2
    Common.playSFX("EXPLOSION_SMALL", 2.1)
    self.explosion:chainFullEvent(currentEvent, EXPLODE_DURATION)
    local moveDistance = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local pushDistance = self.abilityStats:get(Tags.STAT_SECONDARY_RANGE)
    local hit = entity.hitter:createHit()
    hit:setKnockback(pushDistance, self.direction, STEP_DURATION)
    hit:setKnockbackDamage(self.abilityStats)
    hit:applyToPosition(currentEvent, entity.body:getPosition() + Vector[self.direction])
    local moveTo = ActionUtils.getDashMoveTo(entity, reverseDirection(self.direction), self.abilityStats)
    self.move.distance = entity.body:getPosition():distanceManhattan(moveTo)
    if self.move.distance > 0 and entity.buffable:canMove() then
        Common.playSFX("DASH_SHORT")
        self.charactertrail:start(currentEvent)
        self.move.direction = reverseDirection(self.direction)
        self.move:prepare(currentEvent)
        currentEvent = self.move:chainMoveEvent(currentEvent, moveDistance * STEP_DURATION):chainEvent(function()
            self.charactertrail:stop()
        end)
    end

    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("The Jester's Path")
local LEGENDARY_EXTRA_LINE = "{C:KEYWORD}Buff %s - Deal %s bonus damage to targets at least %s away."
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1, [Tags.STAT_MODIFIER_RANGE] = 3, [Tags.STAT_MODIFIER_DAMAGE_BASE] = 14.2, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.55), [Tags.STAT_MODIFIER_VALUE] = 2, [Tags.STAT_ABILITY_COOLDOWN] = -1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_MODIFIER_DAMAGE_MIN, Tags.STAT_MODIFIER_RANGE)
end
local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:decorateOutgoingHit(hit)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        if hit:isDamagePositiveDirect() then
            local range = self.abilityStats:get(Tags.STAT_MODIFIER_RANGE)
            if hit:getApplyDistance() >= 3 then
                hit.minDamage = hit.minDamage + self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
                hit.maxDamage = hit.maxDamage + self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
                hit:increaseBonusState()
            end

        end

    end

end

return ITEM

