local Drain = class("actions.components.component")
local Array = require("utils.classes.array")
local Common = require("common")
local DEFAULT_COLOR = require("utils.classes.color"):new(1, 0.25, 0.25)
local DEFAULT_STARTING_RANGE = 1
local DEFAULT_TARGET_RANGE = 0.6
local DEFAULT_SPEED_MIN = 3
local DEFAULT_SPEED_MAX = 6
function Drain:initialize(action)
    Drain:super(self, "initialize", action)
    self.color = DEFAULT_COLOR
    self.startingRange = DEFAULT_STARTING_RANGE
    self.targetRange = DEFAULT_TARGET_RANGE
    self.speedMin = DEFAULT_SPEED_MIN
    self.speedMax = DEFAULT_SPEED_MAX
    self.particleGapMultiplier = 1
    self._effects = Array:new()
end

function Drain:start(source, target)
    local effect = self:createEffect("drain")
    effect.color = self.color
    effect.source = source
    effect.target = target
    effect.speedMin = self.speedMin
    effect.speedMax = self.speedMax
    if self.particleGapMultiplier ~= 1 then
        effect:setParticleGap(effect:getParticleGap() * self.particleGapMultiplier)
    end

    effect.startingRange = self.startingRange
    effect.targetRange = self.targetRange
    self._effects:push(effect)
end

function Drain:stop()
    for effect in self._effects() do
        effect:stop()
    end

end

return Drain

