local Steppable = require("components.create_class")()
local Set = require("utils.classes.set")
local Array = require("utils.classes.array")
local SparseGrid = require("utils.classes.sparse_grid")
function Steppable:initialize(entity, position, exclusivity)
    Steppable:super(self, "initialize")
    self._entity = entity
    self._position = position
    self._exclusivity = exclusivity or false
    self.onStep = doNothing
    self.canStep = alwaysTrue
    self.stepCost = 1
    self.removedFromGrid = false
    entity:callIfHasComponent("serializable", "addComponent", "steppable")
end

function Steppable:toData()
    return { removedFromGrid = self.removedFromGrid }
end

function Steppable:fromData(data)
    self.removedFromGrid = data.removedFromGrid
end

function Steppable:getPosition()
    return self._position
end

function Steppable:setPosition(newPosition)
    self.system:deleteInstance(self._entity)
    self._position = newPosition
    self.system:addInstance(self._entity)
end

function Steppable:removeFromGrid()
    self.system:deleteInstance(self._entity)
    self.removedFromGrid = true
end

function Steppable:activateOnStepper(anchor)
    local stepper = self.system.services.body:getAt(self._position)
    if stepper and not stepper.body.isFlying then
        if self.canStep(stepper) then
            anchor = self.onStep(anchor, self._entity, stepper) or anchor
        end

    end

    return anchor
end

function Steppable.System:initialize()
    Steppable.System:super(self, "initialize")
    self.storageClass = SparseGrid
    self:setDependencies("body")
end

function Steppable.System:addInstance(entity)
    if entity.steppable.removedFromGrid then
        return 
    end

    local position = entity.steppable._position
    if not self.entities:hasValue(position) then
        self.entities:set(position, Array:new())
    end

    local entities = self.entities:get(position)
    local exclusivity = entity.steppable._exclusivity
    if exclusivity then
        for otherEntity in (entities:clone())() do
            if otherEntity.steppable._exclusivity == exclusivity then
                Debugger.log("Deleting Steppable Conflict")
                otherEntity:delete()
            end

        end

    end

    entities:push(entity)
    if exclusivity then
        self.entities:set(position, entities)
    end

end

function Steppable.System:deleteInstance(entity)
    local position = entity.steppable._position
    local steppables = self.entities:get(position)
    if steppables then
        steppables:delete(entity)
        if steppables:isEmpty() then
            self.entities:delete(position)
        end

    end

end

function Steppable.System:stepAt(anchor, stepper, position)
    if stepper.body.isFlying then
        return 
    end

    local entities = self.entities:get(position)
    if entities then
        for entity in entities:reverseIterator() do
            local steppable = entity.steppable
            if steppable.canStep(stepper) then
                anchor = steppable.onStep(anchor, entity, stepper) or anchor
            end

        end

    end

end

function Steppable.System:deleteTemporaryAt(position)
    local entities = self.entities:get(position)
    if entities then
        for entity in (entities:clone())() do
            local steppable = entity.steppable
            if steppable._exclusivity then
                entity:delete()
            end

        end

    end

end

function Steppable.System:hasExclusivity(position, exclusivity)
    local steppables = self.entities:get(position) or Array.EMPTY
    return steppables:hasOne(function(steppable)
        return steppable.steppable._exclusivity == exclusivity
    end)
end

function Steppable.System:hasInstance(position, entityName)
    local steppables = self.entities:get(position) or Array.EMPTY
    return steppables:hasOne(function(steppable)
        return steppable:getPrefab() == entityName
    end)
end

function Steppable.System:hasPermanentExclusivity(position, exclusivity)
    local steppables = self.entities:get(position) or Array.EMPTY
    return steppables:hasOne(function(steppable)
        return steppable.steppable._exclusivity == exclusivity and (not steppable:hasComponent("perishable") or steppable.perishable.duration == math.huge)
    end)
end

function Steppable.System:getStepCost(stepper, position)
    if stepper.body.isFlying then
        return 1
    end

    local entities = self.entities:get(position) or Array.EMPTY
    return (entities:map(function(entity)
        if entity.steppable.canStep(stepper) then
            return Utils.evaluate(entity.steppable.stepCost, entity)
        else
            return 1
        end

    end):maxValue() or 1)
end

return Steppable

