local GrowingStatsDef = class()
local Set = require("utils.classes.set")
local Hash = require("utils.classes.hash")
local Array = require("utils.classes.array")
local CONSTANTS = require("logic.constants")
local DO_NOT_ROUND = Set:new(Tags.STAT_MANA_REGEN, Tags.STAT_HEALTH_REGEN, Tags.STAT_ABILITY_DAMAGE_VARIANCE, Tags.STAT_SECONDARY_DAMAGE_VARIANCE, Tags.STAT_MODIFIER_DAMAGE_VARIANCE, Tags.STAT_KNOCKBACK_DAMAGE_VARIANCE, Tags.STAT_ABILITY_POWER)
local GROWING_STATS = Set:new(Tags.STAT_MAX_HEALTH, Tags.STAT_MAX_MANA, Tags.STAT_ATTACK_DAMAGE_BASE, Tags.STAT_ABILITY_DAMAGE_BASE, Tags.STAT_SECONDARY_DAMAGE_BASE, Tags.STAT_MODIFIER_DAMAGE_BASE, Tags.STAT_KNOCKBACK_DAMAGE_BASE, Tags.STAT_POISON_DAMAGE_BASE)
local UPGRADE_LEVELS = CONSTANTS.ITEM_UPGRADE_LEVELS
local INCREASE_PER_UPGRADE = CONSTANTS.MAX_UPGRADE_INCREASE / UPGRADE_LEVELS
function GrowingStatsDef:initialize()
    self.statsBase = Hash:new()
    self.growthPerLevel = Array:new()
    self.powerSpikes = Array:new()
    self.growthMultiplier = Hash:new()
    self.statsMax = Hash:new()
    self.saveKey = false
    self.decorateOutgoingHit = doNothing
    self.decorateIncomingHit = doNothing
    self.decorateBasicMove = doNothing
    self.abilityStatBonuses = Hash:new()
end

function GrowingStatsDef:setAbilityStatBonus(stat, callback)
    self.abilityStatBonuses:set(stat, callback)
end

function GrowingStatsDef:addPowerSpike(t)
    self.powerSpikes:push(Hash:new(t))
end

function GrowingStatsDef:setToStatsBase(t)
    self.statsBase:setFromTable(t)
end

function GrowingStatsDef:getStatAtMax(stat)
    return self.statsMax:get(stat, 0)
end

function GrowingStatsDef:getGrowthForLevel(level)
    if self.growthPerLevel:size() >= level then
        return self.growthPerLevel:get(level)
    else
        return Hash.EMPTY
    end

end

function GrowingStatsDef:setGrowthMultiplier(t)
    self.growthMultiplier = Hash:new(t)
end

local function setMinMaxFromBaseVariance(stats, keyBase, keyVariance, keyMin, keyMax)
    if stats:hasKey(keyBase) then
        local baseDamage, variance = stats:get(keyBase), stats:get(keyVariance)
        if variance == 0 then
            stats:set(keyMin, baseDamage)
            stats:set(keyMax, baseDamage)
        else
            stats:set(keyMin, (baseDamage * (1 - variance) - 0.001))
            stats:set(keyMax, (baseDamage * (1 + variance) + 0.001))
        end

        if DebugOptions.REPORT_STAT_SPREAD ~= keyBase then
            stats:deleteKey(keyBase)
        end

        if not DebugOptions.REPORT_VARIANCE_SPREAD then
            stats:deleteKey(keyVariance)
        end

    end

end

