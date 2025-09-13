local Entity = class()
function Entity:initialize(config,...)
    self._prefab = config
    local prefab = require("entities." .. config)
    prefab(self, ...)
end

function Entity:addComponent(component,...)
    local componentClass = require("components." .. component)
    local instance = componentClass:new(self, ...)
    self[component] = instance
    return self[component]
end

function Entity:hasComponent(component)
    return toBoolean(rawget(self, component))
end

function Entity:delete()
    for componentName, componentInstance in pairs(self) do
        if componentName:sub(1, 1) ~= "_" then
            local system = componentInstance.system
            system:deleteInstance(self)
        end

    end

end

function Entity:callIfHasComponent(componentName, methodName,...)
    if DebugOptions.ENABLED then
        require("components." .. componentName)
    end

    if self:hasComponent(componentName) then
        return (self[componentName])[methodName](self[componentName], ...)
    end

    return false
end

function Entity:getIfHasComponent(componentName, fieldName)
    if DebugOptions.ENABLED then
        require("components." .. componentName)
    end

    if self:hasComponent(componentName) then
        return (self[componentName])[fieldName]
    end

    return false
end

function Entity:getPrefab()
    return self._prefab
end

return Entity

