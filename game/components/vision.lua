local Vision = require("components.create_class")()
local TILE_SIZE = require("draw.measures").TILE_SIZE
local COLORS = require("draw.colors")
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local SparseGrid = require("utils.classes.sparse_grid")
local GridAlgorithms = require("utils.algorithms.grids")
local MAX_RANGE = 3
function Vision:initialize(entity)
    Vision:super(self, "initialize")
    self._entity = entity
    self.currentVisible = false
    self.previousVisible = false
    self.explored = false
    self.needRescan = false
    self.currentPosition = false
    self.maxRange = MAX_RANGE
    self.progress = 1
    entity:callIfHasComponent("serializable", "addComponent", "vision")
end

function Vision:toData(convertToData)
    return { currentPosition = convertToData(self.currentPosition), currentVisible = convertToData(self.currentVisible), explored = convertToData(self.explored) }
end

function Vision:fromData(data, convertFromData)
    self.currentPosition = convertFromData(data.currentPosition)
    self.currentVisible = convertFromData(data.currentVisible)
    self.previousVisible = self.currentVisible
    self.explored = convertFromData(data.explored)
end

function Vision:onAdd()
    if not self.currentVisible then
        local lw, lh = self.system.services.level:getDimensions()
        self.currentVisible = SparseGrid:new(false, lw, lh)
        self.previousVisible = SparseGrid:new(false, lw, lh)
        self.explored = SparseGrid:new(false, lw, lh)
    end

end

function Vision:update()
    local displayPosition = self._entity.body:getPosition()
    displayPosition = displayPosition + self._entity.offset:getTotal(true, true)
    local length = displayPosition:distance(self.currentPosition)
    if length == 0 then
        self.progress = 1
    else
        self.progress = 1 - min(1, length)
    end

end

function Vision:fillRoom(visibility, position, tiles, considered)
    for direction in DIRECTIONS_AA() do
        local target = position + Vector[direction]
        if not considered:get(target) and tiles:get(target).isRoom then
            visibility:set(target, true)
            considered:set(target, true)
            self:fillRoom(visibility, target, tiles, considered)
        end

    end

end

function Vision:scan(sourcePosition)
    local tiles = self.system:getTiles()
    Debugger.startBenchmark("scan")
    self.needRescan = false
    self.currentPosition = sourcePosition
    self.previousVisible = self.currentVisible
    self.currentVisible = SparseGrid:new(false, self.currentVisible:getDimensions())
    GridAlgorithms.lightCast(self.currentVisible, sourcePosition, self.maxRange, function(position)
        return tiles:get(position).isBlocking
    end)
    self.currentVisible:set(sourcePosition, true)
    for position, isVisible in self.currentVisible() do
        if position:distanceEuclidean(sourcePosition) > MAX_RANGE + 0.5 then
            self.currentVisible:set(position, false)
        end

    end

    local toSetVisible = Array:new()
    for position in Utils.gridIteratorV(sourcePosition.x - MAX_RANGE, sourcePosition.x + MAX_RANGE, sourcePosition.y - MAX_RANGE, sourcePosition.y + MAX_RANGE) do
        if (not self.currentVisible:get(position) and tiles:get(position).isBlocking) then
            for direction in DIRECTIONS_DIAGONAL() do
                local target = position + Vector[direction]:xPart()
                if (tiles:get(target).isBlocking and self.currentVisible:get(target)) then
                    local target2 = position + Vector[direction]:yPart()
                    if (tiles:get(target2).isBlocking and self.currentVisible:get(target2)) then
                        local target3 = position + Vector[direction]
                        if not (tiles:get(target3).isBlocking and self.currentVisible:get(target3)) then
                            toSetVisible:push(position)
                            break
                        end

                    end

                end

            end

        end

    end

    for position in toSetVisible() do
        self.currentVisible:set(position, true)
    end

    if tiles:get(sourcePosition).isRoom then
        local considered = SparseGrid:new(false)
        considered:set(sourcePosition, true)
        self:fillRoom(self.currentVisible, sourcePosition, tiles, considered)
        for position, isVisible in self.currentVisible() do
            if tiles:get(position).isRoom then
                for direction in DIRECTIONS() do
                    local target = position + Vector[direction]
                    self.currentVisible:set(target, true)
                end

            end

        end

    end

    self.system.services.visionprovider:showOnGrid(self.currentVisible)
    Debugger.stopBenchmark("scan")
    self:update()
