local ENEMIES = require("definitions.enemies")
local RollTable = require("utils.classes.roll_table")
local Array = require("utils.classes.array")
local LogicMethods = require("logic.methods")
local CONSTANTS = require("logic.constants")
local SPAWN_AMOUNT = RollTable:new()
SPAWN_AMOUNT:addResult(1, 0)
SPAWN_AMOUNT:addResult(1, 1)
SPAWN_AMOUNT:addResult(6, 2)
SPAWN_AMOUNT:addResult(17, 3)
local ELITES = require("definitions.elites")
local ELITE_CHANCE_LOWEST = CONSTANTS.ELITE_CHANCE_LOWEST
local ELITE_CHANCE_HIGHEST = CONSTANTS.ELITE_CHANCE_HIGHEST
return function(command)
    local rng, level = command.rng, command.level
    local rooms = command.rooms:reject(function(room)
        return room:containsPosition(level.startPosition)
    end)
    local objects = level:getObjects()
    local eliteChance = 0
    if command.currentFloor > 2 then
        local ratio = (command.currentFloor - 3) / (CONSTANTS.MAX_FLOORS - 4)
        eliteChance = ratio * (ELITE_CHANCE_HIGHEST - ELITE_CHANCE_LOWEST) + ELITE_CHANCE_LOWEST
    end

    if DebugOptions.TEST_ELITE_TYPE then
        eliteChance = 1
    end

    local currentOrbChance = 1 - CONSTANTS.ENEMY_ORB_CHANCE
    for room in rooms() do
        local positions = room:getAllPositionsNonDoor()
        positions:rejectSelf(function(position)
            return level.tiles:get(position).isBlocking or objects:get(position)
        end)
        positions:rejectSelf(function()
            return rng:random() < 0.5
        end)
        local average = positions:sum() / positions:size()
        local starting = positions:minValue(function(a, b)
            return a:distanceManhattan(average) < b:distanceManhattan(average)
        end)
        positions:stableSortSelf(function(a, b)
            return a:distanceManhattan(starting) < b:distanceManhattan(starting)
        end)
        positions = positions:reversed()
        local isElite = rng:random() < eliteChance
        local spawnAmount = SPAWN_AMOUNT:roll(rng)
        if DebugOptions.SINGLE_ROOM_SPAWN then
            spawnAmount = 1
        end

        if command.currentFloor <= 2 and spawnAmount >= 3 then
            spawnAmount = 2
        end

        if spawnAmount >= 3 and isElite then
            spawnAmount = 2
        end

        for i = 1, spawnAmount do
            local enemy, enemyCount = LogicMethods.getRandomSpawn(rng, command.currentFloor)
            local direction
            if rng:random() < 0.5 then
                direction = LEFT
            else
                direction = RIGHT
            end

            if enemyCount > 1 then
                currentOrbChance = currentOrbChance + CONSTANTS.ENEMY_ORB_CHANCE
                for j = 1, min(positions:size(), enemyCount) do
                    local orbChance = 0
                    if currentOrbChance >= 0.99 and j == 1 then
                        orbChance = 1
                        currentOrbChance = currentOrbChance - 1
                    end

                    level:setObject(positions:pop(), "enemies." .. enemy, direction, enemy, command.difficulty, false, orbChance)
                end

            else
                if not isElite then
                    currentOrbChance = currentOrbChance + CONSTANTS.ENEMY_ORB_CHANCE
                end

                if positions:size() >= 1 then
                    local orbChance = 0
                    if not isElite and currentOrbChance >= 0.99 then
                        orbChance = 1
                        currentOrbChance = currentOrbChance - 1
                    end

                    local eliteID = false
                    if isElite then
                        if DebugOptions.TEST_ELITE_TYPE and not ENEMIES[enemy]:isEliteIDBanned(DebugOptions.TEST_ELITE_TYPE) then
                            eliteID = DebugOptions.TEST_ELITE_TYPE
                        else
                            while not eliteID do
                                eliteID = ELITES.ORDERED:roll(rng).id
                                if ENEMIES[enemy]:isEliteIDBanned(eliteID) then
                                    eliteID = false
                                end

                            end

                        end

                    end

                    level:setObject(positions:pop(), "enemies." .. enemy, direction, enemy, command.difficulty, eliteID, orbChance)
                    isElite = false
                end

            end

        end

    end

end

