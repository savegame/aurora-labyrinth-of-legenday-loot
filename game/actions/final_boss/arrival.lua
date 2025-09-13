local ARRIVAL = class("actions.action")
local Global = require("global")
local Common = require("common")
local Vector = require("utils.classes.vector")
local Color = require("utils.classes.color")
local EXTRA_DELAY = 0.2
function ARRIVAL:initialize(entity, direction, abilityStats)
    ARRIVAL:super(self, "initialize", entity, direction, abilityStats)
    self.color = false
    self:addComponent("lightningspawner")
    self.lightningspawner.lightningCount = 3
    self.lightningspawner.speedMultiplier = 0.7
end

function ARRIVAL:process(currentEvent)
    self.lightningspawner.color = self.color
    local source = self.entity.body:getPosition()
    for direction in (DIRECTIONS_AA:shuffle(Common.getMinorRNG()))() do
        currentEvent:chainEvent(function()
            Common.playSFX("LIGHTNING")
        end)
        currentEvent = self.lightningspawner:spawn(currentEvent, source + Vector[direction]):chainProgress(EXTRA_DELAY)
    end

    currentEvent:chainEvent(function()
        Common.playSFX("LIGHTNING")
        Global:get(Tags.GLOBAL_AUDIO):playBGM("LAST_BOSS")
    end)
    currentEvent = self.lightningspawner:spawn(currentEvent, source)
    currentEvent = currentEvent:chainEvent(function()
        self.entity.charactereffects:flash(1, self.color)
        self.entity.sprite.opacity = 1
    end)
    return currentEvent
end

return ARRIVAL

