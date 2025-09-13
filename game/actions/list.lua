local Array = require("utils.classes.array")
local ActionList = class(Array)
function ActionList:initialize(...)
    ActionList:super(self, "initialize", ...)
end

function ActionList:createFromClasses(classes, entity, direction, kwargs)
    local result = ActionList:new()
    for klass in classes() do
        local action = entity.actor:create(klass, direction)
        if kwargs then
            table.assign(action, kwargs)
        end

        if action:isEnabled() then
            result:push(action)
        end

    end

    return result
end

function ActionList:parallelResolve(anchor)
    for action in self() do
        action:parallelResolve(anchor)
    end

end

function ActionList:chainEvent(currentEvent)
    for i, action in ipairs(self) do
        currentEvent = action:chainEvent(currentEvent)
    end

    return currentEvent
end

function ActionList:parallelChainEvent(currentEvent)
    self:parallelResolve(currentEvent)
    return self:chainEvent(currentEvent)
end

ActionList.EMPTY = ActionList:new()
return ActionList

