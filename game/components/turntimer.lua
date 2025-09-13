local TurnTimer = require("components.create_class")()
local UniqueList = require("utils.classes.unique_list")
local Hash = require("utils.classes.hash")
function TurnTimer:initialize(entity)
    TurnTimer:super(self, "initialize")
    self._entity = entity
    self.timers = Hash:new()
    self.cooldowns = Hash:new()
    self.onReady = Hash:new()
    entity:callIfHasComponent("serializable", "addComponent", "turntimer")
end

function TurnTimer:toData(convertToData)
    return { timers = convertToData(self.timers) }
end

function TurnTimer:fromData(data, convertFromData)
    self.timers = convertFromData(data.timers)
end

function TurnTimer:setCooldown(tag, duration)
    self.cooldowns:set(tag, duration)
end

function TurnTimer:setOnCooldown(tag, duration)
    duration = duration or self.cooldowns:get(tag)
    if self._entity:hasComponent("buffable") and self._entity.buffable.delayAllNonStart then
        self.timers:set(tag, duration + 1)
    else
        self.timers:set(tag, duration)
    end

end

function TurnTimer:refreshCooldown(tag)
    self.timers:deleteKeyIfExists(tag)
end

function TurnTimer:callOnReady(anchor, tag)
    if self.onReady:hasKey(tag) then
        self.onReady:get(tag)(self._entity, anchor)
    end

end

function TurnTimer:setOnInfinite(tag)
    self.timers:set(tag, math.huge)
end

function TurnTimer:isOnInfinite(tag)
    return self.timers:get(tag, 0) > 10000
end

function TurnTimer:isReady(tag)
    return not self.timers:hasKey(tag)
end

function TurnTimer:endOfTurn(anchor)
    if not self.system.services.agent:isTimeStopped() then
        self.timers:mapValuesSelf(function(duration)
            return duration - 1
        end)
        for tag, duration in self.timers() do
            if duration <= 0 then
                self:callOnReady(anchor, tag)
            end

        end

        self.timers:rejectEntriesSelf(function(tag, duration)
            return duration <= 0
        end)
    end

end

function TurnTimer.System:initialize()
    TurnTimer.System:super(self, "initialize")
    self:setDependencies("agent")
    self.storageClass = UniqueList
end

function TurnTimer.System:endOfTurn(anchor)
    for entity in self.entities() do
        entity.turntimer:endOfTurn(anchor)
    end

end

return TurnTimer

