local Drain = class("effects.effect")
local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Range = require("utils.classes.range")
local Common = require("common")
local Particle = struct("position", "size", "speed", "targetOffset", "opacity", "toDelete")
local PARTICLE_GAP = 0.02
local RANGE_SIZE = Range:new(1, 3)
function Drain:initialize()
    Drain:super(self, "initialize")
    self.source = false
    self.target = false
    self.isStopped = false
    self.particles = Array:new()
    self.color = false
    self._particleGap = PARTICLE_GAP
    self.nextParticle = self._particleGap
    self.targetRange = 1
    self.startingRange = 1
    self.initialOpacity = 0.75
    self.speedMin = 3
    self.speedMax = 6
    self.speedOnDelete = 2
    self.onDelete = doNothing
end

function Drain:clone()
    local result = Drain:super(self, "clone")
    result.particles = self.particles:clone()
    return result
end

function Drain:getParticleGap()
    return self._particleGap
end

function Drain:setParticleGap(value)
    self._particleGap = value
    self.nextParticle = value
end

local CENTER = Vector:new(0.5, 0.5)
function Drain:update(dt)
    local rng = Common.getMinorRNG()
    if not self.isStopped then
        self.nextParticle = self.nextParticle - dt
        while self.nextParticle <= 0 do
            local starting = self.target.sprite:getDisplayPosition(true) + CENTER
            starting = starting + Vector:new(rng:random() - 0.5, rng:random() - 0.5) * self.startingRange
            local targetOffset = Vector:new(rng:random() - 0.5, rng:random() - 0.5) * self.targetRange
            local speed = rng:random() * (self.speedMax - self.speedMin) + self.speedMin
            local size = RANGE_SIZE:randomFloat(rng)
            self.particles:push(Particle:new(starting, size, speed, targetOffset, self.initialOpacity))
            self.nextParticle = self.nextParticle + self._particleGap
        end

    end

    local targetPosition = self.source.sprite:getDisplayPosition(true) + CENTER
    for particle in self.particles() do
        local ds = particle.speed * dt
        local particleTarget = targetPosition + particle.targetOffset
        local distance = particle.position:distance(particleTarget)
        if distance <= ds then
            particle.toDelete = true
        else
            particle.position = (particleTarget - particle.position) * ds / distance + particle.position
        end

    end

    self.particles:rejectSelf(function(particle)
        return particle.toDelete
    end)
    if self.particles:isEmpty() and self.isStopped then
        self:delete()
    end

    Debugger.drawText(self.particles:size())
end

function Drain:stop()
    self.isStopped = true
    for particle in self.particles() do
        particle.speed = particle.speed * self.speedOnDelete
    end

end

function Drain:draw(managerCoordinates)
    for particle in self.particles() do
        graphics.wSetColor(self.color:expandValues(particle.opacity))
        local position = managerCoordinates:gridToScreen(particle.position)
        local size = particle.size
        graphics.wRectangle(position.x - size / 2, position.y - size / 2, size, size)
    end

end

return Drain

