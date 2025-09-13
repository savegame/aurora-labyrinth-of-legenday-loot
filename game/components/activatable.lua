local Activatable = require("components.create_class")()
function Activatable:initialize(entity)
    Activatable:super(self, "initialize")
    self._activated = false
end

function Activatable:isActivated()
    return self._activated
end

function Activatable:activate()
    self._activated = true
end

function Activatable:deactivate()
    self._activated = false
end

function Activatable:toggle()
    self._activated = (not self._activated)
end

return Activatable

