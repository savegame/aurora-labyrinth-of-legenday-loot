local Timing = class("services.service")
function Timing:initialize()
    Timing:super(self, "initialize")
    self.timePassed = 0
    self.deltaTime = 0
    self.currentFrame = 0
end

function Timing:update(dt)
    self.timePassed = self.timePassed + dt
    self.deltaTime = dt
    self.currentFrame = self.currentFrame + 1
end

return Timing

