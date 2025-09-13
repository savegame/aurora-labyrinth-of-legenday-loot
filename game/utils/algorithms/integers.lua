local Integers = {  }
function Integers.GCD(a, b)
    if b == 0 then
        return a
    end

    return Integers.GCD(b, a % b)
end

function Integers.LCM(a, b)
    return a * b / Integers.GCD(a, b)
end

return Integers

