local LightningSpawner = class("actions.components.component")
local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Common = require("common")
local LIGHTNING_OFFSET = Vector:new(0, 0.25)
local LIGHTNING_LENGTH = 1.5
local DEFAULT_LIGHTNING_COUNT = 3
local STRIKE_DURATION = 0.06
local GLOW_FADE_IN = 0.15
local GLOW_FADE_OUT = 0.1
local LIGHTNING_FADE_OUT = 0.19
function LightningSpawner:initialize(action)
    LightningSpawner:super(self, "initialize", action)
    self.lightningCount = DEFAULT_LIGHTNING_COUNT
    self.color = false
    self.speedMultiplier = 1
    self.strikeDuration = STRIKE_DURATION
end

function LightningSpawner:spawn(currentEvent, position, startPosition)
    local lightnings = Array:new()
    local endPosition = position
    if not startPosition then
        startPosition = position + LIGHTNING_OFFSET - Vector:new(0, LIGHTNING_LENGTH)
        endPosition = position + LIGHTNING_OFFSET
    end

    currentEvent = currentEvent:chainEvent(function()
        for i = 1, self.lightningCount do
            local lightning = self:createEffect("lightning", startPosition, endPosition)
            if self.color then
                lightning.color = self.color
            end

            lightnings:push(lightning)
        end

    end):chainProgress(startPosition:distance(endPosition) * self.strikeDuration / self.speedMultiplier, function(progress)
        for lightning in lightnings() do
            lightning.lineProgress = progress
        end

    end)
    currentEvent:chainProgress(GLOW_FADE_IN / self.speedMultiplier, function(progress)
        for lightning in lightnings() do
            lightning.glowOpacity = progress
        end

    end):chainProgress(GLOW_FADE_OUT / self.speedMultiplier, function(progress)
        for lightning in lightnings() do
            lightning.glowOpacity = 1 - progress / 2
        end

    end):chainProgress(LIGHTNING_FADE_OUT / self.speedMultiplier, function(progress)
        for lightning in lightnings() do
            lightning.opacity = 1 - progress
        end

    end):chainEvent(function()
        for lightning in lightnings() do
            lightning:delete()
        end

    end)
    return currentEvent
end

return LightningSpawner

