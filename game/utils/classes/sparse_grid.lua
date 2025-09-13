local SparseGrid = class()
local Array = require("utils.classes.array")
local Rect = require("utils.classes.rect")
local Vector = require("utils.classes.vector")
local MAX_VALUE = 2 ^ 23
local HASH_MULTIPLIER = MAX_VALUE * 2
function SparseGrid:initialize(default, width, height)
    self.container = {  }
    self.default = default or false
    self.width = width or math.huge
    self.height = height or math.huge
end

function SparseGrid:hash(position)
    return (position.y + MAX_VALUE) * HASH_MULTIPLIER + position.x + MAX_VALUE
end

function SparseGrid:unhash(value)
    return Vector:new(value % HASH_MULTIPLIER - MAX_VALUE, floor(value / HASH_MULTIPLIER) - MAX_VALUE)
end

function SparseGrid:setDefault(default)
    self.default = default
end

function SparseGrid:set(position, value)
    if self.width < math.huge then
        if position.x < 1 or position.x > self.width then
            return 
        end

    end

    if self.height < math.huge then
        if position.y < 1 or position.y > self.height then
            return 
        end

    end

    if value == self.default then
        value = nil
    end

    self.container[self:hash(position)] = value
end

function SparseGrid:get(position)
    if self.width < math.huge then
        if position.x < 1 or position.x > self.width then
            return self.default
        end

    end

    if self.height < math.huge then
        if position.y < 1 or position.y > self.height then
            return self.default
        end

    end

    local value = self.container[self:hash(position)]
    if value == nil then
        return self.default
    end

    return value
end

function SparseGrid:__call()
    local keys = Array:new()
    for key, value in pairs(self.container) do
        if value ~= self.default then
            keys:push(self:unhash(key))
        end

    end

    local i = 0
    return function()
        i = i + 1
        if i > keys:size() then
            return nil
        end

        return keys[i], self:get(keys[i])
    end
end

function SparseGrid:denseIterator()
    Utils.assert(self.width < math.huge and self.height < math.huge, "SparseGrid:denseIterator called without width and height field")
    local positionIterator = Utils.gridIteratorV(1, self.width, 1, self.height)
    local i = 0
    return function()
        i = i + 1
        if i > self.width * self.height then
            return nil
        end

        local position = positionIterator()
        return position, self:get(position)
    end
end

function SparseGrid:size()
    local result = 0
    for key, value in pairs(self.container) do
        if value ~= self.default then
            result = result + 1
        end

    end

    return result
end

function SparseGrid:isEmpty()
    return self:size() == 0
end

function SparseGrid:getDimensions()
    return self.width, self.height
end

function SparseGrid:within(position)
    if not self.width or not self.height then
        return true
    end

    return within(position.x, 1, self.width) and within(position.y, 1, self.height)
end

function SparseGrid:contains(x, y, width, height)
    if type(x) == "table" then
        x, y, width, height = x.x, x.y, x.width, x.height
    end

    if not self.width or not self.height then
        return true
    end

    if not within(x, 1, self.width) or not within(y, 1, self.height) then
        return false
    end

    return within(x + width - 1, 1, self.width) and within(y + height - 1, 1, self.height)
end

function SparseGrid:map(default, fn)
    if not fn then
        fn = default
        default = self.default
    end

    local result = SparseGrid:new(default, self.width, self.height)
    local dimensions = Vector:new(self:getDimensions())
    for position, value in self() do
        result:set(position, fn(value, position, dimensions))
    end

    return result
end

function SparseGrid:clone()
    local result = Utils.clone(self)
    result.container = Utils.clone(self.container)
    return result
end

function SparseGrid:delete(position)
    self:set(position, self.default)
end

function SparseGrid:clear()
    self.container = {  }
end

function SparseGrid:hasValue(position)
    return self:get(position) ~= self.default
end

function SparseGrid:fillRect(value, x, y, width, height)
    if type(x) == "table" then
        x, y, width, height = x.x, x.y, x.width, x.height
    end

    for v in Utils.gridIteratorV(x, x + width - 1, y, y + height - 1) do
        self:set(v, value)
    end

