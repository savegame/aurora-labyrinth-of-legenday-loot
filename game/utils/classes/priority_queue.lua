local PriorityQueue = class()
local Array = require("utils.classes.array")
function PriorityQueue:initialize(compare,...)
    self.heap = Array:new(...)
    self.compare = compare or lessThan
    for i = self.heap.n, 1, -1 do
        self:siftDown(i)
    end

end

function PriorityQueue:setCompare(compare, isMax)
    if isMax then
        self.compare = function(a, b)
            return compare(b, a)
        end
    else
        self.compare = compare
    end

end

function PriorityQueue:isEmpty()
    return self.heap:isEmpty()
end

function PriorityQueue:clear()
    self.heap:clear()
end

function PriorityQueue:popMin()
    if self.heap:size() == 0 then
        return nil
    end

    self.heap[1], self.heap[self.heap.n] = self.heap[self.heap.n], self.heap[1]
    local result = self.heap:pop()
    self:siftDown(1)
    return result
end

function PriorityQueue:peekMin()
    return self.heap[1]
end

function PriorityQueue:indexOf(value)
    return self.heap:indexOf(value)
end

function PriorityQueue:insert(value)
    self.heap:push(value)
    self:siftUp(self.heap.n)
end

function PriorityQueue:update(index)
    self:siftUp(index)
    self:siftDown(index)
end

function PriorityQueue:siftDown(index)
    while true do
        local child = index * 2
                if child > self.heap:size() then
            return 
        elseif child < self.heap:size() then
            if self.compare(self.heap[child + 1], self.heap[child]) then
                child = child + 1
            end

        end

        if self.compare(self.heap[child], self.heap[index]) then
            self.heap[index], self.heap[child] = self.heap[child], self.heap[index]
            index = child
        else
            return 
        end

    end

end

function PriorityQueue:siftUp(index)
    while true do
        if index == 1 then
            return 
        end

        local parent = floor(index / 2)
        if self.compare(self.heap[index], self.heap[parent]) then
            self.heap[index], self.heap[parent] = self.heap[parent], self.heap[index]
            index = parent
        else
            return 
        end

    end

end

return PriorityQueue

