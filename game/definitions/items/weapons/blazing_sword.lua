local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Common = require("common")
local COLORS = require("draw.colors")
local BUFFS = require("definitions.buffs")
local ACTION_CONSTANTS = require("actions.constants")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Blazing Sword")
local ABILITY = require("structures.ability_def"):new("Fire Wave")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(7, 10)
ITEM.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 19.8, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.35), [Tags.STAT_VIRTUAL_RATIO] = 0.68, [Tags.STAT_ABILITY_POWER] = 3.73, [Tags.STAT_ABILITY_DAMAGE_BASE] = 19.8, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.7), [Tags.STAT_SECONDARY_DAMAGE_BASE] = 19.8 / 2, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.7), [Tags.STAT_ABILITY_BURN_DURATION] = 3, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_3X3 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Deal %s damage to a %s. {FORCE_NEWLINE} {C:KEYWORD}Burn - %s health lost per turn. " .. "Every turn, the {C:KEYWORD}Burn area moves forward {C:NUMBER}1 space and deals %s damage to the newly affected spaces."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_AREA_ROUND, Tags.STAT_SECONDARY_DAMAGE_MIN, Tags.STAT_ABILITY_DAMAGE_MIN)
end
local FIRE_SIZE = 3
ABILITY.icon = Vector:new(7, 4)
ABILITY.iconColor = COLORS.STANDARD_FIRE
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local source = entity.body:getPosition()
    local positions = ActionUtils.getCleavePositions(source, FIRE_SIZE, direction)
    local distance = 0
    local vDirection = Vector[direction]
    while not positions:isEmpty() do
        distance = distance + 1
        for i = 1, positions:size() do
            if entity.body:canBePassable(positions[i]) and entity.vision:isVisible(positions[i]) then
                if distance <= FIRE_SIZE then
                    castingGuide:indicate(positions[i])
                else
                    castingGuide:indicateWeak(positions[i])
                end

                positions[i] = positions[i] + vDirection
            else
                positions[i] = false
            end

        end

        positions:acceptSelf(returnSelf)
    end

end
local BUFF = BUFFS:define("FIRE_WAVE_CONTROLLER")
function BUFF:initialize(duration, direction, abilityStats,...)
    BUFF:super(self, "initialize", duration)
    self.direction = direction
    self.abilityStats = abilityStats
    self.positions = Array:new(...)
end

function BUFF:getDataArgs()
    return self.duration, self.direction, self.abilityStats, self.positions:expand()
end

function BUFF:onTurnStart(anchor, entity)
    self:applyToNextRow(anchor, entity, FIRE_SIZE)
    if self.positions:isEmpty() then
        self.duration = 0
    end

end

function BUFF:applyToNextRow(anchor, entity, duration)
    local vDirection = Vector[self.direction]
    for i = 1, self.positions:size() do
        if entity.body:canBePassable(self.positions[i]) then
            local thisPosition = self.positions[i]
            anchor:chainEvent(function(_, anchor)
                local hit = entity.hitter:createHit()
                hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
                hit:setSpawnFire(duration, self.abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MIN), self.abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MAX))
                hit:applyToPosition(anchor, thisPosition)
                Common.playSFX("BURN_DAMAGE", 1, 1.4)
            end)
            self.positions[i] = thisPosition + vDirection
        else
            self.positions[i] = false
        end

    end

    self.positions:acceptSelf(returnSelf)
end

function BUFF:shouldCombine(oldBuff)
    return false
end

local ACTION = class(ACTIONS_FRAGMENT.CAST)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self:speedMultiply(ACTION_CONSTANTS.SLOW_CAST_MULTIPLIER)
    self.chargeSound = "WEAPON_CHARGE"
    self.swingSound = "WHOOSH_MAGIC"
end

local EFFECT_GAP = ACTION_CONSTANTS.WALK_DURATION
local DURATION = 30 - 1
function ACTION:process(currentEvent)
    currentEvent = ACTION:super(self, "process", currentEvent)
    local positions = ActionUtils.getCleavePositions(self.entity.body:getPosition(), FIRE_SIZE, self.direction)
    local buff = BUFF:new(DURATION, self.direction, self.abilityStats, positions:expand())
    self.entity.buffable:apply(buff)
    for distance = 1, FIRE_SIZE do
        buff:applyToNextRow(currentEvent, self.entity, distance)
        currentEvent = currentEvent:chainProgress(EFFECT_GAP)
    end

    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Pyroclasm")
local LEGENDARY_STAT_LINE = "Targets lose %s more health every turn from your {C:KEYWORD}Burn effects."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 4.8, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.69) })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
LEGENDARY.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositive() and hit.damageType == Tags.DAMAGE_TYPE_BURN then
        hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
        hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
        hit:increaseBonusState()
    end

end
return ITEM

