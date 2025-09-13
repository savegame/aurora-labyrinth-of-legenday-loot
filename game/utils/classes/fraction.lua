local Fraction = class()
local IntegerAlgorithms = require("utils.classes.integers")
function Fraction:initialize(numerator, denominator)
    self.numerator = numerator
    self.denominator = denominator or 1
end

function Fraction:lowestTermsSelf()
    local gcd = IntegerAlgorithms.GCD(self.numerator, self.denominator)
    self.numerator = self.numerator / gcd
    self.denominator = self.denominator / gcd
    return self
end

function Fraction:lowestTerms()
    local result = Fraction:new(self.numerator, self.denominator)
    result:lowestTermsSelf()
    return result
end

function Fraction:__add(other)
    if type(other) == "number" then
        return Fraction:new(self.numerator + other * self.denominator, self.denominator)
    else
        local lcm = IntegerAlgorithms.LCM(self.denominator, other.denominator)
        local newNumerator = self.numerator * lcm / self.denominator + other.numerator * lcm / other.denominator
        return Fraction:new(newNumerator, lcm):lowestTermsSelf()
    end

end

function Fraction:__sub(other)
    if type(other) == "number" then
        return Fraction:new(self.numerator - other * self.denominator, self.denominator)
    else
        local lcm = IntegerAlgorithms.LCM(self.denominator, other.denominator)
        local newNumerator = self.numerator * lcm / self.denominator - other.numerator * lcm / other.denominator
        return Fraction:new(newNumerator, lcm):lowestTermsSelf()
    end

end

function Fraction:__div(other)
    if type(other) == "number" then
        return self / Fraction:new(other)
    else
        local result = Fraction:new(self.numerator * other.denominator, self.denominator * other.numerator)
        return result:lowestTermsSelf()
    end

end

function Fraction:__tostring()
    return self.numerator .. "/" .. self.denominator
end

Fraction.ONE = Fraction:new(1, 1)
return Fraction

