local Body = require("components.create_class")()
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local SparseGrid = require("utils.classes.sparse_grid")
local Common = require("common")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local function bodyMarshaller(entity, data)
end

function Body:initialize(entity, position)
    Body:super(self, "initialize")
    self._entity = entity
    self._position = position
    self.isFlying = false
    self.phaseProjectiles = false
    self.skipEndStep = false
    self.stepCost = math.huge
    self.cantBeMoved = false
    self.removedFromGrid = false
    entity:callIfHasComponent("serializable", "addComponent", "body")
end

function Body:toData()
    return { isFlying = self.isFlying, phaseProjectiles = self.phaseProjectiles, removedFromGrid = self.removedFromGrid }
end

function Body:fromData(data)
    self.isFlying = data.isFlying
    self.phaseProjectiles = data.phaseProjectiles
    self.removedFromGrid = data.removedFromGrid
end

function Body:setPosition(newPosition)
    self.system:deleteInstance(self._entity)
    self._position = newPosition
    self.system:addInstance(self._entity)
end

function Body:removeFromGrid()
    self.system:deleteInstance(self._entity)
    self.removedFromGrid = true
end

function Body:inGrid()
    return self.system:getAt(self._position) == self._entity
end

function Body:getPosition()
    return self._position
end

function Body:isPassable(position)
    return self.system:isPassable(position)
end

function Body:getStepCost(position)
    return self.system:getStepCost(self._entity, position)
end

function Body:canBePassable(position)
    return self.system:canBePassable(position)
end

function Body:getEntityAt(position)
    return self.system:getAt(position)
end

function Body:hasEntityWithTank(position)
    return self.system:hasEntityWithTank(position)
end

function Body:hasEntityWithAgent(position)
    return self.system:hasEntityWithAgent(position)
end

function Body:isPassableDirection(direction)
    return self.system:isPassable(self._position + Vector[direction])
end

function Body:canBePassableDirection(direction)
    return self.system:canBePassable(self._position + Vector[direction])
end

function Body:isAlignedTo(target, levelPassableOnly)
    return self.system:arePositionsAligned(self._position, target, levelPassableOnly)
end

function Body:isInCorridor()
    return self.system:isInCorridor(self._position)
end

function Body:evaluateStepCost()
    return Utils.evaluate(self.stepCost, self._entity)
end

function Body:stepAt(anchor, position)
    self.system.services.steppable:stepAt(anchor, self._entity, position)
end

function Body:hasSteppableExclusivity(position, exclusivity)
    return self.system.services.steppable:hasExclusivity(position, exclusivity)
end

function Body:hasSteppableInstance(position, entityName)
    return self.system.services.steppable:hasInstance(position, entityName)
end

function Body:catchProjectilesAt(anchor, position)
    self.system.services.projectile:catchAt(anchor, self._entity, position)
end

function Body:endOfMove(anchor, moveFrom, moveTo)
    self:catchProjectilesAt(anchor, moveTo)
    self:stepAt(anchor, moveTo)
    self.skipEndStep = true
end

function Body:freezeProjectilesAt(position)
    if not self.phaseProjectiles then
        self.system.services.projectile:freezeAt(position)
    end

end

function Body:getProjectilesAt(position)
    self.system.services.projectile:getProjectilesAt(position)
end

function Body.System:initialize(level)
    Body.System:super(self, "initialize")
    self.storageClass = SparseGrid
    self:setDependencies("steppable", "projectile", "level")
end

function Body.System:addInstance(entity)
    if not entity.body.removedFromGrid then
        self.entities:set(entity.body._position, entity)
    end

end

function Body.System:deleteInstance(entity)
    if self.entities:get(entity.body._position) == entity then
        self.entities:delete(entity.body._position)
    end

end

function Body.System:canBePassable(position)
    return self.services.level:isPassable(position)
end

function Body.System:hasEntityWithTank(position)
    local entity = self.entities:get(position)
    return entity and entity:hasComponent("tank")
end

function Body.System:hasEntityWithAgent(position)
    local entity = self.entities:get(position)
    return entity and entity:hasComponent("agent")
end

function Body.System:isInCorridor(position)
    local tile = self.services.level:get(position)
    return (not tile.isBlocking) and (not tile.isRoom)
end

function Body.System:isPassable(position)
    if self.entities:get(position) then
        return false
    end

    return self.services.level:isPassable(position)
end

function Body.System:isPassableForProjectiles(position)
    local entity = self.entities:get(position)
    if entity then
        return entity.body.phaseProjectiles
    end

    return self.services.level:isPassable(position)
end

function Body.System:getStepCost(stepper, position)
    return self.services.steppable:getStepCost(stepper, position)
end

function Body.System:hasBody(position)
    return toBoolean(self.entities:get(position, false))
end

function Body.System:getAt(position)
    return self.entities:get(position, false)
end

function Body.System:isPositionAdjacentToAgent(entity, position)
    for direction in DIRECTIONS_AA() do
        local entityAt = self:getAt(position + Vector[direction])
        if entityAt and entityAt ~= entity and entityAt:hasComponent("agent") then
            return true
        end

    end

    return false
end

function Body.System:arePositionsAligned(position1, position2, levelPassableOnly)
    if position1.x ~= position2.x and position1.y ~= position2.y then
        return false
    end

    local direction = Common.getDirectionTowards(position1, position2)
    local current = position1 + Vector[direction]
    while current ~= position2 do
                if levelPassableOnly then
            if not self:canBePassable(current) then
                return false
            end

        elseif not self:isPassable(current) then
            return false
        end

        current = current + Vector[direction]
    end

    return true
end

function Body.System:stepAllNonAgents(anchor)
    for _, entity in self.entities() do
        if not entity:hasComponent("player") and not entity:hasComponent("agent") then
            self.services.steppable:stepAt(anchor, entity, entity.body:getPosition())
        end

    end

end

return Body

