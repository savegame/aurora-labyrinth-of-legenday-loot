local LogicRNG = class("services.service")
function LogicRNG:initialize()
    LogicRNG:super(self, "initialize")
    self._rng = false
    self:setDependencies("run")
end

function LogicRNG:getState()
    return self._rng:getState()
end

function LogicRNG:setState(state)
    self._rng:setState(state)
end

function LogicRNG:onDependencyFulfill()
    self._rng = Utils.createRandomGenerator(self.services.run:getCurrentFloorSeed())
end

function LogicRNG:random(...)
    return self._rng:random(...)
end

LogicRNG.roll = LogicRNG.random
function LogicRNG:rollChance(chance)
    return self._rng:random() < chance
end

function LogicRNG:rollFloat(minValue, maxValue)
    return self._rng:random() * (maxValue - minValue) + maxValue
end

function LogicRNG:resolveInteger(number)
    local remainder = number % 1
    if remainder > 0 then
        if self._rng:random() < remainder then
            return floor(number) + 1
        else
            return floor(number)
        end

    else
        return number
    end

end

return LogicRNG

