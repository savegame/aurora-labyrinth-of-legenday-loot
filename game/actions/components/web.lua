local Web = class("actions.components.component")
local Common = require("common")
function Web:initialize(action)
    Web:super(self, "initialize", action)
    self.target = false
    self.source = false
    self._length = false
    self._effect = false
end

function Web:chainExtendEvent(currentEvent, duration)
    return currentEvent:chainEvent(function()
        self._effect = self:createEffect("web")
        self._effect.position = self.source or self.action.entity.body:getPosition()
        self._effect.direction = Common.getDirectionTowards(self._effect.position, self.target)
        self._length = self._effect.position:distanceManhattan(self.target)
    end):chainProgress(duration, function(progress)
        self._effect.length = progress * self._length
    end)
end

function Web:chainRetractEvent(currentEvent, duration)
    return currentEvent:chainProgress(duration, function(progress)
        self._effect.length = (1 - progress) * self._length
    end):chainEvent(function()
        self._effect:delete()
    end)
end

function Web:forceDelete()
    self._effect:delete()
end

return Web

