local BUFFS = require("definitions.buffs")
local TUTORIAL_CONTROLLER = BUFFS:define("TUTORIAL_CONTROLLER")
local TRIGGERS = require("actions.triggers")
local Common = require("common")
local TRIGGER_HEALTH_ORB = class(TRIGGERS.ON_KILL)
function TRIGGER_HEALTH_ORB:process(currentEvent)
    if self.killed.tank.orbChance == 1 then
        if Common.isElite(self.killed) then
            self.entity.publisher:publish(Tags.UI_HEALTH_ORB_KILL, true)
        else
            self.entity.publisher:publish(Tags.UI_HEALTH_ORB_KILL, false)
        end

    end

    return currentEvent
end

function TRIGGER_HEALTH_ORB:isEnabled()
    return self.killed and self.killed:hasComponent("agent")
end

local TRIGGER_DESTRUCTIBLE = class(TRIGGERS.ON_KILL)
function TRIGGER_DESTRUCTIBLE:process(currentEvent)
    self.entity.publisher:publish(Tags.UI_DESTRUCTIBLE_KILL, self.killed)
    return currentEvent
end

function TRIGGER_DESTRUCTIBLE:isEnabled()
    if not self.killed or not self.killed:hasComponent("tank") then
        return false
    end

    if self.killed:hasComponent("agent") then
        return false
    end

    return self.killed.tank.orbChance <= 0
end

function TUTORIAL_CONTROLLER:initialize(duration)
    TUTORIAL_CONTROLLER:super(self, "initialize", duration)
    self.triggerClasses:push(TRIGGER_HEALTH_ORB)
    self.triggerClasses:push(TRIGGER_DESTRUCTIBLE)
end

return TUTORIAL_CONTROLLER

