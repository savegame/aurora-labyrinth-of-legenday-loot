local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Ember Greaves")
local ABILITY = require("structures.ability_def"):new("Fire Dash")
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_NOT_IMMUNE)
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(10, 21)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 28, [Tags.STAT_MAX_MANA] = 12, [Tags.STAT_ABILITY_POWER] = 2.62, [Tags.STAT_ABILITY_RANGE] = 2, [Tags.STAT_ABILITY_BURN_DURATION] = 3, [Tags.STAT_SECONDARY_DAMAGE_BASE] = 10.8, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.74) })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BURN_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BURN_DURATION] = 1 })
local FORMAT = "Move up to %s. {C:KEYWORD}Burn the spaces you previously occupied. {FORCE_NEWLINE} %s, %s health lost per turn. "
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE, Tags.STAT_ABILITY_BURN_DURATION, Tags.STAT_SECONDARY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(11, 10)
ABILITY.iconColor = COLORS.STANDARD_FIRE
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonFrontIsNotPassable
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local moveTo = ActionUtils.getDashMoveTo(entity, direction, abilityStats)
    if moveTo and moveTo ~= entity.body:getPosition() then
        castingGuide:indicateMoveTo(moveTo)
        local target = entity.body:getPosition()
        while target ~= moveTo do
            castingGuide:indicate(target)
            target = target + Vector[direction]
        end

    end

end
local STEP_DURATION = ACTION_CONSTANTS.WALK_DURATION * 0.6
local ACTION = class(ACTIONS_FRAGMENT.TRAIL_MOVE)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.stepDuration = STEP_DURATION
    self.moveFrom = false
end

function ACTION:parallelResolve(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    self.moveFrom = self.entity.body:getPosition()
    local moveTo = ActionUtils.getDashMoveTo(self.entity, self.direction, self.abilityStats)
    self.distance = self.entity.body:getPosition():distanceManhattan(moveTo)
    return ACTION:super(self, "parallelResolve", currentEvent)
end

function ACTION:process(currentEvent)
    self.preStep = function(anchor, moveFrom, moveTo)
        local hit = self.entity.hitter:createHit()
        hit:setSpawnFireFromSecondary(self.abilityStats)
        hit:applyToPosition(anchor, moveFrom)
    end
    Common.playSFX("BURN_DAMAGE", 0.75)
    return ACTION:super(self, "process", currentEvent)
end

local LEGENDARY = ITEM:createLegendary("Trailblazer")
LEGENDARY.statLine = "Immune to {C:KEYWORD}Burn health loss. Your first step onto a {C:KEYWORD}Burn " .. "space every turn is {C:KEYWORD}Quick."
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_RANGE] = 1, [Tags.STAT_ABILITY_BURN_DURATION] = 1 })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_RANGE, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ABILITY_BURN_DURATION, Tags.STAT_UPGRADED)
end
LEGENDARY.decorateIncomingHit = function(entity, hit, abilityStats)
    if hit.damageType == Tags.DAMAGE_TYPE_BURN then
        hit.sound = false
        hit:clear()
    end

end
local QUICK_STEP_DISABLE = BUFFS:define("QUICK_STEP_DISABLE")
function QUICK_STEP_DISABLE:initialize(duration)
    QUICK_STEP_DISABLE:super(self, "initialize", duration)
    self.expiresAtStart = true
end

LEGENDARY.decorateBasicMove = function(entity, action, abilityStats)
    if not entity.buffable:isAffectedBy(QUICK_STEP_DISABLE) then
        local target = entity.body:getPosition() + Vector[action.direction]
        if entity.body:hasSteppableExclusivity(target, Tags.STEP_EXCLUSIVE_ENGULF) then
            action:setToQuick()
            entity.buffable:apply(QUICK_STEP_DISABLE:new(1))
        end

    end

end
return ITEM

