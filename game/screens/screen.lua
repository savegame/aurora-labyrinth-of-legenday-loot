local Screen = class()
local Hash = require("utils.classes.hash")
local Entity = require("entities.entity")
local Global = require("global")
local MEASURES = require("draw.measures")
function Screen:initialize()
    Global:get(Tags.GLOBAL_AUDIO):stopBGS()
    self._services = Hash:new()
    self._systems = Hash:new()
    self._serviceClasses = Hash:new()
    self:provideServiceDependency("profile", Global:get(Tags.GLOBAL_PROFILE))
    self:provideServiceDependency("cursor", Global:get(Tags.GLOBAL_CURSOR))
    self:provideServiceDependency("createEntity", function(entityName, ...)
        return self:createEntity(entityName, ...)
    end)
    self._cover = 1
end

function Screen:updateWithDelta(dt)
    if self._cover == 1 then
        dt = 1 / 1000
    end

    dt = dt * self:getTimeMultiplier()
    self:update(dt)
    self:getService("controls"):removeFrameStates()
end

function Screen:update(dt)
    self:getService("timing"):update(dt)
    Global:get(Tags.GLOBAL_AUDIO):update(dt)
    local coverDuration = self:getCoverDuration()
    if coverDuration <= 0 then
        self._cover = 0
    else
        self._cover = math.max(0, self._cover - dt / coverDuration)
    end

end

function Screen:drawFull()
    local viewport = self:getService("viewport")
    viewport:graphicsScale()
    self:draw()
    viewport:drawCover(self._cover)
end

function Screen:onWindowModeChange()
end

function Screen:draw()
end

function Screen:getCoverDuration()
    return MEASURES.COVER_FADE_DURATION
end

function Screen:getTimeMultiplier()
    if DebugOptions.ENABLED then
        return Debugger.getTimeMultiplier()
    else
        return 1
    end

end

function Screen:setServiceClass(dependencyName, dependencyClass)
    self._serviceClasses:set(dependencyName, dependencyClass)
end

function Screen:provideServiceDependency(serviceName, service)
    self._services:set(serviceName, service)
end

function Screen:fulfillServiceRequirements(service)
    for dependencyName in service.dependencies() do
        service:setService(dependencyName, self:getService(dependencyName))
    end

    service:onDependencyFulfill()
end

function Screen:getFromClass(serviceName, serviceClass)
    local service = serviceClass:new()
    self._services:set(serviceName, service)
    self:fulfillServiceRequirements(service)
    return service
end

local ASSERT_CONFLICT = "Service/system name conflict: %s"
local ASSERT_DNE = "Service/system does not exists: %s"
function Screen:getService(serviceName)
            if self._services:hasKey(serviceName) then
        return self._services:get(serviceName)
    elseif self._systems:hasKey(serviceName) then
        return self._systems:get(serviceName)
    elseif self._serviceClasses:hasKey(serviceName) then
        local result = self:getFromClass(serviceName, self._serviceClasses:get(serviceName))
        self._serviceClasses:deleteKey(serviceName)
        return result
    else
        local systemExists = filesystem.getInfo("components/" .. serviceName .. ".lua", "file")
        local serviceExists = filesystem.getInfo("services/" .. serviceName .. ".lua", "file")
        Utils.assert(not systemExists or not serviceExists, ASSERT_CONFLICT, serviceName)
        Utils.assert(systemExists or serviceExists, ASSERT_DNE, serviceName)
        if systemExists then
            return self:getSystem(serviceName)
        else
            local serviceClass = require("services." .. serviceName)
            return self:getFromClass(serviceName, serviceClass)
        end

    end

end

Screen.preloadService = Screen.getService
function Screen:getSystem(componentName)
    if not self._systems:hasKey(componentName) then
        local componentClass = require("components." .. componentName)
        local systemInstance = componentClass.System:new()
        systemInstance:createStorage()
        self._systems:set(componentName, systemInstance)
        self:fulfillServiceRequirements(systemInstance)
    end

    return self._systems:get(componentName)
end

function Screen:createEntity(config, hook,...)
    local entity
    if hook and type(hook) == "function" then
        entity = Entity:new(config, ...)
        hook(entity)
    else
        entity = Entity:new(config, hook, ...)
    end

    for componentName, componentInstance in pairs(entity) do
        if componentName:sub(1, 1) ~= "_" then
            local system = self:getSystem(componentName)
            componentInstance.system = system
            system:addInstance(entity)
        end

    end

    return entity
end

function Screen:onQuit()
end

function Screen:extraDebuggingInfo()
    return ""
end

function Screen:adFailedToLoad()
end

function Screen:adReward()
end

function Screen:adStopped()
end

return Screen

