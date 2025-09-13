local Deque = class()
local Array = require("utils.classes.array")
function Deque:initialize(...)
    self.indexStart = 1
    self.indexEnd = 0
    self.container = {  }
    self:pushMultiple(...)
end

function Deque:isEmpty()
    return self.indexEnd < self.indexStart
end

function Deque:size()
    return self.indexEnd - self.indexStart + 1
end

function Deque:push(value)
    self.indexEnd = self.indexEnd + 1
    self.container[self.indexEnd] = value
end

function Deque:pushMultiple(...)
    for i, value in ipairs({ ... }) do
        self.indexEnd = self.indexEnd + 1
        self.container[self.indexEnd] = value
    end

end

Deque.EMPTY = Deque:new()
function Deque:pushFirst(value)
    self.indexStart = self.indexStart - 1
    self.container[self.indexStart] = value
end

function Deque:pop()
    if not self:isEmpty() then
        local value = self.container[self.indexEnd]
        self.container[self.indexEnd] = nil
        self.indexEnd = self.indexEnd - 1
        return value
    end

    return nil
end

function Deque:popFirst()
    if not self:isEmpty() then
        local value = self.container[self.indexStart]
        self.container[self.indexStart] = nil
        self.indexStart = self.indexStart + 1
        return value
    end

    return nil
end

function Deque:peekFirst()
    return self.container[self.indexStart]
end

Deque.queue = Deque.push
Deque.dequeue = Deque.popFirst
function Deque:__call()
    local i = self.indexStart - 1
    return function()
        i = i + 1
        if i > self.indexEnd then
            return nil
        end

        return self.container[i]
    end
end

function Deque:reverseIterator()
    local i = self.indexEnd + 1
    return function()
        i = i - 1
        if i < self.indexStart then
            return nil
        end

        return self.container[i]
    end
end

function Deque:toArray()
    return Array.collect(self())
end

function Deque:__tostring()
    return Utils.toString(self:toArray())
end

return Deque

