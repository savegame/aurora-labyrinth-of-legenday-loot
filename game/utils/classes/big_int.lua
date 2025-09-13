local BigInt = class()
local Array = require("utils.classes.array")
local DIGITS = "0123456789abcdefghijklmnopqrstuvwxyz"
local BITS = 24
local RADIX = 2 ^ BITS
local function partitionAndConvert(n, base, power)
    local result = Array:new()
    local digits = BITS / power
    local length = #n
    while length > 0 do
        local starting = max(1, length - digits + 1)
        result:push(tonumber(n:sub(starting, length), base))
        n = n:sub(1, starting - 1)
        length = length - digits
    end

    return result
end

local function getPowerOfTwo(base)
    return round(log(base) / log(2))
end

local function isBasePowerDivisible(base, power)
    return 2 ^ power == base and BITS % power == 0
end

function BigInt:initialize(n, base)
            if BigInt:isInstance(n) then
        self.digits = n.digits:clone()
        self.negative = n.negative
    elseif type(n) == "number" then
        self.negative = n < 0
        n = abs(n)
        self.digits = Array:new(n)
        if n >= RADIX then
            self:_fixOverflow()
        end

    elseif type(n) == "string" then
        if n:sub(1, 1) == "-" then
            self.negative = true
            n = n:sub(2)
        else
            self.negative = false
        end

        if #n == 0 then
            self.digits:push(0)
        else
            n = n:lower()
            base = base or 10
            local power = getPowerOfTwo(base)
            if isBasePowerDivisible(base, power) then
                self.digits = partitionAndConvert(n, base, power)
            else
                local result = BigInt.ZERO
                local biBase = BigInt:new(base)
                for i = 1, #n do
                    result = result:__mul(biBase)
                    result = result:__add(BigInt:new(tonumber(n:sub(i, i), base)))
                end

                self.digits = result.digits
            end

        end

    else
        self.digits = Array:new()
        self.negative = false
    end

end

BigInt.ZERO = BigInt:new(0)
BigInt.ONE = BigInt:new(1)
BigInt.TWO = BigInt:new(2)
function BigInt:_fixOverflow()
    local newDigits = Array:new()
    local i = 1
    while i <= self.digits:size() do
        local digit = self.digits[i]
        newDigits:push(digit % RADIX)
        local carry = floor(digit / RADIX)
        if i == self.digits:size() then
            if carry > 0 then
                self.digits:push(carry)
            end

        else
            self.digits[i + 1] = self.digits[i + 1] + carry
        end

        i = i + 1
    end

    self.digits = newDigits
end

function BigInt:trimLeadingZeroes()
    while self.digits:last() == 0 and self.digits:size() > 1 do
        self.digits:pop()
    end

end

function BigInt:__unm()
    local result = BigInt:new(self)
    result.negative = not self.negative
    result:fixBrokenZero()
    return result
end

function BigInt:__add(addend)
    if self.negative ~= addend.negative then
        return self:__sub(addend:__unm())
    end

    local result = BigInt:new()
    for i = 1, max(self.digits:size(), addend.digits:size()) do
        result.digits:push(self.digits:get(i, 0) + addend.digits:get(i, 0))
    end

    result:_fixOverflow()
    result.negative = self.negative
    result:fixBrokenZero()
    return result
end

function BigInt:__sub(subtrahend)
    if self.negative ~= subtrahend.negative then
        return self:__add(subtrahend:__unm())
    end

    local comparison = self:compareAbs(subtrahend)
        if comparison == 0 then
        return BigInt.ZERO
    elseif comparison < 0 then
        return subtrahend:__sub(self):__unm()
    else
        local result = BigInt:new()
        local borrowed = false
        for i = 1, self.digits:size() do
            local selfDigit = self.digits[i]
            local subtrahendDigit = subtrahend.digits:get(i, 0)
            if borrowed then
                selfDigit = selfDigit - 1
                borrowed = false
            end

            if selfDigit < subtrahendDigit then
                selfDigit = selfDigit + RADIX
                borrowed = true
            end

            result.digits:push(selfDigit - subtrahendDigit)
        end

        result:trimLeadingZeroes()
        result.negative = self.negative
        result:fixBrokenZero()
        return result
    end

