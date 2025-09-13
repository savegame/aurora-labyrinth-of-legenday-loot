local Component = class()
function Component:initialize()
    self.system = false
end

function Component:onDelete()
end

local System = class("services.service")
local StorageNone = class()
function StorageNone:add()
end

function StorageNone:delete()
end

function StorageNone:isEmpty()
    return true
end

function System:initialize()
    System:super(self, "initialize")
    self.storageClass = StorageNone
    self.entities = false
end

function System:createStorage()
    self.entities = (self.storageClass):new()
end

function System:addInstance(entity)
    self.entities:add(entity)
end

function System:deleteInstance(entity)
    self.entities:delete(entity)
end

function System:isEmpty()
    return self.entities:isEmpty()
end

return function()
    local NewComponent = class(Component)
    NewComponent.System = class(System)
    return NewComponent
end

