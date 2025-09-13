local StepInteractive = require("components.create_class")()
local SparseGrid = require("utils.classes.sparse_grid")
function StepInteractive:initialize(entity, position)
    StepInteractive:super(self, "initialize")
    self._position = position
    self._entity = entity
    self.onInteract = doNothing
end

function StepInteractive:getPosition()
    return self._position
end

function StepInteractive:getDisplayPosition()
    return self._position
end

function StepInteractive:onDelete()
    self.system:deleteInstance(self._entity)
end

function StepInteractive:uninteract()
    if self.system._lastInteracted == self._entity then
        self.system._lastInteracted = false
    end

end

function StepInteractive.System:initialize(director)
    StepInteractive.System:super(self, "initialize")
    self.storageClass = SparseGrid
    self._lastInteracted = false
    self:setDependencies("director")
end

function StepInteractive.System:addInstance(entity)
    self.entities:set(entity.stepinteractive._position, entity)
end

function StepInteractive.System:deleteInstance(entity)
    if self.entities:get(entity.stepinteractive._position) == entity then
        self.entities:delete(entity.stepinteractive._position)
    end

end

function StepInteractive.System:check(position)
    local entity = self.entities:get(position, false)
    if entity and self._lastInteracted ~= entity then
        entity.stepinteractive.onInteract(entity, self.services.director)
    end

    self._lastInteracted = entity
end

function StepInteractive.System:getAt(position)
    return self.entities:get(position, false)
end

return StepInteractive

