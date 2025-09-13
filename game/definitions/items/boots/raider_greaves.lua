local Vector = require("utils.classes.vector")
local Common = require("common")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local ActionUtils = require("actions.utils")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local TERMS = require("text.terms")
local ITEM = require("structures.item_def"):new("Raider Greaves")
local ABILITY = require("structures.ability_def"):new("Ambush")
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_NOT_IMMUNE)
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(10, 20)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 36, [Tags.STAT_MAX_MANA] = 4, [Tags.STAT_ABILITY_POWER] = 1.65, [Tags.STAT_ABILITY_QUICK] = 1, [Tags.STAT_ABILITY_RANGE] = 2 })
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
local FORMAT = "Move up to %s to a space adjacent to an enemy. {C:KEYWORD}Quick."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE)
end
local REASON_NO_ENEMY = "No adjacent enemy."
local function getMoveTo(entity, direction, abilityStats)
    local range = abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local source = entity.body:getPosition()
    local moveTo = false
    local reason = REASON_NO_ENEMY
    local target = source
    for i = 1, range do
        target = source + Vector[direction] * i
        if not entity.body:isPassable(target) or not entity.vision:isVisible(target) then
            if i == 1 then
                reason = TERMS.INVALID_DIRECTION_BLOCKED
            end

            target = target - Vector[direction]
            break
        end

        for direction in DIRECTIONS_AA() do
            if entity.body:hasEntityWithAgent(target + Vector[direction]) then
                moveTo = target
                break
            end

        end

    end

    if moveTo then
        reason = false
    end

    return moveTo, reason, target
end

ABILITY.icon = Vector:new(12, 2)
ABILITY.iconColor = COLORS.STANDARD_RAGE
ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local _, reason = getMoveTo(entity, direction, abilityStats)
    return reason
end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local moveTo, _, potentialTarget = getMoveTo(entity, direction, abilityStats)
        if moveTo and moveTo ~= entity.body:getPosition() then
        castingGuide:indicateMoveTo(moveTo)
    elseif potentialTarget ~= entity.body:getPosition() then
        castingGuide:indicateMoveTo(potentialTarget)
    end

end
local STEP_DURATION = ACTION_CONSTANTS.WALK_DURATION * 0.5
local ACTION = class(ACTIONS_FRAGMENT.TRAIL_MOVE)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.stepDuration = STEP_DURATION
end

function ACTION:parallelResolve(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    local moveTo = getMoveTo(self.entity, self.direction, self.abilityStats)
    self.distance = self.entity.body:getPosition():distanceManhattan(moveTo)
    return ACTION:super(self, "parallelResolve", currentEvent)
end

local LEGENDARY = ITEM:createLegendary("Invader's March")
local LEGENDARY_EXTRA_LINE = "{C:KEYWORD}Buff %s - Deal %s bonus damage to adjacent targets."
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1, [Tags.STAT_MODIFIER_DAMAGE_BASE] = 8.8, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.8), [Tags.STAT_ABILITY_COOLDOWN] = -1 })
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:decorateOutgoingHit(hit)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        if hit:isDamagePositiveDirect() then
            if hit:getApplyDistance() <= 1 then
                hit.minDamage = hit.minDamage + self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
                hit.maxDamage = hit.maxDamage + self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
                hit:increaseBonusState()
            end

        end

    end

end

return ITEM

