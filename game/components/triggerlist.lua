local TriggerList = require("components.create_class")()
local Array = require("utils.classes.array")
local ActionList = require("actions.list")
function TriggerList:initialize(entity)
    TriggerList:super(self, "initialize")
    self._entity = entity
    self.triggerClasses = Array:new()
end

function TriggerList:getActionsForTrigger(baseClass, direction, kwargs)
    local triggerClasses = self.triggerClasses:accept(function(triggerClass)
        return baseClass:isChild(triggerClass)
    end)
    return ActionList:createFromClasses(triggerClasses, self._entity, direction, kwargs)
end

function TriggerList:hasActionsForTrigger(baseClass, direction, kwargs)
    return not self:getActionsForTrigger(baseClass, direction, kwargs):isEmpty()
end

return TriggerList

