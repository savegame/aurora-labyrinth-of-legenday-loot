local Hash = require("utils.classes.hash")
function Utils.loadLove(...)
    for i, moduleName in ipairs { ... } do
        _G[moduleName] = love[moduleName]
    end

end

function Utils.loadAllLove(onConflict)
    for moduleName, _ in pairs(love._modules) do
        if _G[moduleName] then
            for k, v in pairs(love[moduleName]) do
                if onConflict and _G[moduleName][k] then
                    onConflict(moduleName, k)
                end

                _G[moduleName][k] = v
            end

        else
            _G[moduleName] = love[moduleName]
        end

    end

end

function Utils.disableDefaultRandomGenerator()
    random = function()
        Utils.assert(false, "Use RandomGenerator#random")
    end
    math.random = random
    DEFAULT_RNG.random = random
end

function Utils.createRandomGenerator(seed)
    local rng
            if type(seed) == "number" then
        rng = math.newRandomGenerator(seed)
    elseif type(seed) == "string" then
        local digits = #seed
        local half1, half2 = seed:sub(1, floor(digits / 2)), seed:sub(floor(digits / 2) + 1, digits)
        rng = math.newRandomGenerator(tonumber(half1, 36), tonumber(half2, 36))
    elseif type(seed) == "userdata" then
        rng = math.newRandomGenerator(ceil(seed:random() * (2 ^ 30 - 1)), ceil(seed:random() * (2 ^ 30 - 1)))
    else
        rng = math.newRandomGenerator(round((timer.getTime() * 10000 + timer.getDelta() * 100000000) + mouse.getX() * mouse.getY()), os.time())
    end

    for i = 1, 3 do
        rng:random()
    end

    return rng
end

local imageCache = Hash:new()
function Utils.loadImage(filename)
    if not imageCache:hasKey(filename) then
        imageCache:set(filename, graphics.newImage("graphics/" .. filename .. ".png"))
    end

    return imageCache:get(filename)
end

local quadCache = Hash:new()
local MAX_QUAD = 2 ^ 24
function Utils.loadQuad(width, height)
    if type(width) == "string" then
        width, height = Utils.loadImage(width):getDimensions()
    end

    local key = height * MAX_QUAD + width
    if not quadCache:hasKey(key) then
        quadCache:set(key, graphics.newQuad(0, 0, width, height, width, height))
    end

    return quadCache:get(key)
end

function Utils.stencilExclude(callback)
    graphics.stencil(callback, "replace", 1)
    graphics.setStencilTest("notequal", 1)
end

function Utils.stencilInclude(callback)
    graphics.stencil(callback, "replace", 1)
    graphics.setStencilTest("equal", 1)
end

function Utils.stencilDisable()
    graphics.setStencilTest()
end