end

function SparseGrid:fillRectIfEmpty(value, x, y, width, height)
        if not x then
        x, y, width, height = 1, 1, self.width, self.height
    elseif type(x) == "table" then
        x, y, width, height = x.x, x.y, x.width, x.height
    end

    for v in Utils.gridIteratorV(x, x + width - 1, y, y + height - 1) do
        if not self:hasValue(v) then
            self:set(v, value)
        end

    end

end

function SparseGrid:clearRect(x, y, width, height)
    self:fillRect(self.default, x, y, width, height)
end

function SparseGrid:lineRect(value, x, y, width, height)
    if type(x) == "table" then
        x, y, width, height = x.x, x.y, x.width, x.height
    end

    for ix = x, x + width - 1 do
        self:set(Vector:new(ix, y), value)
        self:set(Vector:new(ix, y + height - 1), value)
    end

    for iy = y + 1, y + height - 2 do
        self:set(Vector:new(x, iy), value)
        self:set(Vector:new(x + width - 1, iy), value)
    end

end

function SparseGrid:copy(other)
    self:clear()
    for k, v in pairs(other.container) do
        self.container[k] = v
    end

end

function SparseGrid:paste(other, dx, dy)
    if type(dx) == "table" then
        dx, dy = dx.x, dx.y
    end

    local offset = Vector:new(dx - 1, dy - 1)
    for position, value in other() do
        self:set(position + offset, value)
    end

end

function SparseGrid:canPaste(other, dx, dy)
    if type(dx) == "table" then
        dx, dy = dx.x, dx.y
    end

    local offset = Vector:new(dx - 1, dy - 1)
    for iv, _ in other:denseIterator() do
                if not self:within(iv + offset) then
            return false
        elseif other:hasValue(iv) and self:hasValue(iv + offset) then
            return false
        end

    end

    return true
end

function SparseGrid:isOccupied(x, y, width, height)
    if type(x) == "table" then
        x, y, width, height = x.x, x.y, x.width, x.height
    end

    for iv in Utils.gridIteratorV(x, x + width - 1, y, y + height - 1) do
        if self:hasValue(iv) or not self:within(iv) then
            return true
        end

    end

    return false
end

function SparseGrid:isAllValue(value, x, y, width, height)
    if type(x) == "table" then
        x, y, width, height = x.x, x.y, x.width, x.height
    end

    for iv in Utils.gridIteratorV(x, x + width - 1, y, y + height - 1) do
        if self:get(iv) ~= value or not self:within(iv) then
            return false
        end

    end

    return true
end

function SparseGrid:flipHorizontal()
    local newGrid = SparseGrid:new(self.default, self.width, self.height)
    for position, value in self() do
        newGrid:set(Vector:new(self.width - position.x + 1, position.y), value)
    end

    return newGrid
end

function SparseGrid:rotateClockwise()
    local newGrid = SparseGrid:new(self.default, self.height, self.width)
    for position, value in self() do
        newGrid:set(Vector:new(self.height - position.y + 1, position.x), value)
    end

    return newGrid
end

function SparseGrid:rotateCounterclockwise()
    local newGrid = SparseGrid:new(self.default, self.height, self.width)
    for position, value in self() do
        newGrid:set(Vector:new(position.y, self.width - position.x + 1), value)
    end

    return newGrid
end

function SparseGrid:rotate180()
    local newGrid = SparseGrid:new(self.default, self.width, self.height)
    for position, value in self() do
        newGrid:set(Vector:new(self.width - position.x + 1, self.height - position.y + 1), value)
    end

    return newGrid
end

function SparseGrid:merge(other)
    for k, v in pairs(other.container) do
        if v ~= self.default then
            self.container[k] = v
        end

    end

end

