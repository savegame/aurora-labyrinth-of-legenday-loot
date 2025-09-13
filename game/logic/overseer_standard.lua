local OverseerStandard = class("logic.overseer_base")
local Range = require("utils.classes.range")
local GridAlgorithms = require("utils.algorithms.grids")
local Common = require("common")
local LogicMethods = require("logic.methods")
local SPAWN_INTERVAL_STARTING = 30
local SPAWN_INTERVAL_DECREASE = 1
local SPAWN_INTERVAL_MINIMUM = 10
function OverseerStandard:initialize(...)
    OverseerStandard:super(self, "initialize", ...)
    self.nextSpawn = 1
    self.currentInterval = SPAWN_INTERVAL_STARTING
end

function OverseerStandard:toData()
    local result = OverseerStandard:super(self, "toData")
    result.nextSpawn = self.nextSpawn
    result.currentInterval = self.currentInterval
    return result
end

function OverseerStandard:fromData(data)
    OverseerStandard:super(self, "fromData", data)
    self.nextSpawn = data.nextSpawn
    self.currentInterval = data.currentInterval
end

function OverseerStandard:isValidSpawn(position)
    local player = self.services.player:get()
    if position:distanceManhattan(player.body:getPosition()) > 8 then
        if not player.vision:isVisible(position) then
            if player.body:isPassable(position) then
                return true
            end

        end

    end

    return false
end

function OverseerStandard:spawnEnemy(enemy, position)
    return self.services.createEntity("enemies." .. enemy, position, Common.getDirectionTowards(position, self.services.player:get().body:getPosition()), enemy, self.services.run.difficulty)
end

function OverseerStandard:checkEvents(anchor)
    if self.currentTurn >= self.nextSpawn then
        self.nextSpawn = self.nextSpawn + self.currentInterval
        self.currentInterval = max(self.currentInterval - SPAWN_INTERVAL_DECREASE, SPAWN_INTERVAL_MINIMUM)
        local logicRNG = self.services.logicrng
        local enemy, enemyCount = LogicMethods.getRandomSpawn(logicRNG, self.services.run.currentFloor)
        local hallPositions = self.services.level.hallPositions:shuffle(logicRNG)
        while enemyCount > 0 and (not hallPositions:isEmpty()) do
            local position = hallPositions:pop()
            if self:isValidSpawn(position) then
                enemyCount = enemyCount - 1
                self:spawnEnemy(enemy, position)
                for offset in GridAlgorithms.diamondIterator(Range:new(1, 3)) do
                    if enemyCount == 0 then
                        break
                    end

                    if self:isValidSpawn(position + offset) then
                        enemyCount = enemyCount - 1
                        self:spawnEnemy(enemy, position + offset)
                    end

                end

                break
            end

        end

    end

end

return OverseerStandard