end

function BigInt:__mul(factor)
    local result = BigInt:new()
    result.digits = Array:createRepeatedValues(0, self.digits:size() + factor.digits:size() - 1)
    for i = 1, self.digits:size() do
        for j = 1, factor.digits:size() do
            result.digits[i + j - 1] = result.digits[i + j - 1] + self.digits[i] * factor.digits[j]
        end

        result:_fixOverflow()
    end

    result.negative = self.negative ~= factor.negative
    result:fixBrokenZero()
    return result
end

function BigInt:divmod(divisor)
    Utils.assert(divisor ~= BigInt.ZERO, "Division by zero")
    local remainder = BigInt:new(self)
    local negative = (self.negative ~= divisor.negative)
    remainder.negative = false
    local quotient = BigInt:new()
    quotient.digits = Array:createRepeatedValues(0, remainder.digits:size() - divisor.digits:size() + 1)
    while true do
        if remainder < divisor then
            break
        end

        local lastDigit = remainder.digits:last()
        local quotientIndex = remainder.digits:size() - divisor.digits:size() + 1
        if lastDigit <= divisor.digits:last() and quotientIndex > 1 then
            lastDigit = lastDigit * RADIX + remainder.digits[remainder.digits:size() - 1]
            quotientIndex = quotientIndex - 1
        end

        local guess = max(floor(lastDigit / (divisor.digits:last() + 1)), 1)
        quotient.digits[quotientIndex] = quotient.digits[quotientIndex] + guess
        local toSubtract = BigInt:new()
        for divisorDigit in divisor.digits() do
            toSubtract.digits:push(divisorDigit * guess)
        end

        toSubtract:_fixOverflow()
        toSubtract.digits = Array:createRepeatedValues(0, quotientIndex - 1) + toSubtract.digits
        remainder = remainder:__sub(toSubtract)
    end

    if negative and remainder ~= BigInt.ZERO then
        quotient.digits[1] = quotient.digits[1] + 1
        remainder = divisor:__sub(remainder)
    end

    quotient:_fixOverflow()
    quotient:trimLeadingZeroes()
    quotient.negative = negative
    quotient:fixBrokenZero()
    return quotient, remainder
end

function BigInt:div2()
    local remainder = 0
    local quotient = BigInt:new(self)
    for i = quotient.digits:size(), 1, -1 do
        if quotient.digits[i] % 2 == 1 then
            if i == 1 then
                remainder = 1
            else
                quotient.digits[i - 1] = quotient.digits[i - 1] + RADIX
            end

        end

        quotient.digits[i] = floor(quotient.digits[i] / 2)
    end

    quotient:trimLeadingZeroes()
    quotient.negative = (self.negative and quotient ~= BigInt.ZERO)
    if quotient.negative and remainder ~= 0 then
        quotient.digits[1] = quotient.digits[1] + 1
    end

    quotient:fixBrokenZero()
    return quotient, remainder
end

function BigInt:__div(divisor)
    local quotient, remainder = self:divmod(divisor)
    return quotient
end

function BigInt:__mod(divisor)
    local quotient, remainder = self:divmod(divisor)
    return remainder
end

function BigInt:__pow(exponent)
    Utils.assert(not exponent.negative, "BigInt negative exponents unsupported")
    if exponent == BigInt.ZERO then
        return BigInt.ONE
    end

    local result = BigInt.ONE
    local base = self
    while exponent > BigInt.ONE do
        if exponent.digits[1] % 2 == 1 then
            result = result:__mul(base)
        end

        base = base:__mul(base)
        exponent = exponent:div2()
    end

    return result:__mul(base)
end

function BigInt:modPow(exponent, divisor)
    Utils.assert(not exponent.negative, "BigInt negative exponents unsupported")
    Utils.assert(divisor ~= BigInt.ZERO, "Division by zero")
    if exponent == BigInt.ZERO then
        return BigInt.ONE
    end

    local result = BigInt.ONE
    local base = self
    while exponent > BigInt.ONE do
        if exponent.digits[1] % 2 == 1 then
            result = result:__mul(base):__mod(divisor)
        end

        base = base:__mul(base):__mod(divisor)
        exponent = exponent:div2()
    end

    return result:__mul(base):__mod(divisor)
