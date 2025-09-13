local RandomQueue = class()
local Array = require("utils.classes.array")
function RandomQueue:initialize(rng,...)
    self.rng = rng or DEFAULT_RNG
    self.container = Array:new(...)
    self.container:shuffleSelf(self.rng)
end

function RandomQueue:queue(value)
    self.container:push(value)
    local size = self.container:size()
    local j = self.rng:random(1, size)
    self.container[size], self.container[j] = self.container[j], self.container[size]
end

function RandomQueue:dequeue()
    return self.container:pop()
end

RandomQueue.push = RandomQueue.queue
RandomQueue.pop = RandomQueue.dequeue
function RandomQueue:isEmpty()
    return self.container:isEmpty()
end

function RandomQueue:size()
    return self.container:size()
end

return RandomQueue

