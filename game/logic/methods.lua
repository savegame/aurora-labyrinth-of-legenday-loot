local LogicMethods = {  }
local ITEMS = require("definitions.items")
local Array = require("utils.classes.array")
local Range = require("utils.classes.range")
local Hash = require("utils.classes.hash")
local RollTable = require("utils.classes.roll_table")
local ENEMIES = require("definitions.enemies")
local CONSTANTS = require("logic.constants")
local cacheSpawnTable = Hash:new()
function LogicMethods.getRandomSpawn(rng, currentFloor)
    if not cacheSpawnTable:hasKey(currentFloor) then
        local spawnTable = RollTable:new()
        for enemy in ENEMIES.LIST() do
            if enemy.frequency > 0 then
                local peakFloor = enemy.minFloor + 1
                local minFloor = enemy.minFloor
                if within(currentFloor - enemy.minFloor, 0, 3) or (currentFloor >= minFloor and minFloor >= CONSTANTS.MAX_FLOORS - 5) then
                                        if peakFloor == currentFloor then
                        spawnTable:addResult(enemy.frequency, enemy)
                    elseif abs(peakFloor - currentFloor) == 1 then
                        spawnTable:addResult(enemy.frequency * 0.9, enemy)
                    else
                        spawnTable:addResult(enemy.frequency * 0.8, enemy)
                    end

                end

            end

        end

        cacheSpawnTable:set(currentFloor, spawnTable)
    end

    local spawnTable = cacheSpawnTable:get(currentFloor)
    local enemy = spawnTable:roll(rng)
    return enemy.id, enemy.count
end

function LogicMethods.getEliteScrapReward(minFloor)
    return 5 + floor(minFloor / 2.3)
end

function LogicMethods.getCurrentMaxUpgrade(currentFloor)
    if currentFloor < 4 then
        return 2
    else
        return min(ceil((currentFloor + 1) / 2), CONSTANTS.ITEM_UPGRADE_LEVELS)
    end

end

function LogicMethods.getNextUpgradeFloor(currentFloor)
    local currentMax = LogicMethods.getCurrentMaxUpgrade(currentFloor)
    if currentMax == CONSTANTS.ITEM_UPGRADE_LEVELS then
        return CONSTANTS.MAX_FLOORS
    else
        return currentMax * 2
    end

end

function LogicMethods.getDestructibleHealth(currentFloor, multiplier)
    return round(LogicMethods.getFloorDependentValue(currentFloor, 40) * (multiplier or 1))
end

function LogicMethods.getFloorDependentValues(currentFloor, value, variance)
    local currentFloor = bound(currentFloor, 1, CONSTANTS.MAX_FLOORS - 2)
    local maxMultiplier = CONSTANTS.MAX_UPGRADE_INCREASE * (currentFloor - 1) / (CONSTANTS.MAX_FLOORS - 3)
    local baseValue = value * (1 + maxMultiplier)
    return baseValue * (1 - variance), baseValue * (1 + variance)
end

function LogicMethods.getFloorDependentValue(currentFloor, value)
    local result, _ = LogicMethods.getFloorDependentValues(currentFloor, value, 0)
    return result
end

local function nDistinctSpaced(rng, n, minValue, maxValue, guaranteedValues)
    local result = Array:new()
    local possibilities = Range:new(minValue, maxValue):toArray()
    for value in guaranteedValues() do
        result:push(value)
        possibilities:delete(value)
        possibilities:deleteIfExists(value - 1)
        possibilities:deleteIfExists(value + 1)
    end

    for i = 1, n - guaranteedValues:size() do
        local value = possibilities:randomValue(rng)
        result:push(value)
        possibilities:delete(value)
        possibilities:deleteIfExists(value - 1)
        possibilities:deleteIfExists(value + 1)
    end

    result:stableSortSelf()
    return result
end

local STANDARD_LEGENDARIES = 5
local STANDARD_ANVILS = 6
local GOLDEN_ANVIL_CHANCE = 0.2
if DebugOptions.ENABLED then
end

function LogicMethods.decideSpecialFloors(rng, run)
    local legendarySlots = ITEMS.SLOTS_WITH_LEGENDARIES:nDistinctRandom(3, rng)
    local legendaryIDs = Array:new()
    for slot in legendarySlots() do
        local itemDef = ITEMS.BY_SLOT[slot]:roll(rng)
        legendaryIDs:push(itemDef.saveKey)
        while true do
            local otherItem = ITEMS.BY_SLOT[slot]:roll(rng)
            if otherItem ~= itemDef then
                legendaryIDs:push(otherItem.saveKey)
                break
            end

        end

    end

    legendaryIDs = legendaryIDs:subArray(1, STANDARD_LEGENDARIES)
    local anvilCount = STANDARD_ANVILS
    if rng:random() < GOLDEN_ANVIL_CHANCE then
        anvilCount = anvilCount - 1
        legendaryIDs[STANDARD_LEGENDARIES] = "golden_anvil"
    end

    legendaryIDs:shuffleSelf(rng)
    local legendaryFloors = nDistinctSpaced(rng, STANDARD_LEGENDARIES, 6, 18, Array:new(rng:random(6, 7), rng:random(17, 18)))
    local anvilPossibilities = Range:new(4, 24):toArray()
    for i, iFloor in ipairs(legendaryFloors) do
        run.legendaries:set(iFloor, legendaryIDs[i])
        anvilPossibilities:delete(iFloor)
    end

    local firstAnvil = rng:random(1, 2)
    local anvilIndices = nDistinctSpaced(rng, anvilCount, 1, anvilPossibilities:size(), Array:new(firstAnvil, anvilPossibilities:size()))
    run.anvilFloors = anvilIndices:map(function(index)
        return anvilPossibilities[index]
    end)
    Debugger.log("Legendaries", run.legendaries)
    Debugger.log("Anvil Floors", run.anvilFloors)
end

return LogicMethods