local function resolveStats(stats)
    setMinMaxFromBaseVariance(stats, Tags.STAT_ATTACK_DAMAGE_BASE, Tags.STAT_ATTACK_DAMAGE_VARIANCE, Tags.STAT_ATTACK_DAMAGE_MIN, Tags.STAT_ATTACK_DAMAGE_MAX)
    setMinMaxFromBaseVariance(stats, Tags.STAT_ABILITY_DAMAGE_BASE, Tags.STAT_ABILITY_DAMAGE_VARIANCE, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_DAMAGE_MAX)
    setMinMaxFromBaseVariance(stats, Tags.STAT_SECONDARY_DAMAGE_BASE, Tags.STAT_SECONDARY_DAMAGE_VARIANCE, Tags.STAT_SECONDARY_DAMAGE_MIN, Tags.STAT_SECONDARY_DAMAGE_MAX)
    setMinMaxFromBaseVariance(stats, Tags.STAT_MODIFIER_DAMAGE_BASE, Tags.STAT_MODIFIER_DAMAGE_VARIANCE, Tags.STAT_MODIFIER_DAMAGE_MIN, Tags.STAT_MODIFIER_DAMAGE_MAX)
    setMinMaxFromBaseVariance(stats, Tags.STAT_KNOCKBACK_DAMAGE_BASE, Tags.STAT_KNOCKBACK_DAMAGE_VARIANCE, Tags.STAT_KNOCKBACK_DAMAGE_MIN, Tags.STAT_KNOCKBACK_DAMAGE_MAX)
    if stats:hasKey(Tags.STAT_POISON_DAMAGE_BASE) then
        local poisonBase = stats:get(Tags.STAT_POISON_DAMAGE_BASE)
        local poisonDuration = stats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
        stats:set(Tags.STAT_POISON_DAMAGE_TOTAL, round(poisonBase * poisonDuration))
        stats:deleteKey(Tags.STAT_POISON_DAMAGE_BASE)
    end

    stats:mapValuesSelf(function(value, stat)
        if DO_NOT_ROUND:contains(stat) then
            return value
        else
            return round(value)
        end

    end)
end

function GrowingStatsDef:extrapolate()
    Utils.assert(self.powerSpikes, "Can only extrapolate once")
    local spikeCount = self.powerSpikes:size()
    local spikesAt = Hash:new()
    Utils.assert(spikeCount <= UPGRADE_LEVELS and spikeCount >= 0, "Power spikes must be between 0 and %d", UPGRADE_LEVELS)
    if spikeCount > 0 then
        local spikes = Array:new()
        local skips = max(2, ceil(UPGRADE_LEVELS / spikeCount))
        local firstHalfCount = min(UPGRADE_LEVELS / 2, spikeCount)
        for i = 0, firstHalfCount - 1 do
            spikes:push(UPGRADE_LEVELS - i * skips)
        end

        for i = 1, spikeCount - firstHalfCount do
            spikes:push(UPGRADE_LEVELS - i * 2 + 1)
        end

        spikes:stableSortSelf()
        if spikes[1] == 1 and spikeCount < UPGRADE_LEVELS then
            spikes[1] = 2
        end

        for i, spike in ipairs(spikes) do
            spikesAt:set(spike, self.powerSpikes[i])
        end

    end

    local statsPerLevel = Array:new()
    local previous = self.statsBase
    for i = 1, CONSTANTS.ITEM_UPGRADE_LEVELS do
        local current = Hash:new()
        for stat, value in previous() do
            if GROWING_STATS:contains(stat) then
                local base = self.statsBase:get(stat)
                value = value + base * INCREASE_PER_UPGRADE * self.growthMultiplier:get(stat, 1)
            end

            current:set(stat, value)
        end

        if spikesAt:hasKey(i) then
            for stat, value in (spikesAt:get(i))() do
                current:add(stat, value, 0)
            end

        end

        statsPerLevel:push(current)
        previous = current
    end

    resolveStats(self.statsBase)
    local previous = self.statsBase
    for statForLevel in statsPerLevel() do
        resolveStats(statForLevel)
        local growthForLevel = statForLevel:mapValues(function(value, stat)
            return value - previous:get(stat, 0)
        end)
        growthForLevel:rejectEntriesSelf(function(key, value)
            return value == 0
        end)
        self.growthPerLevel:push(growthForLevel)
        previous = statForLevel
    end

    self.statsMax = statsPerLevel:last()
end

return GrowingStatsDef

