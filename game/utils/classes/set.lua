local Set = class()
local Array = require("utils.classes.array")
function Set:initialize(...)
    self.n = 0
    self.container = {  }
    self:add(...)
end

function Set:clear()
    self.container = {  }
end

function Set:add(...)
    for i, v in ipairs({ ... }) do
        if not self.container[v] then
            self.container[v] = true
            self.n = self.n + 1
        end

    end

end

function Set:size()
    return self.n
end

Set.EMPTY = Set:new()
function Set:first()
    for v, _ in pairs(self.container) do
        return v
    end

    return nil
end

function Set:intersection(otherSet)
    local intersect = Set:new()
    for v in self() do
        if otherSet:contains(v) then
            intersect:add(v)
        end

    end

    return intersect
end

function Set:doesIntersect(otherSet)
    for v in self() do
        if otherSet:contains(v) then
            return true
        end

    end

    return false
end

function Set:delete(value)
    if self.container[value] ~= nil then
        self.container[value] = nil
        self.n = self.n - 1
    end

end

function Set:findOne(fn)
    for k, v in pairs(self.container) do
        if fn(k) then
            return k
        end

    end

    return nil
end

function Set:rejectSelf(fn)
    for v in self() do
        if not fn(v) then
            self.container[value] = nil
        end

    end

end

function Set:reject(fn)
    local newSet = Set:new()
    for v in self() do
        if not fn(v) then
            newSet:add(v)
        end

    end

    return newSet
end

function Set:map(fn)
    local newSet = Set:new()
    for v in self() do
        newSet:add(fn(v))
    end

    return newSet
end

function Set:contains(value)
    return toBoolean(self.container[value])
end

function Set:isEmpty()
    return self.n == 0
end

function Set:toArray()
    local values = Array:new()
    for v, _ in pairs(self.container) do
        values:push(v)
    end

    return values
end

function Set:__call()
    return (self:toArray())()
end

return Set

