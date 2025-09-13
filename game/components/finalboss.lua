local FinalBoss = require("components.create_class")()
local Array = require("utils.classes.array")
function FinalBoss:clearEntities()
    for entity in self.system.services.projectile.entities() do
        entity:delete()
    end

    for entity in self.system.services.perishable.entities() do
        entity:delete()
    end

end

function FinalBoss.System:initialize()
    FinalBoss.System:super(self, "initialize")
    self.storageClass = Array
    self:setDependencies("projectile", "steppable", "perishable")
end

function FinalBoss.System:get()
    return self.entities[1]
end

return FinalBoss

