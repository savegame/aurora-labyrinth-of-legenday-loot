local Jump = class("actions.components.component")
local EASING = require("draw.easing")
function Jump:initialize(action)
    Jump:super(self, "initialize", action)
    self.entity = false
    self.height = 0
    self.offset = false
    self.easingRise = EASING.OUT_QUAD
    self.easingFall = EASING.QUAD
end

function Jump:setEasingToLinear()
    self.easingRise = EASING.LINEAR
    self.easingFall = EASING.LINEAR
end

function Jump:_getEntity()
    return self.entity or self.action.entity
end

function Jump:chainFullEvent(currentEvent, duration)
    currentEvent = self:chainRiseEvent(currentEvent, duration / 2)
    return self:chainFallEvent(currentEvent, duration / 2)
end

function Jump:chainRiseEvent(currentEvent, duration)
    self.offset = self:_getEntity().offset:createProfile()
    return currentEvent:chainProgress(duration, function(progress)
        self.offset.jump = progress * self.height
    end, self.easingRise)
end

function Jump:chainFallEvent(currentEvent, duration)
    return currentEvent:chainProgress(duration, function(progress)
        self.offset.jump = (1 - progress) * self.height
    end, self.easingFall):chainEvent(function()
        self:_getEntity().offset:deleteProfile(self.offset)
    end)
end

return Jump

