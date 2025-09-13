local FrontInteractive = require("components.create_class")()
local SparseGrid = require("utils.classes.sparse_grid")
function FrontInteractive:initialize(entity)
    FrontInteractive:super(self, "initialize")
    Debugger.assertComponent(entity, "body")
    self.onInteract = doNothing
    self.isActive = true
end

function FrontInteractive.System:initialize(director)
    FrontInteractive.System:super(self, "initialize")
    self.storageClass = SparseGrid
    self:setDependencies("director")
end

function FrontInteractive.System:addInstance(entity)
    self.entities:set(entity.body._position, entity)
end

function FrontInteractive.System:deleteInstance(entity)
    self.entities:delete(entity.body._position)
end

function FrontInteractive.System:check(position)
    local entity = self.entities:get(position, false)
    if entity and not entity.body.removedFromGrid and Utils.evaluate(entity.frontinteractive.isActive, entity, self.services.director) then
        entity.frontinteractive.onInteract(entity, self.services.director)
        return true
    end

    return false
end

return FrontInteractive

