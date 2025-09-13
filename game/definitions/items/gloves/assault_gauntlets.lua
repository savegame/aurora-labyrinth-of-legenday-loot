local Vector = require("utils.classes.vector")
local Set = require("utils.classes.set")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ACTION_CONSTANTS = require("actions.constants")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ActionUtils = require("actions.utils")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local TERMS = require("text.terms")
local ITEM = require("structures.item_def"):new("Assault Gauntlets")
local ABILITY = require("structures.ability_def"):new("Assault")
ABILITY:addTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_PLUS_BASIC_ATTACK)
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_NOT_IMMUNE)
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(6, 12)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 40, [Tags.STAT_ABILITY_POWER] = 2.25, [Tags.STAT_ABILITY_RANGE] = 3, [Tags.STAT_ABILITY_RANGE_MIN] = 2, [Tags.STAT_ABILITY_DAMAGE_BASE] = 15, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.44) })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Range %s - Move to a space adjacent to an enemy and " .. "{C:KEYWORD}Attack it, dealing %s bonus damage."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(9, 2)
ABILITY.iconColor = COLORS.STANDARD_STEEL
ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local reason = ActionUtils.getInvalidReasonEnemy(entity, direction, abilityStats, true)
    if reason == TERMS.INVALID_DIRECTION_BLOCKED then
        return "Must move at least 1 space"
    else
        return reason
    end

end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local entityAt = ActionUtils.indicateEnemyWithinRange(entity, direction, abilityStats, castingGuide, true)
    if entityAt then
        local moveTo = entityAt.body:getPosition() - Vector[direction]
        castingGuide:indicateMoveTo(moveTo)
    end

end
local STEP_DURATION = ACTION_CONSTANTS.WALK_DURATION * 0.7
local ACTION = class(ACTIONS_FRAGMENT.TRAIL_MOVE)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.stepDuration = STEP_DURATION
    self.targetsHit = Set:new()
end

function ACTION:parallelResolve(currentEvent)
    local moveTo = ActionUtils.getDashMoveTo(self.entity, self.direction, self.abilityStats)
    self.distance = moveTo:distanceManhattan(self.entity.body:getPosition())
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        local entityAt = self.entity.body:getEntityAt(moveTo + Vector[self.direction])
        if entityAt then
            self.targetsHit:add(entityAt)
        end

    end

    ACTION:super(self, "parallelResolve", currentEvent)
end

local CHAIN_DELAY = 0.165
function ACTION:process(currentEvent)
    local entity = self.entity
    ACTION:super(self, "process", currentEvent)
    if self.distance >= 2 then
        currentEvent = currentEvent:chainProgress(STEP_DURATION * (self.distance - 1.5))
    end

    local attackAction = self.entity.melee:createAction(self.direction)
    attackAction:parallelResolve(currentEvent)
    attackAction.baseAttack:setBonusFromAbilityStats(self.abilityStats)
    currentEvent = attackAction:chainEvent(currentEvent)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        local directions = DIRECTIONS_AA:shuffle(self:getLogicRNG())
        for direction in directions() do
            local enemy = ActionUtils.getEnemyWithinRange(entity, direction, self.abilityStats, true)
            if enemy and not self.targetsHit:contains(enemy) then
                currentEvent = currentEvent:chainProgress(CHAIN_DELAY)
                local done = currentEvent:createWaitGroup(1)
                currentEvent:chainEvent(function(_, anchor)
                    if ActionUtils.getEnemyWithinRange(entity, direction, self.abilityStats, true) then
                        local chainAction = entity.actor:create(ACTION, direction, self.abilityStats)
                        chainAction.targetsHit = self.targetsHit
                        anchor = chainAction:parallelChainEvent(anchor)
                    end

                    anchor:chainWaitGroupDone(done)
                end)
                return done
            end

        end

    end

    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Omnislash")
LEGENDARY.abilityExtraLine = "Repeatedly recast this ability on a different random enemy in range."
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_COOLDOWN] = -5 })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_COOLDOWN, Tags.STAT_UPGRADED)
end
return ITEM

