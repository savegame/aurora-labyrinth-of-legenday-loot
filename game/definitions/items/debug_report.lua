local Array = require("utils.classes.array")
local CONSTANTS = require("logic.constants")
local function byName(a, b)
    return a.name < b.name
end

local VARIANCE_LOW = CONSTANTS.DAMAGE_VARIANCE_LOW
local VARIANCE_HIGH = CONSTANTS.DAMAGE_VARIANCE_HIGH
local function getVariance(itemDef)
    local varianceBase = 0
    if itemDef.statsBase:hasKey(Tags.STAT_ABILITY_DAMAGE_VARIANCE) then
        varianceBase = itemDef.statsBase:get(Tags.STAT_ABILITY_DAMAGE_VARIANCE)
    end

    if varianceBase == 0 then
        varianceBase = itemDef.statsBase:get(Tags.STAT_SECONDARY_DAMAGE_VARIANCE, 0)
    end

    return (varianceBase - VARIANCE_LOW) / (VARIANCE_HIGH - VARIANCE_LOW)
end

local function getStatAtMax(itemDef, stat)
    local value = itemDef:getStatAtMax(stat)
    if stat == Tags.STAT_ABILITY_DAMAGE_MIN then
        value = (value + itemDef:getStatAtMax(Tags.STAT_ABILITY_DAMAGE_MAX)) / 2
    end

    return value
end

return function(ITEMS)
    local itemDefs = Array:new()
    for key, itemDef in pairs(ITEMS.BY_ID) do
        itemDefs:push(itemDef)
    end

    local stat = DebugOptions.REPORT_STAT_SPREAD
    if stat then
        Debugger.log("-- Stat report: " .. tostring(stat) .. " --")
        itemDefs:unstableSortSelf(byName)
        itemDefs:stableSortSelf(function(a, b)
            return getStatAtMax(a, stat) < getStatAtMax(b, stat)
        end)
        for itemDef in itemDefs() do
            local value = getStatAtMax(itemDef, stat)
            if value ~= 0 and ITEMS.SLOTS_WITH_ABILITIES:contains(itemDef.slot) then
                Debugger.log(("%20s: %.2f"):format(itemDef.name, value))
            end

        end

    end

    if DebugOptions.REPORT_VARIANCE_SPREAD then
        Debugger.log("-- Variance spread: --")
        itemDefs:unstableSortSelf(byName)
        itemDefs:stableSortSelf(function(a, b)
            return getVariance(a) < getVariance(b)
        end)
        local variances = Array:new()
        for itemDef in itemDefs() do
            local variance = getVariance(itemDef)
            if variance > 0 then
                variances:push(variance)
                Debugger.log(("%20s: %.2f"):format(itemDef.name, variance))
            end

        end

        Debugger.log(("Variance Mean: %.4f"):format(variances:average()))
        local median = variances[ceil(variances:size() / 2)]
        if variances:size() % 2 == 1 then
            median = (median + variances[ceil(variances:size() / 2) + 1]) / 2
        end

        Debugger.log(("Variance Median: %.4f"):format(median))
    end

    if DebugOptions.REPORT_SUFFIX_COUNT then
        Debugger.log("-- Suffix report --")
        itemDefs:unstableSortSelf(byName)
        itemDefs:stableSortSelf(function(a, b)
            return a.suffixTable:size() < b.suffixTable:size()
        end)
        for itemDef in itemDefs() do
            if itemDef.suffixTable:size() > 0 then
                Debugger.log(("%20s: %d"):format(itemDef.name, itemDef.suffixTable:size()))
            end

        end

    end

end

