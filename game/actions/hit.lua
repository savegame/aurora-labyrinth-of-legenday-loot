local HIT = class("actions.action")
function HIT:initialize(entity, direction, abilityStats)
    HIT:super(self, "initialize", entity, direction, abilityStats)
    self.hit = false
    self.targetEntity = false
    self.targetPosition = false
end

function HIT:parallelResolve(anchor)
    if not self.hit then
        self.hit = self.entity.hitter:createHit()
    end

end

function HIT:process(currentEvent)
    if self.hit then
                if self.targetEntity then
            self.hit:applyToEntity(currentEvent, self.targetEntity, self.targetPosition)
        elseif self.targetPosition then
            self.hit:applyToPosition(currentEvent, self.targetPosition)
        end

    end

    return currentEvent
end

return HIT

