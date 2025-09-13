local SEED_DIGITS = 8
local DIGITS_READABLE = "123456789ABCDEFGHJKLMNPQRSTUVWXYZ"
local Array = require("utils.classes.array")
local seedGenerator = Utils.createRandomGenerator()
return function()
    local seed = Array:new()
    for i = 1, SEED_DIGITS do
        local i = seedGenerator:random(1, #DIGITS_READABLE)
        seed:push(DIGITS_READABLE:sub(i, i))
    end

    return seed:join()
end

