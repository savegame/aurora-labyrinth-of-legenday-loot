local Noise = class()
local Vector3 = require("utils.classes.vector3")
function Noise:initialize(rng)
    self.offset = Vector3:new(rng:random(-128, 128), rng:random(-128, 128), rng:random(-128, 128))
end

function Noise:fractal2D(octaves, inputX, inputY, persistence)
    inputX, inputY = inputX + self.offset.x, inputY + self.offset.y
    persistence = persistence or 0.75
    local total = 0
    local frequency = 1 / (2 ^ (octaves))
    local amplitude = 1
    local maxValue = 0
    for i = 1, octaves do
        total = total + love.math.noise(inputX * frequency, inputY * frequency) * amplitude
        maxValue = maxValue + amplitude
        amplitude = amplitude * persistence
        frequency = frequency * 2
    end

    return total / maxValue
end

function Noise:fractal3D(octaves, inputX, inputY, inputZ, persistence)
    inputX, inputY, inputZ = inputX + self.offset.x, inputY + self.offset.y, inputZ + self.offset.z
    persistence = persistence or 0.75
    local total = 0
    local frequency = 1 / (2 ^ (octaves - 1))
    local amplitude = 1
    local maxValue = 0
    for i = 1, octaves do
        total = total + love.math.noise(inputX * frequency, inputY * frequency, inputZ * frequency) * amplitude
        maxValue = maxValue + amplitude
        amplitude = amplitude * persistence
        frequency = frequency * 2
    end

    return total / maxValue
end

return Noise

