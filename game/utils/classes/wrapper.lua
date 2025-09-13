local Wrapper = class()
function Wrapper:initialize(value)
    self.value = value or false
end

function Wrapper:set(newValue)
    self.value = newValue
end

function Wrapper:get()
    return self.value
end

function Wrapper:add(addend)
    self.value = self.value + addend
    return self.value
end

function Wrapper:bound(minValue, maxValue)
    self.value = bound(self.value, minValue, maxValue)
end

return Wrapper

