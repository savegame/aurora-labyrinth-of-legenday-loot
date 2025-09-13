local Service = class()
local UniqueList = require("utils.classes.unique_list")
function Service:initialize()
    self.dependencies = UniqueList:new()
    self.services = Object:new()
end

function Service:setDependencies(...)
    self.dependencies:pushMultiple(...)
end

function Service:setService(name, service)
    rawset(self.services, name, service)
end

function Service:onDependencyFulfill()
end

return Service

