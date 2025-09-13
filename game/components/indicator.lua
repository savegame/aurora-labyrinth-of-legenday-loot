local Indicator = require("components.create_class")()
local UniqueList = require("utils.classes.unique_list")
function Indicator:initialize(entity, color)
    Indicator:super(self, "initialize")
    self._entity = entity
    self.color = color
    self.removedFromGrid = false
    entity:callIfHasComponent("serializable", "addComponent", "indicator")
end

function Indicator:removeFromGrid()
    self.system:deleteInstance(self._entity)
    self.removedFromGrid = true
end

function Indicator.System:initialize()
    Indicator.System:super(self, "initialize")
    self.storageClass = UniqueList
end

function Indicator.System:addInstance(entity)
    if not entity.indicator.removedFromGrid then
        Indicator.System:super(self, "addInstance", entity)
    end

end

function Indicator:toData()
    return { removedFromGrid = self.removedFromGrid }
end

function Indicator:fromData(data)
    self.removedFromGrid = data.removedFromGrid
end

return Indicator

