local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Incinerating Gloves")
local ABILITY = require("structures.ability_def"):new("Fire Wall")
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(7, 16)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 4, [Tags.STAT_MAX_MANA] = 36, [Tags.STAT_ABILITY_POWER] = 3.27, [Tags.STAT_ABILITY_DAMAGE_BASE] = 10.4, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.72), [Tags.STAT_SECONDARY_DAMAGE_BASE] = 10.4, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.72), [Tags.STAT_ABILITY_BURN_DURATION] = 4, [Tags.STAT_ABILITY_RANGE_MIN] = 2, [Tags.STAT_ABILITY_RANGE_MAX] = 3, [Tags.STAT_ABILITY_AREA_OTHER] = 5 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BURN_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BURN_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Deal %s damage to an area %s spaces wide and %s spaces from you. {FORCE_NEWLINE} " .. "%s, %s health lost per turn."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_AREA_OTHER, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_ABILITY_BURN_DURATION, Tags.STAT_SECONDARY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(3, 7)
ABILITY.iconColor = COLORS.STANDARD_FIRE
ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local source = entity.body:getPosition()
    local rangeMin = abilityStats:get(Tags.STAT_ABILITY_RANGE_MIN)
    for i = 1, rangeMin do
        if not entity.body:canBePassable(source + Vector[direction] * i) then
            return TERMS.INVALID_DIRECTION_BLOCKED
        end

    end

    return false
end
local function getLineArea(entity, direction, range, area)
    local source = entity.body:getPosition() + Vector[direction] * range
    local result = Array:new()
    if entity.body:canBePassable(source) then
        result:push(source)
    else
        return result
    end

    local radius = floor((area - 1) / 2)
    for vDir in Array:new(Vector[ccwDirection(direction)], Vector[cwDirection(direction)])() do
        for i = 1, radius do
            local target = source + vDir * i
            if entity.body:canBePassable(target) then
                result:push(target)
            else
                break
            end

        end

    end

    return result
end

ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    if not ABILITY.getInvalidReason(entity, direction, abilityStats) then
        local rangeMin = abilityStats:get(Tags.STAT_ABILITY_RANGE_MIN)
        local rangeMax = abilityStats:get(Tags.STAT_ABILITY_RANGE_MAX)
        local area = abilityStats:get(Tags.STAT_ABILITY_AREA_OTHER)
        for i = rangeMin, rangeMax do
            local positions = getLineArea(entity, direction, i, area)
            for position in positions() do
                if entity.vision:isVisible(position) then
                    castingGuide:indicate(position)
                end

            end

        end

    end

end
local ACTION = class(ACTIONS_FRAGMENT.CAST)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = COLORS.STANDARD_FIRE
    self:speedMultiply(ACTION_CONSTANTS.MEDIUM_CAST_MULTIPLIER)
end

local SPREAD_DELAY = 0.24
function ACTION:process(currentEvent)
    currentEvent = ACTION:super(self, "process", currentEvent)
    local abilityStats = self.abilityStats
    local rangeMin = abilityStats:get(Tags.STAT_ABILITY_RANGE_MIN)
    local rangeMax = abilityStats:get(Tags.STAT_ABILITY_RANGE_MAX)
    local area = abilityStats:get(Tags.STAT_ABILITY_AREA_OTHER)
    local positions = Array:new()
    for i = rangeMin, rangeMax do
        positions:concat(getLineArea(self.entity, self.direction, i, area))
    end

    local source = self.entity.body:getPosition()
    local sortCoordinate = "x"
    if self.direction == LEFT or self.direction == RIGHT then
        sortCoordinate = "y"
    end

    positions:unstableSortSelf(function(a, b)
        return (abs(a[sortCoordinate] - source[sortCoordinate]) < abs(b[sortCoordinate] - source[sortCoordinate]))
    end)
    local currentCoordinate = 0
    for position in positions() do
        local nextCoordinate = abs(position[sortCoordinate] - source[sortCoordinate])
        if nextCoordinate ~= currentCoordinate then
            currentCoordinate = nextCoordinate
            currentEvent = currentEvent:chainProgress(SPREAD_DELAY)
        end

        currentEvent:chainEvent(function(_, anchor)
            local hit = self.entity.hitter:createHit()
            hit.sound = false
            Common.playSFX("BURN_DAMAGE", 1, 1.5)
            hit:setSpawnFireFromSecondary(self.abilityStats)
            hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
            hit:applyToPosition(anchor, position)
        end)
    end

    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Gloves of Prometheus")
local LEGENDARY_STAT_LINE = "Increase all {C:KEYWORD}Burn duration by %s."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DEBUFF_DURATION] = 2 })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_DEBUFF_DURATION)
end
LEGENDARY.decorateOutgoingHit = function(entity, hit, abilityStats)
    local increase = abilityStats:get(Tags.STAT_MODIFIER_DEBUFF_DURATION)
    if hit.spawnFire then
        hit.spawnFire.duration = hit.spawnFire.duration + increase
    end

end
return ITEM

