local ConvertNumber = {  }
local Array = require("utils.classes.array")
local TO_ROMAN_NUMERAL_SINGLE = { [1] = "I", [5] = "V", [10] = "X", [50] = "L", [100] = "C", [500] = "D", [1000] = "M" }
function ConvertNumber.toRomanNumeral(n)
    n = floor(n)
    local result = Array:new()
    while n > 1000 do
        n = n - 1000
        result:push(TO_ROMAN_NUMERAL_SINGLE[1000])
    end

    local place = 100
    while n >= 1 do
        local digitAtPlace = floor(n / place)
                if digitAtPlace == 9 then
            result:pushMultiple(TO_ROMAN_NUMERAL_SINGLE[place], TO_ROMAN_NUMERAL_SINGLE[place * 10])
        elseif digitAtPlace == 4 then
            result:pushMultiple(TO_ROMAN_NUMERAL_SINGLE[place], TO_ROMAN_NUMERAL_SINGLE[place * 5])
        else
            if digitAtPlace >= 5 then
                result:push(TO_ROMAN_NUMERAL_SINGLE[place * 5])
                digitAtPlace = digitAtPlace - 5
            end

            result:concat(Array:createRepeatedValues(TO_ROMAN_NUMERAL_SINGLE[place], digitAtPlace))
        end

        n = n % place
        place = place / 10
    end

    return result:join()
end

function ConvertNumber.commafy(n)
    local isNegative = false
    if number < 0 then
        isNegative = true
        number = abs(number)
    end

    local extra = round(number % 1, 2)
    number = floor(number)
    local result = ""
    while number >= 1000 do
        result = (",%03d%s"):format(number % 1000, result)
        number = floor(number / 1000)
    end

    result = tostring(number) .. result
    if isNegative then
        result = "-" .. result
    end

    if extra > 0 then
        result = result .. (("%.2f"):format(extra):sub(2))
    end

    return result
end

function ConvertNumber.getOrdinalSuffix(n)
    if not within(n % 100, 11, 13) then
        local last1 = n % 10
                        if last1 == 1 then
            return "st"
        elseif last1 == 2 then
            return "nd"
        elseif last1 == 3 then
            return "rd"
        end

    end

    return "th"
end

return ConvertNumber

