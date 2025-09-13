local ActionScheduler = class("scheduler")
function ActionScheduler:initialize()
    ActionScheduler:super(self, "initialize")
    self:setDependencies("timing")
end

function ActionScheduler:getCurrentTime()
    return self.services.timing.timePassed
end

return ActionScheduler

