local Hash = class()
local Array = require("utils.classes.array")
function Hash:initialize(starting)
    self.container = starting or {  }
end

Hash.EMPTY = Hash:new()
function Hash:clear()
    self.container = {  }
end

function Hash:clone()
    return Hash:new(Utils.clone(self.container))
end

function Hash:hasKey(key)
    return self.container[key] ~= nil
end

function Hash:set(key, value)
    Utils.assert(value ~= nil, "Cannot set to a nil value: %s", key)
    self.container[key] = value
end

local ASSERT_DNE_KEY = "Hash does not have value for key: %s"
function Hash:get(key, defaultValue)
    if self.container[key] == nil then
        if defaultValue == nil then
            Utils.assert(false, ASSERT_DNE_KEY, key)
        else
            return defaultValue
        end

    end

    return self.container[key]
end

function Hash:add(key, value, defaultValue)
    self.container[key] = (self.container[key] or defaultValue) + value
end

function Hash:multiply(key, value, defaultValue)
    self.container[key] = (self.container[key] or defaultValue) * value
end

function Hash:deleteKey(key)
    Utils.assert(self.container[key] ~= nil, ASSERT_DNE_KEY, key)
    self.container[key] = nil
end

function Hash:deleteKeyIfExists(key)
    self.container[key] = nil
end

function Hash:apply(key, fn,...)
    if self:hasKey(key) then
        self.container[key] = fn(self.container[key], ...)
        return self.container[key]
    else
        return nil
    end

end

function Hash:isEmpty()
    for key, value in self() do
        return false
    end

    return true
end

function Hash:keys()
    local keys = Array:new()
    for key, _ in self() do
        keys:push(key)
    end

    return keys
end

function Hash:values()
    local values = Array:new()
    for _, value in self() do
        values:push(value)
    end

    return values
end

function Hash:size()
    local size = 0
    for key, value in self() do
        size = size + 1
    end

    return size
end

function Hash:maxValue(compare)
    compare = compare or lessThan
    local maxValue = nil
    for _, value in self() do
        if not maxValue then
            maxValue = value
        end

        if compare(maxValue, value) then
            maxValue = value
        end

    end

    return maxValue
end

function Hash:merge(other)
    for key, value in other() do
        self:set(key, value)
    end

end

function Hash:mapValues(fn)
    local result = Hash:new()
    for key, value in self() do
        result:set(key, fn(value, key))
    end

    return result
end

function Hash:mapValuesSelf(fn)
    local result = self:mapValues(fn)
    self.container = result.container
    return self
end

function Hash:mapKeys(fn)
    local result = Hash:new()
    for key, value in self() do
        result:set(fn(key), value)
    end

    return result
end

function Hash:acceptEntries(fn)
    local result = Hash:new()
    for key, value in self() do
        if fn(key, value) then
            result:set(key, value)
        end

    end

    return result
end

function Hash:rejectEntries(fn)
    local result = Hash:new()
    for key, value in self() do
        if not fn(key, value) then
            result:set(key, value)
        end

    end

    return result
end

function Hash:rejectEntriesSelf(fn)
    local result = self:rejectEntries(fn)
    self.container = result.container
    return self
end

function Hash:containsKey(otherKey)
    for key, value in self() do
        if key == otherKey then
            return true
        end

    end

    return false
end

function Hash:containsValue(otherValue)
    for key, value in self() do
        if value == otherValue then
            return true
        end

    end

    return false
end

function Hash:getKeyForValue(otherValue)
    for key, value in self() do
        if value == otherValue then
            return key
        end

    end

    return nil
end

function Hash:setFromTable(t)
    for key, value in pairs(t) do
        self.container[key] = value
    end

end

function Hash:__call()
    return pairs(self.container)
end

function Hash:__eq(other)
    if not Hash:isInstance(other) then
        return false
    end

    if self:size() ~= other:size() then
        return false
    end

    for key, value in self() do
        if value ~= other:get(key) then
            return false
        end

    end

    return true
end

function Hash:__add(other)
    local result = self:clone()
    result:merge(other)
    return result
end

function Hash:inverted()
    local result = Hash:new()
    for k, v in self() do
        result:set(v, k)
    end

    return result
end

function Hash:sortedKeysIterator(fn)
    local keys = self:keys()
    keys:stableSortSelf(fn)
    local i = 0
    return function()
        i = i + 1
        if i > keys.n then
            return nil
        end

        return keys[i], self:get(keys[i])
    end
end

function Hash:toTable()
    return Utils.clone(self.container)
end

function Hash:__tostring()
    return Utils.toString(self.container)
end

return Hash

