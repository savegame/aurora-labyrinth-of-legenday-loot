local Publisher = require("components.create_class")()
function Publisher:initialize(entity)
    Publisher:super(self, "initialize")
end

function Publisher:publish(message,...)
    self.system:publish(message, ...)
end

function Publisher.System:initialize()
    Publisher.System:super(self, "initialize")
    self:setDependencies("director")
end

function Publisher.System:publish(message,...)
    self.services.director:publish(message, ...)
end

return Publisher

