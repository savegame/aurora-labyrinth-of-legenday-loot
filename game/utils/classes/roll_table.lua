local RollTable = class()
local Array = require("utils.classes.array")
function RollTable:initialize()
    self._results = Array:new()
    self._runningOdds = Array:new()
end

function RollTable:clone()
    local result = RollTable:super(self, "clone")
    result._results = self._results:clone()
    result._runningOdds = self._runningOdds:clone()
    return result
end

function RollTable:addResult(chance, result)
    if chance > 0 then
        self._results:push(result)
        self._runningOdds:push((self._runningOdds:last() or 0) + chance)
    end

end

function RollTable:roll(rng)
    rng = rng or DEFAULT_RNG
    return self:getValue(rng:random())
end

function RollTable:getValue(roll)
    roll = roll * self._runningOdds:last()
    for i = 1, self._results.n - 1 do
        if roll < self._runningOdds[i] then
            return self._results[i]
        end

    end

    return self._results:last()
end

function RollTable:isEmpty()
    return self._results:isEmpty()
end

function RollTable:size()
    return self._results:size()
end

function RollTable:getResults()
    return self._results
end

function RollTable:__tostring()
    local previous = 0
    local result = Array:new()
    for i, value in ipairs(self._results) do
        result:push(("%.2f-%.2f: %s"):format(previous, self._runningOdds[i], value))
        previous = self._runningOdds[i]
    end

    return result:join(", ")
end

return RollTable

