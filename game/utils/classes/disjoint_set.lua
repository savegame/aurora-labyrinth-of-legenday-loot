local DisjointSet = class()
local Array = require("utils.classes.array")
function DisjointSet:initialize(values)
        if type(values) == "number" then
        self.parent = Range:new(1, values):toArray()
        values = self.parent
    elseif Array:isInstance(values) then
        self.parent = Range:new(1, values.n):toArray()
    else
        Utils.assert(false, "Invalid values for DisjointSet:initialize: %s", values)
    end

    self.mapping = {  }
    self.values = values
    self.rank = Array:new()
    for i, value in ipairs(values) do
        self.mapping[value] = i
        self.rank:push(0)
    end

end

function DisjointSet:toIndex(value)
    Utils.assert(self.mapping[value], "Value not found in disjoint set: %s", value)
    return self.mapping[value]
end

function DisjointSet:findParentIndex(index)
    if self.parent[index] ~= index then
        self.parent[index] = self:findParentIndex(self.parent[index])
    end

    return self.parent[index]
end

function DisjointSet:findParent(value)
    return self.values[self:findParentIndex(self:toIndex(value))]
end

function DisjointSet:union(value1, value2)
    local index1, index2 = self:toIndex(value1), self:toIndex(value2)
    local parent1, parent2 = self:findParentIndex(index1), self:findParentIndex(index2)
    if parent1 == parent2 then
        return false
    end

        if self.rank[parent1] < self.rank[parent2] then
        self.parent[parent1] = parent2
    elseif self.rank[parent2] < self.rank[parent1] then
        self.parent[parent2] = parent1
    else
        self.parent[parent2] = parent1
        self.rank[parent1] = self.rank[parent1] + 1
    end

    return true
end

return DisjointSet

