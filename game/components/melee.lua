local Melee = require("components.create_class")()
function Melee:initialize(entity)
    Melee:super(self, "initialize")
    self.attackClass = false
    self.swingIcon = false
    self.enabled = true
    self._entity = entity
end

function Melee:evaluateSwingIcon()
    return Utils.evaluate(self.swingIcon, self._entity)
end

function Melee:createAction(direction)
    return self._entity.actor:create(self.attackClass, direction)
end

return Melee

