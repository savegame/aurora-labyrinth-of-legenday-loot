local VisionProvider = require("components.create_class")()
local Common = require("common")
local SparseGrid = require("utils.classes.sparse_grid")
function VisionProvider:initialize(entity)
    VisionProvider:super(self, "initialize")
end

function VisionProvider.System:initialize()
    VisionProvider.System:super(self, "initialize")
    self.storageClass = SparseGrid
    self:setDependencies("vision")
end

function VisionProvider.System:addInstance(entity)
    local position = Common.getPositionComponent(entity):getPosition()
    self.entities:set(position, self.entities:get(position) + 1)
    self.services.vision:setVisible(position)
    self.services.vision:setNeedRescan()
end

function VisionProvider.System:showOnGrid(grid)
    for position, value in self.entities() do
        if value > 0 then
            grid:set(position, true)
        end

    end

end

function VisionProvider.System:createStorage()
    self.entities = (self.storageClass):new(0)
end

function VisionProvider.System:deleteInstance(entity)
    local position = Common.getPositionComponent(entity):getPosition()
    self.entities:set(position, self.entities:get(position) - 1)
    self.services.vision:setNeedRescan()
end

return VisionProvider

