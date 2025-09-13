local Ranged = require("components.create_class")()
local Vector = require("utils.classes.vector")
local SparseGrid = require("utils.classes.sparse_grid")
local Array = require("utils.classes.array")
local Common = require("common")
local COOLDOWN_BEFORE_KITING = 10
function Ranged:initialize(entity)
    Ranged:super(self, "initialize")
    self._entity = entity
    self.attackClass = false
    self.range = math.huge
    self.attackCooldown = 1
    self.cooldown = 0
    self.alignBackOff = true
    self.fireOffCenter = false
    entity:callIfHasComponent("serializable", "addComponent", "ranged")
end

function Ranged:toData()
    return { cooldown = self.cooldown }
end

function Ranged:fromData(data)
    self.cooldown = data.cooldown
end

function Ranged:isReady()
    return self.cooldown == 0
end

function Ranged:willAttackSoon()
    return self.cooldown < COOLDOWN_BEFORE_KITING
end

function Ranged:setOnCooldown()
    self.cooldown = self.attackCooldown
end

function Ranged:endOfTurn()
    if self._entity.buffable:canAct() then
        self.cooldown = max(0, self.cooldown - 1)
    end

end

function Ranged:createAction(direction)
    return self._entity.actor:create(self.attackClass, direction)
end

function Ranged.System:initialize()
    Ranged.System:super(self, "initialize")
    self.storageClass = Array
    self:setDependencies("body", "player", "vision")
end

function Ranged.System:getReservedGrid()
    local reserved = SparseGrid:new(false)
    local player = self.services.player:get()
    local vision = self.services.vision
    local playerPosition = player.body:getPosition()
    local systemBody = self.services.body
    for entity in self.entities() do
        if entity.ranged:isReady() and not entity.body.removedFromGrid then
            local position = entity.body:getPosition()
            local distance = position:distanceManhattan(playerPosition)
            if vision:isVisible(position) and distance <= entity.ranged.range then
                if systemBody:arePositionsAligned(position, playerPosition) then
                    local direction = Common.getDirectionTowards(position, playerPosition)
                    local current = position + Vector[direction]
                    while current ~= playerPosition do
                        reserved:set(current, true)
                        current = current + Vector[direction]
                    end

                end

            end

        end

    end

    return reserved
end

return Ranged