function SparseGrid:pad(amount, value)
    value = value or self.default
    amount = amount or 1
    self.width = self.width + amount * 2
    self.height = self.height + amount * 2
    for ix = self.width - amount, 1 + amount, -1 do
        for iy = self.height - amount, 1 + amount, -1 do
            local position = Vector:new(ix, iy)
            self:set(position, self:get(position - Vector.UNIT_XY * amount))
        end

    end

    self:fillRect(value, 1, 1, self.width, amount)
    self:fillRect(value, 1, self.height - amount + 1, self.width, amount)
    self:fillRect(value, 1, amount + 1, amount, self.height - amount * 2)
    self:fillRect(value, self.width - amount + 1, amount + 1, amount, self.height - amount * 2)
    return self
end

function SparseGrid:padHorizontal(amount, value)
    value = value or self.default
    amount = amount or 1
    self.width = self.width + amount * 2
    for ix = self.width - amount, 1 + amount, -1 do
        for iy = self.height, 1, -1 do
            local position = Vector:new(ix, iy)
            self:set(position, self:get(position - Vector.UNIT_X * amount))
        end

    end

    self:fillRect(value, 1, 1, amount, self.height)
    self:fillRect(value, self.width - amount + 1, 1, amount, self.height)
    return self
end

function SparseGrid:trimSelf()
    local trim = {  }
    local rect = self:toRect()
    for direction in DIRECTIONS_AA() do
        trim[direction] = 0
        local allWall = true
        while allWall do
            for iv in rect:iterateSide(direction) do
                if self:hasValue(iv - Vector[direction] * trim[direction]) then
                    allWall = false
                    break
                end

            end

            if allWall then
                trim[direction] = trim[direction] + 1
            end

        end

    end

    local newWidth, newHeight = self.width - trim[LEFT] - trim[RIGHT], self.height - trim[UP] - trim[DOWN]
    for iv in Utils.gridIteratorV(1, newWidth, 1, newHeight) do
        self:set(iv, self:get(iv + Vector:new(trim[LEFT], trim[UP])))
    end

    self.width, self.height = newWidth, newHeight
    return self, trim
end

function SparseGrid:normalize()
    local minValue, maxValue = 1, 0
    for _, value in self() do
        minValue, maxValue = min(value, minValue), max(value, maxValue)
    end

    return self:map(function(value)
        return (value - minValue) / (maxValue - minValue)
    end)
end

function SparseGrid:applyAutomataRule(rangeBorn, rangeSurvive)
    local changed = 0
    local newGrid = SparseGrid:new(self.default, self.width, self.height)
    for iv, current in self:denseIterator() do
        local aliveCount = 0
        for ov in Utils.gridIteratorV(-1, 1, -1, 1) do
            if ov ~= Vector.ORIGIN then
                if self:get(iv + ov) then
                    aliveCount = aliveCount + 1
                end

            end

        end

        local newValue = rangeBorn:contains(aliveCount)
        if self:get(iv) then
            newValue = rangeSurvive:contains(aliveCount)
        end

        if current ~= newValue then
            changed = changed + 1
        end

        newGrid:set(iv, newValue)
    end

    return newGrid, changed
end

function SparseGrid:scaleSelf(value)
    self.width, self.height = ceil(self.width * value), ceil(self.height * value)
    for iv, _ in self:denseIterator() do
        self:set(iv, self:get(((iv - Vector.UNIT_XY) / value):floorXY() + Vector.UNIT_XY))
    end

    return self
end

function SparseGrid:scale(value)
    local newGrid = self:clone()
    newGrid:scaleSelf(value)
    return newGrid
end

function SparseGrid:getRow(index)
    local result = Array:new()
    for i = 1, self.width do
        result:push(self:get(Vector:new(i, index)))
    end

    return result
end

function SparseGrid:getValidPosition()
    for key, value in pairs(self.container) do
        if value ~= self.default then
            return self:unhash(key)
        end

    end

    return nil
end

function SparseGrid:toRect(position)
    position = position or Vector.UNIT_XY
    return Rect:new(position.x, position.y, self.width, self.height)
end

function SparseGrid:centroid()
    local total = Vector.ORIGIN
    local n = 0
    for position, _ in self() do
        total = total + position
        n = n + 1
    end

    if n == 0 then
        return total
    end

    return total / n
end

return SparseGrid

