local Array = class()
function Array:Convert(t)
    t.n = #t
    setmetatable(t, Array)
    return t
end

function Array:initialize(...)
    self.n = 0
    self:pushMultiple(...)
end

function Array:__newindex(key, value)
    if type(key) ~= "number" and key ~= "n" and not rawget(self, "_isClass") then
        Utils.assert(false, "Key '%s' does not exist", key)
    end

    rawset(self, key, value)
end

function Array:push(value)
    self.n = self.n + 1
    self[self.n] = value
end

function Array:pushMultiple(...)
    for i, value in ipairs({ ... }) do
        self.n = self.n + 1
        self[self.n] = value
    end

end

function Array:size()
    return self.n
end

Array.add = Array.push
function Array:collect(iterator)
    local result = Array:new()
    for value in iterator do
        result:push(value)
    end

    return result
end

function Array:collect2(iterator)
    local result1, result2 = Array:new(), Array:new()
    for value1, value2 in iterator do
        result1:push(value1)
        result2:push(value2)
    end

    return result1, result2
end

Array.EMPTY = Array:new()
function Array:at(index)
    return self[index]
end

function Array:get(index, defaultValue)
    if index > self.n or index < 1 then
        return defaultValue
    end

    return self[index]
end

function Array:createRange(minValue, maxValue)
    local result = Array:new()
    for value = minValue, maxValue do
        result:push(value)
    end

    return result
end

function Array:createRepeatedValues(value, count)
    local result = Array:new()
    for i = 1, count do
        result:push(value)
    end

    return result
end

function Array:reversed()
    local result = Array:new()
    for i = 1, self.n do
        result:push(self[self.n - i + 1])
    end

    return result
end

function Array:subArray(first, last)
    last = last or self.n
    if first < 1 then
        first = 1
    end

    if last > self.n then
        last = self.n
    end

    local result = Array:new()
    for i = first, last do
        result:push(self[i])
    end

    return result
end

Array.sub = Array.subArray
function Array:first()
    return self[1]
end

function Array:last()
    if self:isEmpty() then
        return nil
    end

    return self[self.n]
end

function Array:flipSelf()
    for i = 1, self.n / 2 do
        self[i], self[self.n - i + 1] = self[self.n - i + 1], self[i]
    end

end

function Array:randomValue(rng)
    rng = rng or DEFAULT_RNG
    if self.n == 0 then
        return nil
    end

    local index = 1
    return self[rng:random(1, self.n)]
end

Array.roll = Array.randomValue
function Array:shuffleSelf(rng)
    rng = rng or DEFAULT_RNG
    for i = 1, self.n do
        local j = rng:random(i, self.n)
        self[i], self[j] = self[j], self[i]
    end

    return self
end

function Array:shuffle(rng)
    local result = self:clone()
    result:shuffleSelf(rng)
    return result
end

function Array:insert(i, v)
    table.insert(self, i, v)
    self.n = self.n + 1
end

function Array:deleteAt(i)
    local value = nil
    if i and i >= 1 and i <= self.n then
        value = self[i]
        table.remove(self, i)
        self.n = self.n - 1
    end

    return value
end

function Array:rotateLeft()
    if self.n > 0 then
        local value = self:pop()
        self:pushFirst(value)
    end

end

function Array:pushFirst(...)
    local count = select("#", ...)
    for i = 1, self.n do
        self[self.n + count - i + 1] = self[self.n - i + 1]
    end

    for i, v in ipairs({ ... }) do
        self[i] = v
    end

    self.n = self.n + count
end

function Array:clear()
    while self.n > 0 do
        self:pop()
    end

end

function Array:stableSortSelf(compare)
    compare = compare or lessThan
    local indexed = Array:new()
    for i, v in ipairs(self) do
        indexed:push({ v, i })
    end

    table.sort(indexed, function(a, b)
        local result = compare(a[1], b[1])
        if not result and not compare(b[1], a[1]) then
            return a[2] < b[2]
        end

        return result
    end)
    for i, v in ipairs(indexed) do
        self[i] = v[1]
    end

    return self
end

function Array:stableSort(compare)
    local result = self:clone()
    result:stableSortSelf(compare)
    return result
end

function Array:unstableSortSelf(compare)
    table.sort(self, compare)
    return self
end

function Array:unstableSort(compare)
    local result = self:clone()
    result:unstableSortSelf(compare)
    return result
end

function Array:sum()
    if self.n == 0 then
        return 0
    end

    local total = self[1]
    for i = 2, self.n do
        total = total + self[i]
    end

    return total
end

function Array:average()
    return self:sum() / self.n
end

function Array:mode()
    if self.n == 0 then
        return nil
    end

    local count = {  }
    local greatest = self[1]
    for value in self() do
        count[value] = (count[value] or 0) + 1
        if count[value] > count[greatest] then
            greatest = value
        end

    end

    return greatest
end

function Array:inject(fn)
    if self.n <= 1 then
        return self[1]
    end

    local value = self[1]
    for i = 2, self.n do
        value = fn(value, self[i])
    end

    return value
end

function Array:any(fn)
    for value in self() do
        if fn(value) then
            return true
        end

    end

    return false
end

function Array:all(fn)
    for value in self() do
        if not fn(value) then
            return false
        end

    end

    return true