end

function Vision:refreshExplored()
    for position, isVisible in self.currentVisible() do
        if isVisible then
            self.explored:set(position, true)
        end

    end

    self.system:refreshExplored()
end

function Vision:isVisible(position)
    return self.currentVisible:get(position)
end

function Vision:setVisible(position)
    self.currentVisible:set(position, true)
end

function Vision:isExplored(position)
    return self.explored:get(position)
end

function Vision:isVisibleForDisplay(position)
    if self.progress == 1 then
        return self.currentVisible:get(position)
    else
        return self.currentVisible:get(position) or self.previousVisible:get(position)
    end

end

function Vision:getOpacityFromGrid(grid, position)
        if grid:get(position) then
        return COLORS.VISION_VISIBLE_OPACITY
    elseif self.explored:get(position) then
        return COLORS.VISION_EXPLORED_OPACITY
    else
        return COLORS.VISION_UNEXPLORED_OPACITY
    end

end

function Vision:getOpacity(position)
    local currentOpacity = self:getOpacityFromGrid(self.currentVisible, position)
    if self.progress == 1 then
        return currentOpacity
    else
        local previousOpacity = self:getOpacityFromGrid(self.previousVisible, position)
        return previousOpacity * (1 - self.progress) + currentOpacity * self.progress
    end

end

function Vision:draw()
    Debugger.startBenchmark("vision")
    local coordinates = self.system.services.coordinates
    local bounds = coordinates:getScreenBounds()
    for py = bounds.y, bounds:bottom() - 1 do
        local lastValue = 0
        local lastX = bounds.x - 1
        for px = bounds.x, bounds:right() + 1 do
            local value = self:getOpacity(Vector:new(px, py))
            if px == bounds:right() + 1 or lastValue ~= value then
                if lastValue > 0 then
                    graphics.wSetColor(0, 0, 0, lastValue)
                    local scPos = coordinates:gridToScreen(Vector:new(lastX, py))
                    graphics.wRectangle(scPos.x, scPos.y, TILE_SIZE * (px - lastX), TILE_SIZE)
                end

                lastValue = value
                lastX = px
            end

        end

    end

    Debugger.stopBenchmark("vision")
end

function Vision.System:initialize()
    Vision.System:super(self, "initialize")
    self.storageClass = Array
    self:setDependencies("level", "coordinates", "visionprovider", "director")
end

function Vision.System:getTiles()
    return self.services.level.tiles
end

function Vision.System:refreshExplored()
    self.services.director:publish(Tags.UI_REFRESH_EXPLORED)
end

function Vision.System:get()
    return self.entities[1].vision
end

function Vision.System:setVisible(target)
    self.entities[1].vision:setVisible(target)
end

function Vision.System:setNeedRescan()
    self.entities[1].vision.needRescan = true
end

function Vision.System:isVisible(target)
    return self.entities[1].vision:isVisible(target)
end

function Vision.System:isVisibleForDisplay(target)
    return self.entities[1].vision:isVisibleForDisplay(target)
end

function Vision.System:draw()
    self.entities[1].vision:draw()
end

function Vision.System:update()
    self.entities[1].vision:update()
end

function Vision.System:addInstance(entity)
    self.entities:push(entity)
    entity.vision:onAdd()
end

function Vision.System:deleteInstance(entity)
end

return Vision