end

function BigInt:modInverse(divisor)
    Utils.assert(not self.negative and not divisor.negative, "a & b must be positive for mod inverse")
    Utils.assert(divisor ~= BigInt.ZERO, "Division by zero")
    local s = BigInt.ZERO
    local r = divisor
    local oldS = BigInt.ONE
    local oldR = self
    while r ~= BigInt.ZERO do
        local quotient = oldR:__div(r)
        oldR, r = r, (oldR - quotient * r)
        oldS, s = s, (oldS - quotient * s)
    end

    Utils.assert(oldR == BigInt.ONE, "Mod inverse does not exist for %s/%s", self:__tostring(), divisor:__tostring())
    return oldS
end

function BigInt:compareAbs(other)
        if self.digits:size() < other.digits:size() then
        return -1
    elseif self.digits:size() > other.digits:size() then
        return 1
    else
        for i = self.digits:size(), 1, -1 do
                        if self.digits[i] < other.digits[i] then
                return -1
            elseif self.digits[i] > other.digits[i] then
                return 1
            end

        end

    end

    return 0
end

function BigInt:compare(other)
    self:fixBrokenZero()
    other:fixBrokenZero()
        if self.negative and not other.negative then
        return -1
    elseif other.negative and not self.negative then
        return 1
    else
        if self.negative then
            return -self:compareAbs(other)
        else
            return self:compareAbs(other)
        end

    end

end

function BigInt:fixBrokenZero()
    if self.negative and self.digits[1] == 0 and self.digits:size() == 1 then
        self.negative = false
    end

end

function BigInt:__eq(other)
    return self:compare(other) == 0
end

function BigInt:__lt(other)
    return self:compare(other) < 0
end

function BigInt:abs()
    local result = BigInt:new(self)
    result.negative = false
    return result
end

function BigInt:randomZeroToN(rng)
    local result = BigInt:new()
    result.digits = Array:createRepeatedValues(0, self.digits:size())
    local atMax = true
    for i = result.digits.n, 1, -1 do
        if atMax then
            result.digits[i] = rng:random(0, self.digits[i])
        else
            result.digits[i] = rng:random(RADIX) - 1
        end

        atMax = atMax and (result.digits[i] == self.digits[i])
    end

    result:trimLeadingZeroes()
    return result
end

function BigInt:random(rng)
    local n = self:abs():__sub(BigInt.ONE)
    return n:randomZeroToN(rng):__add(BigInt.ONE)
end

function BigInt:__tostring()
    return self:toString(10)
end

function BigInt:toString(base)
    base = base or 10
    Utils.assert(base <= 36, "BigInt:toString base must be <= 36: ", base)
    local result = Array:new()
    local power = getPowerOfTwo(base)
    if isBasePowerDivisible(base, power) then
        for digit in self.digits() do
            for i = 1, BITS / power do
                local index = (digit % base) + 1
                result:push(DIGITS:sub(index, index))
                digit = floor(digit / base)
            end

        end

    else
        local current = BigInt:new(self)
        current.negative = false
        base = BigInt:new(base)
        local digit
        while current > BigInt.ZERO do
            current, digit = current:divmod(base)
            result:push(DIGITS:sub(digit.digits[1] + 1, digit.digits[1] + 1))
        end

    end

    while result:last() == "0" do
        result:pop()
    end

        if result:isEmpty() then
        result = Array:new("0")
    elseif self.negative then
        result:push("-")
    end

    return result:reversed():join()
end

function BigInt:toBinaryString()
    local base = 256
    local result = Array:new()
    for digit in self.digits() do
        for i = 1, BITS / 8 do
            result:push(string.char(digit % base))
            digit = floor(digit / base)
        end

    end

    while result:last() == "0" do
        result:pop()
    end

        if result:isEmpty() then
        result = Array:new("0")
    elseif self.negative then
        result:push("-")
    end

    return result:reversed():join()
end

return BigInt