end

function Array:compact()
    return self:reject(isFalse)
end

function Array:expand()
    return unpack(self)
end

function Array:countIf(fn)
    local result = 0
    for v in self() do
        if fn(v) then
            result = result + 1
        end

    end

    return result
end

function Array:callForAll(fn)
    for v in self() do
        fn(v)
    end

end

function Array:mapSelf(fn)
    for i = 1, self.n do
        self[i] = fn(self[i])
    end

    return self
end

function Array:map(fn)
    local result = self:clone()
    result:mapSelf(fn)
    return result
end

function Array:maxValue(compare)
    compare = compare or lessThan
    local maxValue = nil
    for value in self() do
        if not maxValue then
            maxValue = value
        end

        if compare(maxValue, value) then
            maxValue = value
        end

    end

    return maxValue
end

function Array:minValue(compare)
    compare = compare or lessThan
    local minValue = nil
    for value in self() do
        if not minValue then
            minValue = value
        end

        if compare(value, minValue) then
            minValue = value
        end

    end

    return minValue
end

function Array:mapAction(name)
    for value in self() do
        value[name](value)
    end

end

function Array:contains(value)
    return toBoolean(self:indexOf(value))
end

function Array:count(value)
    local count = 0
    for v in self() do
        if v == value then
            count = count + 1
        end

    end

    return count
end

function Array:indexOf(value)
    for i, v in ipairs(self) do
        if value == v then
            return i
        end

    end

    return nil
end

function Array:indexIf(fn)
    for i, v in ipairs(self) do
        if fn(v) then
            return i
        end

    end

    return nil
end

function Array:delete(value)
    return self:deleteAt(self:indexOf(value))
end

function Array:deleteIfExists(value)
    local index = self:indexOf(value)
    if index then
        self:deleteAt(index)
    end

end

function Array:pop()
    local result = nil
    if self.n > 0 then
        result = self[self.n]
        self[self.n] = nil
        self.n = self.n - 1
    end

    return result
end

function Array:popFirst()
    return self:deleteAt(1)
end

function Array:isEmpty()
    return self.n == 0
end

function Array:paste(other)
    for i = 1, self.n do
        if i <= other.n then
            self[i] = other[i]
        end

    end

end

function Array:concat(other)
    for i = 1, other.n do
        self[self.n + i] = other[i]
    end

    self.n = self.n + other.n
    return self
end

local function equalTo(v)
    return function(other)
        return v == other
    end
end

function Array:rejectSelf(fn)
    local current = 0
    for v in self() do
        if not fn(v) then
            current = current + 1
            self[current] = v
        end

    end

    while self.n > current do
        self:pop()
    end

    return self
end

function Array:reject(fn)
    local result = self:clone()
    result:rejectSelf(fn)
    return result
end

function Array:acceptSelf(fn)
    return self:rejectSelf(Utils.negateFunction(fn))
end

function Array:accept(fn)
    return self:reject(Utils.negateFunction(fn))
end

function Array:iterateIf(fn)
    local i = 0
    return function()
        while i < self.n do
            i = i + 1
            if fn(self[i]) then
                return self[i]
            end

        end

        return nil
    end
end

function Array:iterateUnless(fn)
    return self:iterateIf(Utils.negateFunction(fn))
end

function Array:findOne(fn)
    for v in self() do
        if fn(v) then
            return v
        end

    end

    return nil
end

function Array:hasOne(fn)
    for v in self() do
        if fn(v) then
            return true
        end

    end

    return false
end

function Array:nDistinctRandom(n, rng)
    rng = rng or DEFAULT_RNG
    return self:shuffle(rng):subArray(1, n)
end

function Array:__call()
    local i = 0
    return function()
        i = i + 1
        if i > self.n then
            return nil
        end

        return self[i]
    end
end

function Array:reverseIterator()
    local i = self.n + 1
    return function()
        i = i - 1
        if i < 1 then
            return nil
        end

        return self[i]
    end
end

function Array:pairwiseIterator()
    local i, j = 1, 1
    return function()
        if j >= self.n then
            i = i + 1
            j = i + 1
        else
            j = j + 1
        end

        if i >= self.n then
            return nil
        end

        return self[i], self[j]
    end
end

function Array:join(joiner)
    return table.concat(self, joiner or "")
end

function Array:__eq(other)
    if self.n ~= other.n then
        return false
    end

    for i = 1, self.n do
        if self[i] ~= other[i] then
            return false
        end

    end

    return true
end

function Array:__add(other)
    local result = self:clone()
    result:concat(other)
    return result
end

function Array:__tostring(tablesAdded)
    local result = Array:new("[")
    for v in self() do
                if type(v) == "string" then
            result:push("\"" .. tostring(v) .. "\"")
        elseif type(v) == "table" then
            result:push(Utils.toString(v, -1, true, nil, tablesAdded))
        else
            result:push(tostring(v))
        end

        result:push(", ")
    end

    if result.n > 1 then
        result:pop()
    end

    result:push("]")
    return result:join()
end

function Array:flatten()
    local result = Array:new()
    for v in self() do
        if Array:isInstance(v) then
            for v2 in (v:flatten())() do
                result:push(v2)
            end

        else
            result:push(v)
        end

    end

    return result
end

return Array

